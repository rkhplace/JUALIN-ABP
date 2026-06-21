<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\Storage;
use App\Models\User;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('accounts:purge-scheduled', function () {
    User::query()
        ->where('role', '!=', 'admin')
        ->whereNotNull('scheduled_deletion_at')
        ->where('scheduled_deletion_at', '<=', now())
        ->chunkById(100, function ($users) {
            foreach ($users as $user) {
                $profilePicture = $user->getRawOriginal('profile_picture');
                if ($profilePicture && Storage::disk('public')->exists($profilePicture)) {
                    Storage::disk('public')->delete($profilePicture);
                }
                $user->delete();
            }
        });
})->purpose('Permanently delete accounts whose 14-day recovery period has ended');

Schedule::command('accounts:purge-scheduled')->dailyAt('02:00')->withoutOverlapping();
