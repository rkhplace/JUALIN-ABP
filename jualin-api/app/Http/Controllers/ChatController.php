<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use App\Models\ChatMessage;
use App\Models\ChatRoom;
use App\Models\Notification;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ChatController extends Controller
{
    /**
     * GET /v1/chat/rooms
     *
     * Returns all chat rooms the authenticated user belongs to,
     * with the other member's info and latest message preview.
     */
    public function rooms(): JsonResponse
    {
        $user = Auth::user();

        $rooms = ChatRoom::whereHas('members', function ($q) use ($user) {
                $q->where('users.id', $user->id);
            })
            ->with([
                'members'       => fn($q) => $q->where('users.id', '!=', $user->id),
                'latestMessage.sender',
                'product.seller:id,username,profile_picture',
            ])
            ->latest('updated_at')
            ->get()
            ->map(function (ChatRoom $room) {
                $other  = $room->members->first();
                $latest = $room->latestMessage;
                return [
                    'id'            => $room->id,
                    'room_type'     => $room->room_type,
                    'product_id'    => $room->product_id,
                    'product'       => $this->serializeProduct($room->product),
                    'other_user'    => $other ? [
                        'id'              => $other->id,
                        'username'        => $other->username ?? $other->name,
                        'profile_picture' => $other->profile_picture ?? null,
                    ] : null,
                    'latest_message' => $latest ? [
                        'message'    => $latest->message,
                        'sent_at'    => $latest->sent_at,
                        'sender_id'  => $latest->sender_id,
                        'is_read'    => $latest->is_read,
                    ] : null,
                    'updated_at'    => $room->updated_at,
                ];
            });

        return ApiResponse::success('Chat rooms retrieved successfully', $rooms);
    }

    /**
     * GET /v1/chat/rooms/{roomId}/messages
     *
     * Returns paginated messages for the given room.
     * The user must be a member of the room.
     */
    public function messages(Request $request, int $roomId): JsonResponse
    {
        $user = Auth::user();

        $room = ChatRoom::whereHas('members', function ($q) use ($user) {
            $q->where('users.id', $user->id);
        })->find($roomId);

        if (!$room) {
            return ApiResponse::error('Chat room not found or access denied', null, 404);
        }

        $messages = ChatMessage::where('chat_room_id', $roomId)
            ->with('sender:id,username,profile_picture')
            ->orderBy('sent_at', 'asc')
            ->paginate((int) $request->get('per_page', 50));

        // Mark messages from others as read
        ChatMessage::where('chat_room_id', $roomId)
            ->where('sender_id', '!=', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        // Append type and product_data to each message in the paginated result
        $messages->getCollection()->transform(function ($msg) {
            $msg->type = $msg->type ?? 'text';
            return $msg;
        });

        return ApiResponse::success('Messages retrieved successfully', $messages);
    }

    /**
     * POST /v1/chat/rooms/{roomId}/messages
     *
     * Sends a message in the given room.
     * The user must be a member of the room.
     */
    public function sendMessage(Request $request, int $roomId): JsonResponse
    {
        $user = Auth::user();

        $room = ChatRoom::whereHas('members', function ($q) use ($user) {
            $q->where('users.id', $user->id);
        })->find($roomId);

        if (!$room) {
            return ApiResponse::error('Chat room not found or access denied', null, 404);
        }

        $request->validate([
            'message'      => 'required|string|max:2000',
            'type'         => 'sometimes|string|in:text,product',
            'product_data' => 'sometimes|array',
        ]);

        $message = ChatMessage::create([
            'chat_room_id' => $roomId,
            'sender_id'    => $user->id,
            'message'      => $request->message,
            'type'         => $request->input('type', 'text'),
            'product_data' => $request->input('product_data'),
            'sent_at'      => now(),
            'is_read'      => false,
        ]);

        // Touch room so it bubbles to top of list
        $room->touch();

        $message->load('sender:id,username,profile_picture');
        $this->notifyRoomMembers($room, $user->id, $user->username ?? 'Pengguna', $message->message);

        return ApiResponse::success('Message sent', $message, 201);
    }

    /**
     * POST /v1/chat/rooms/{roomId}/product-message
     *
     * Sends a product-type message in the given room.
     * Prevents duplicate product messages for the same product in the same room.
     */
    public function sendProductMessage(Request $request, int $roomId): JsonResponse
    {
        $user = Auth::user();

        $room = ChatRoom::whereHas('members', function ($q) use ($user) {
            $q->where('users.id', $user->id);
        })->find($roomId);

        if (!$room) {
            return ApiResponse::error('Chat room not found or access denied', null, 404);
        }

        $request->validate([
            'product_data'      => 'required|array',
            'product_data.id'   => 'required',
            'product_data.name' => 'required|string',
        ]);

        $productData = $request->input('product_data');
        $product = Product::with('seller:id,username,profile_picture')->find($productData['id']);
        if ($product) {
            $productData = $this->serializeProduct($product);
        }

        // Check if a product message with same product ID already exists in this room
        $exists = ChatMessage::where('chat_room_id', $roomId)
            ->where('type', 'product')
            ->get()
            ->contains(function ($msg) use ($productData) {
                $data = is_array($msg->product_data) ? $msg->product_data : json_decode($msg->product_data, true);
                return isset($data['id']) && (int) $data['id'] === (int) $productData['id'];
            });

        if ($exists) {
            return ApiResponse::success('Product message already exists', null, 200);
        }

        $message = ChatMessage::create([
            'chat_room_id' => $roomId,
            'sender_id'    => $user->id,
            'message'      => '📦 ' . $productData['name'],
            'type'         => 'product',
            'product_data' => $productData,
            'sent_at'      => now(),
            'is_read'      => false,
        ]);

        $room->touch();
        $message->load('sender:id,username,profile_picture');
        $this->notifyRoomMembers(
            $room,
            $user->id,
            $user->username ?? 'Pengguna',
            'Membagikan preview produk: ' . $productData['name']
        );

        return ApiResponse::success('Product message sent', $message, 201);
    }

    /**
     * POST /v1/chat/rooms/start
     *
     * Finds or creates a private room between the current user (buyer) and seller.
     * Accepts either `seller_id` (preferred) or `user_id` for backwards compatibility.
     */
    public function startRoom(Request $request): JsonResponse
    {
        $request->validate([
            'seller_id'  => 'sometimes|integer|exists:users,id',
            'user_id'    => 'sometimes|integer|exists:users,id',
            'product_id' => 'sometimes|nullable|integer|exists:products,id',
        ]);

        $currentUser  = Auth::user();
        // Accept either seller_id or user_id
        $targetUserId = $request->seller_id ?? $request->user_id;
        $productId = $request->input('product_id');

        if (!$targetUserId) {
            return ApiResponse::error('seller_id or user_id is required', null, 422);
        }

        if ($currentUser->id === $targetUserId) {
            return ApiResponse::error('Cannot start chat with yourself', null, 400);
        }

        if ($productId) {
            $product = Product::find($productId);
            if (!$product) {
                return ApiResponse::error('Product not found', null, 422);
            }

            if ((int) $product->seller_id !== (int) $targetUserId) {
                return ApiResponse::error('Product does not belong to selected seller', null, 422);
            }
        }

        // Find existing private room shared by both users
        $existingRoom = ChatRoom::where('room_type', 'private')
            ->whereHas('members', fn($q) => $q->where('users.id', $currentUser->id))
            ->whereHas('members', fn($q) => $q->where('users.id', $targetUserId))
            ->first();

        if ($existingRoom) {
            if ($productId && !$existingRoom->product_id) {
                $existingRoom->update(['product_id' => $productId]);
            }

            return ApiResponse::success('Existing room found', [
                'room_id' => $existingRoom->id,
                'product_id' => $existingRoom->fresh()->product_id,
            ]);
        }

        // Create new room and add both members
        $room = ChatRoom::create([
            'room_type' => 'private',
            'product_id' => $productId,
        ]);
        $room->members()->attach([$currentUser->id, $targetUserId]);

        return ApiResponse::success('Room created', [
            'room_id' => $room->id,
            'product_id' => $room->product_id,
        ], 201);
    }

    private function serializeProduct(?Product $product): ?array
    {
        if (!$product) {
            return null;
        }

        return [
            'id' => $product->id,
            'name' => $product->name,
            'price' => $product->price,
            'image' => $product->image,
            'seller_id' => $product->seller_id,
            'seller_name' => $product->seller?->username,
        ];
    }

    private function notifyRoomMembers(
        ChatRoom $room,
        int $senderId,
        string $senderName,
        string $body
    ): void {
        $room->loadMissing('members:id');

        foreach ($room->members as $member) {
            if ((int) $member->id === (int) $senderId) {
                continue;
            }

            Notification::create([
                'user_id' => $member->id,
                'title' => 'Pesan baru dari ' . $senderName,
                'body' => $body,
                'type' => 'chat',
                'target_type' => 'chat_room',
                'target_id' => $room->id,
            ]);
        }
    }
}
