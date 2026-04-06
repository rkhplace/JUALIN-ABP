<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use App\Models\ChatMessage;
use App\Models\ChatRoom;
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
            ])
            ->latest('updated_at')
            ->get()
            ->map(function (ChatRoom $room) {
                $other  = $room->members->first();
                $latest = $room->latestMessage;
                return [
                    'id'            => $room->id,
                    'room_type'     => $room->room_type,
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

        $request->validate(['message' => 'required|string|max:2000']);

        $message = ChatMessage::create([
            'chat_room_id' => $roomId,
            'sender_id'    => $user->id,
            'message'      => $request->message,
            'sent_at'      => now(),
            'is_read'      => false,
        ]);

        // Touch room so it bubbles to top of list
        $room->touch();

        $message->load('sender:id,username,profile_picture');

        return ApiResponse::success('Message sent', $message, 201);
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
        ]);

        $currentUser  = Auth::user();
        // Accept either seller_id or user_id
        $targetUserId = $request->seller_id ?? $request->user_id;

        if (!$targetUserId) {
            return ApiResponse::error('seller_id or user_id is required', null, 422);
        }

        if ($currentUser->id === $targetUserId) {
            return ApiResponse::error('Cannot start chat with yourself', null, 400);
        }

        // Find existing private room shared by both users
        $existingRoom = ChatRoom::where('room_type', 'private')
            ->whereHas('members', fn($q) => $q->where('users.id', $currentUser->id))
            ->whereHas('members', fn($q) => $q->where('users.id', $targetUserId))
            ->first();

        if ($existingRoom) {
            return ApiResponse::success('Existing room found', ['room_id' => $existingRoom->id]);
        }

        // Create new room and add both members
        $room = ChatRoom::create(['room_type' => 'private']);
        $room->members()->attach([$currentUser->id, $targetUserId]);

        return ApiResponse::success('Room created', ['room_id' => $room->id], 201);
    }
}
