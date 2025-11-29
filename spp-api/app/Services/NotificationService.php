<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;

class NotificationService
{
    /**
     * Create notification untuk user
     */
    public function create(User $user, string $title, string $message, string $type = 'general', ?array $data = null): Notification
    {
        return Notification::create([
            'user_id' => $user->id,
            'title' => $title,
            'message' => $message,
            'type' => $type,
            'data' => $data,
        ]);
    }

    /**
     * Create notification untuk antrian
     */
    public function notifyQueue(User $user, string $title, string $message, int $queueId, ?array $additionalData = []): Notification
    {
        return $this->create(
            $user,
            $title,
            $message,
            'queue',
            array_merge(['queue_id' => $queueId], $additionalData)
        );
    }

    /**
     * Create notification untuk pembayaran
     */
    public function notifyPayment(User $user, string $title, string $message, int $paymentId, ?array $additionalData = []): Notification
    {
        return $this->create(
            $user,
            $title,
            $message,
            'payment',
            array_merge(['payment_id' => $paymentId], $additionalData)
        );
    }

    /**
     * Get unread count untuk user
     */
    public function getUnreadCount(User $user): int
    {
        return Notification::where('user_id', $user->id)
            ->unread()
            ->count();
    }

    /**
     * Mark all as read untuk user
     */
    public function markAllAsRead(User $user): void
    {
        Notification::where('user_id', $user->id)
            ->unread()
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
    }
}

