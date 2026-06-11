<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use App\Models\Notification;
use App\Models\UserDeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    /**
     * GET /api/v1/notifications
     * Retrieve notifications for the authenticated user.
     */
    public function index(Request $request): JsonResponse
    {
        $user = Auth::user();

        $notifications = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($notif) {
                return [
                    'id' => $notif->id,
                    'title' => $notif->title,
                    'body' => $notif->body,
                    'type' => $notif->type,
                    'target_type' => $notif->target_type,
                    'target_id' => $notif->target_id,
                    'is_read' => $notif->is_read,
                    'created_at' => $notif->created_at->diffForHumans(),
                ];
            });

        $unreadCount = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        // Optionally mark all as read when explicitly requested
        if ($request->query('mark_read')) {
            Notification::where('user_id', $user->id)
                ->where('is_read', false)
                ->update(['is_read' => true]);
        }

        return ApiResponse::success('Notifications retrieved successfully', [
            'unread_count' => $unreadCount,
            'data' => $notifications,
        ]);
    }

    public function storeDeviceToken(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => 'required|string|max:512',
            'platform' => 'sometimes|string|in:android',
        ]);

        $token = UserDeviceToken::updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => Auth::id(),
                'platform' => $data['platform'] ?? 'android',
                'is_active' => true,
                'last_seen_at' => now(),
            ]
        );

        return ApiResponse::success('Device token registered', [
            'id' => $token->id,
        ]);
    }

    public function destroyDeviceToken(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => 'required|string|max:512',
        ]);

        UserDeviceToken::where('token', $data['token'])
            ->where('user_id', Auth::id())
            ->update(['is_active' => false]);

        return ApiResponse::success('Device token disabled');
    }
}
