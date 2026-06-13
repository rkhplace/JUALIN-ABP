<?php

namespace Tests\Unit;

use App\Models\Transaction;
use App\Models\User;
use App\Services\SellerVerificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SellerVerificationServiceTest extends TestCase
{
    use RefreshDatabase;

    public function testSellerBecomesVerifiedAfterThreeValidTransactions(): void
    {
        $seller = User::create([
            'username' => 'seller_verified',
            'email' => 'seller-verified@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);
        $buyer = User::create([
            'username' => 'buyer_verified',
            'email' => 'buyer-verified@example.com',
            'password' => 'pw',
            'role' => 'customer',
        ]);

        Transaction::create([
            'customer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'total_amount' => 10000,
            'status' => 'verified',
        ]);
        Transaction::create([
            'customer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'total_amount' => 10000,
            'status' => 'completed',
        ]);
        Transaction::create([
            'customer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'total_amount' => 10000,
            'status' => 'refunded',
        ]);

        $service = new SellerVerificationService();
        $service->updateSellerVerification($seller->id);
        $seller->refresh();

        $this->assertSame(2, $seller->total_sales);
        $this->assertFalse($seller->is_verified);

        Transaction::create([
            'customer_id' => $buyer->id,
            'seller_id' => $seller->id,
            'total_amount' => 10000,
            'status' => 'verified',
        ]);

        $service->updateSellerVerification($seller->id);
        $seller->refresh();

        $this->assertSame(3, $seller->total_sales);
        $this->assertTrue($seller->is_verified);
    }
}
