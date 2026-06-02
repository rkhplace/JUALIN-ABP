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
            ->whereIn('status', ['verified'])
            ->count();

        $seller->total_sales  = $totalSales;
        $seller->is_verified  = $totalSales >= self::VERIFICATION_TARGET;
        $seller->save();
    }
}
