<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;

class BuyerCredibilityService
{
    private const SUCCESS_STATUSES = ['verified', 'completed'];
    private const RISK_STATUSES = ['cancelled', 'refunded', 'failed', 'expired'];

    public function summarize(User $buyer): array
    {
        $successfulPurchases = Transaction::query()
            ->where('customer_id', $buyer->id)
            ->whereIn('status', self::SUCCESS_STATUSES)
            ->count();

        $riskCount = Transaction::query()
            ->where('customer_id', $buyer->id)
            ->whereIn('status', self::RISK_STATUSES)
            ->count();

        $totalPurchases = Transaction::query()
            ->where('customer_id', $buyer->id)
            ->count();

        $profileComplete = $this->isProfileComplete($buyer);
        $accountAgeDays = $buyer->created_at
            ? (int) $buyer->created_at->diffInDays(now())
            : 0;

        $level = $this->resolveLevel(
            $successfulPurchases,
            $riskCount,
            $totalPurchases,
            $profileComplete
        );

        return [
            'level' => $level,
            'label' => $this->labelForLevel($level),
            'successful_purchases' => $successfulPurchases,
            'cancelled_or_refunded' => $riskCount,
            'total_purchases' => $totalPurchases,
            'profile_complete' => $profileComplete,
            'account_age_days' => $accountAgeDays,
            'signals' => $this->signals(
                $successfulPurchases,
                $riskCount,
                $profileComplete,
                $accountAgeDays
            ),
        ];
    }

    private function resolveLevel(
        int $successfulPurchases,
        int $riskCount,
        int $totalPurchases,
        bool $profileComplete
    ): string {
        if ($totalPurchases > 0 && $riskCount >= 2 && $riskCount >= $successfulPurchases) {
            return 'needs_attention';
        }

        if ($successfulPurchases >= 3 && $profileComplete) {
            return 'trusted';
        }

        if ($successfulPurchases > 0) {
            return 'active';
        }

        return 'new';
    }

    private function labelForLevel(string $level): string
    {
        return match ($level) {
            'trusted' => 'Pembeli Terpercaya',
            'active' => 'Pembeli Aktif',
            'needs_attention' => 'Perlu Perhatian',
            default => 'Pembeli Baru',
        };
    }

    private function signals(
        int $successfulPurchases,
        int $riskCount,
        bool $profileComplete,
        int $accountAgeDays
    ): array {
        $signals = [
            "{$successfulPurchases} transaksi berhasil",
            $profileComplete ? 'Profil lengkap' : 'Profil belum lengkap',
        ];

        if ($riskCount > 0) {
            $signals[] = "{$riskCount} transaksi batal/refund";
        }

        if ($accountAgeDays > 0) {
            $signals[] = "Akun {$accountAgeDays} hari";
        }

        return $signals;
    }

    private function isProfileComplete(User $buyer): bool
    {
        foreach (['username', 'email', 'phone', 'profile_picture'] as $field) {
            if (blank($buyer->{$field})) {
                return false;
            }
        }

        return true;
    }
}
