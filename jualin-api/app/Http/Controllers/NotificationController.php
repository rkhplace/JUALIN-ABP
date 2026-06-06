<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use App\Models\Notification;
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
}
