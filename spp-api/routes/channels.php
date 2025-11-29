<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// Private channel untuk notifikasi antrian
Broadcast::channel('queue.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// Private channel untuk notifikasi pembayaran
Broadcast::channel('payment.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});
