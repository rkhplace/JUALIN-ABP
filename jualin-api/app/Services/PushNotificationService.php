<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\UserDeviceToken;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FirebaseNotification;

class PushNotificationService
{
    public function sendForNotification(Notification $notification): void
    {
        $tokens = UserDeviceToken::query()
            ->where('user_id', $notification->user_id)
            ->where('platform', 'android')
            ->where('is_active', true)
            ->pluck('token');

        if ($tokens->isEmpty()) {
            return;
        }

        $messaging = $this->messaging();
        if (!$messaging) {
            return;
        }

        foreach ($tokens as $token) {
            try {
                $message = CloudMessage::withTarget('token', $token)
                    ->withNotification(FirebaseNotification::create(
                        $notification->title,
                        $notification->body
                    ))
                    ->withData($this->dataPayload($notification));

                $messaging->send($message);
            } catch (\Throwable $e) {
                Log::warning('Failed to send FCM notification', [
                    'notification_id' => $notification->id,
                    'user_id' => $notification->user_id,
                    'token_id' => substr($token, 0, 16),
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }

    private function messaging(): mixed
    {
        $credentials = $this->resolveFirebaseCredentials();
        if (!$credentials) {
            Log::warning('Firebase credentials not found for push notifications');
            return null;
        }

        return (new Factory)
            ->withServiceAccount($credentials)
            ->createMessaging();
    }

    private function resolveFirebaseCredentials(): string|array|null
    {
        $json = env('FIREBASE_CREDENTIALS_JSON');
        if ($json) {
            $decoded = json_decode($json, true);
            if (is_array($decoded)) {
                return $decoded;
            }

            Log::warning('FIREBASE_CREDENTIALS_JSON is not valid JSON');
        }

        $base64 = env('FIREBASE_CREDENTIALS_BASE64');
        if ($base64) {
            $decodedJson = base64_decode($base64, true);
            $decoded = $decodedJson ? json_decode($decodedJson, true) : null;
            if (is_array($decoded)) {
                return $decoded;
            }

            Log::warning('FIREBASE_CREDENTIALS_BASE64 is not valid base64 JSON');
        }

        $serviceAccountPath = storage_path('app/firebase-credentials.json');
        if (file_exists($serviceAccountPath)) {
            return $serviceAccountPath;
        }

        return null;
    }

    private function dataPayload(Notification $notification): array
    {
        return [
            'notification_id' => (string) $notification->id,
            'type' => (string) $notification->type,
            'target_type' => (string) ($notification->target_type ?? 'notifications'),
            'target_id' => (string) ($notification->target_id ?? ''),
        ];
    }
}
