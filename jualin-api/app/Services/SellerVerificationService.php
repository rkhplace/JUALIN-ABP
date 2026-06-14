<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;

class SellerVerificationService
{
    /**
     * Threshold of completed transactions to become verified.
     */
    const VERIFICATION_TARGET = 3;

    /**
     * Profile fields sellers must complete before receiving the verified badge.
     */
    const PROFILE_REQUIREMENTS = [
        'username' => 'Nama pengguna',
        'email' => 'Email',
        'gender' => 'Jenis kelamin',
        'birthday' => 'Tanggal lahir',
        'region' => 'Provinsi',
        'city' => 'Kota',
        'phone' => 'Nomor telepon',
        'bio' => 'Bio',
        'profile_picture' => 'Foto profil',
    ];

    /**
     * Recount completed transactions for the given seller,
     * update total_sales, and set is_verified accordingly.
     */
    public function updateSellerVerification(int $sellerId): void
    {
        $seller = User::find($sellerId);

        if (!$seller || $seller->role !== 'seller') {
            return;
        }

        $totalSales = Transaction::where('seller_id', $sellerId)
            ->whereIn('status', ['verified', 'completed'])
            ->count();

        $seller->total_sales  = $totalSales;
        $seller->is_verified  = $totalSales >= self::VERIFICATION_TARGET
            && $this->hasCompleteProfile($seller);
        $seller->save();
    }

    public function getProfileCompletion(User $seller): array
    {
        $missing = [];

        foreach (self::PROFILE_REQUIREMENTS as $field => $label) {
            $value = $field === 'profile_picture'
                ? $seller->getRawOriginal('profile_picture')
                : $seller->{$field};

            if (!$this->isFilled($value)) {
                $missing[] = [
                    'field' => $field,
                    'label' => $label,
                ];
            }
        }

        return [
            'is_complete' => count($missing) === 0,
            'missing_fields' => $missing,
            'required_fields' => array_map(
                fn(string $field, string $label) => [
                    'field' => $field,
                    'label' => $label,
                ],
                array_keys(self::PROFILE_REQUIREMENTS),
                self::PROFILE_REQUIREMENTS
            ),
        ];
    }

    public function hasCompleteProfile(User $seller): bool
    {
        return $this->getProfileCompletion($seller)['is_complete'];
    }

    private function isFilled(mixed $value): bool
    {
        if ($value === null) {
            return false;
        }

        if (is_string($value)) {
            return trim($value) !== '';
        }

        return true;
    }
}
