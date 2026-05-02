<?php

namespace App\Providers;

use App\Http\Middleware\RoleMiddleware;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Route::aliasMiddleware('role', RoleMiddleware::class);

        ResetPassword::createUrlUsing(function (object $notifiable, string $token) {
            $frontendUrl = rtrim(config('app.frontend_url') ?: config('app.url'), '/');

            return $frontendUrl . '/auth/reset-password?' . http_build_query([
                'token' => $token,
                'email' => $notifiable->getEmailForPasswordReset(),
            ]);
        });

        ResetPassword::toMailUsing(function (object $notifiable, string $url) {
            return (new MailMessage)
                ->subject('Reset Kata Sandi Akun Jualin')
                ->greeting('Hai, ' . ($notifiable->username ?? 'Sobat Jualin') . '!')
                ->line('Lupa password ya? Tenang ajaa, kamu bisa klik tombol di bawah ini untuk mengatur ulang kata sandi akun Jualin kamu.')
                ->line('Link ini hanya berlaku selama 60 menit, jadi jangan ditunda terlalu lama ya.')
                ->action('Atur Ulang Kata Sandi', $url)
                ->line('Kalau kamu tidak merasa meminta reset password, abaikan saja email ini. Akun kamu tetap aman.')
                ->salutation('Sampai ketemu lagi, Tim Jualin');
        });
    }
}
