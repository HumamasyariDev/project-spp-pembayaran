<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    /**
     * Get all notifications for the authenticated user
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            $query = DB::table('notifications')
                ->where('user_id', $user->id);
            
            // Filter by type if provided
            if ($request->has('type') && $request->type !== 'Semua') {
                $query->where('type', $request->type);
            }
            
            $notifications = $query
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($notification) {
                    return [
                        'id' => $notification->id,
                        'type' => $notification->type,
                        'title' => $notification->title,
                        'body' => $notification->message, // Use 'message' column
                        'data' => json_decode($notification->data),
                        'is_read' => (bool) $notification->is_read,
                        'created_at' => $notification->created_at,
                    ];
                });

            return response()->json([
                'status' => true,
                'message' => 'Notifications retrieved successfully',
                'data' => $notifications,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve notifications: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get unread notification count
     */
    public function unreadCount(Request $request)
    {
        try {
            $user = $request->user();
            
            $count = DB::table('notifications')
                ->where('user_id', $user->id)
                ->where('is_read', false)
                ->count();

            return response()->json([
                'status' => true,
                'data' => ['count' => $count],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to get unread count: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mark notification as read
     */
    public function markAsRead(Request $request, $id)
    {
        try {
            $user = $request->user();
            
            $notification = DB::table('notifications')
                ->where('id', $id)
                ->where('user_id', $user->id)
                ->first();

            if (!$notification) {
                return response()->json([
                    'status' => false,
                    'message' => 'Notification not found',
                ], 404);
            }

            DB::table('notifications')
                ->where('id', $id)
                ->update(['is_read' => true]);

            return response()->json([
                'status' => true,
                'message' => 'Notification marked as read',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to mark notification as read: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(Request $request)
    {
        try {
            $user = $request->user();
            
            DB::table('notifications')
                ->where('user_id', $user->id)
                ->update(['is_read' => true]);

            return response()->json([
                'status' => true,
                'message' => 'All notifications marked as read',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to mark all notifications as read: ' . $e->getMessage(),
            ], 500);
        }
    }
}
