<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class LoginLockedNotification extends Notification
{
    use Queueable;

    public function __construct(
        private readonly string $resetUrl,
        private readonly string $attemptedAt,
        private readonly string $ipAddress,
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Peringatan Keamanan Akun Jualin')
            ->greeting('Hai, ' . ($notifiable->username ?? 'Sobat Jualin') . '!')
            ->line('Kami mendeteksi 3 kali percobaan login yang gagal. Demi keamanan, akses login akunmu dikunci sementara selama 15 menit.')
            ->line("Waktu percobaan: {$this->attemptedAt} WIB")
            ->line("Alamat IP: {$this->ipAddress}")
            ->line('Jika ini bukan kamu, segera atur ulang kata sandi melalui tombol berikut.')
            ->action('Reset Kata Sandi Sekarang', $this->resetUrl)
            ->line('Tautan reset hanya dapat digunakan sekali. Jika percobaan ini memang dilakukan olehmu, kamu dapat menunggu masa penguncian berakhir.')
            ->salutation('Tetap aman, Tim Jualin');
    }
}
