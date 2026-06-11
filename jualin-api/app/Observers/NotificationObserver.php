<?php

namespace App\Observers;

use App\Models\Notification;
use App\Services\PushNotificationService;

class NotificationObserver
{
    public function created(Notification $notification): void
    {
        app(PushNotificationService::class)->sendForNotification($notification);
    }
}
