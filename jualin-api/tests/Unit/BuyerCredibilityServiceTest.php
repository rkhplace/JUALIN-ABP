<?php

namespace Tests\Unit;

use App\Models\Transaction;
use App\Models\User;
use App\Services\BuyerCredibilityService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuyerCredibilityServiceTest extends TestCase
{
    use RefreshDatabase;

    public function testBuyerBecomesTrustedAfterThreeSuccessfulPurchasesAndCompleteProfile(): void
    {
        $buyer = User::create([
            'username' => 'buyer_trusted',
            'email' => 'buyer-trusted@example.com',
            'password' => 'pw',
            'role' => 'customer',
            'phone' => '08123456789',
            'profile_picture' => 'profile_pictures/buyer.jpg',
        ]);
        $seller = User::create([
            'username' => 'seller_for_trusted_buyer',
            'email' => 'seller-trusted-buyer@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);

        foreach (['verified', 'completed', 'verified'] as $status) {
            Transaction::create([
                'customer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'total_amount' => 10000,
                'status' => $status,
            ]);
        }

        $summary = (new BuyerCredibilityService())->summarize($buyer);

        $this->assertSame('trusted', $summary['level']);
        $this->assertSame('Pembeli Terpercaya', $summary['label']);
        $this->assertSame(3, $summary['successful_purchases']);
        $this->assertTrue($summary['profile_complete']);
    }

    public function testBuyerNeedsAttentionWhenFailedHistoryDominates(): void
    {
        $buyer = User::create([
            'username' => 'buyer_attention',
            'email' => 'buyer-attention@example.com',
            'password' => 'pw',
            'role' => 'customer',
        ]);
        $seller = User::create([
            'username' => 'seller_for_attention_buyer',
            'email' => 'seller-attention-buyer@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);

        foreach (['cancelled', 'refunded'] as $status) {
            Transaction::create([
                'customer_id' => $buyer->id,
                'seller_id' => $seller->id,
                'total_amount' => 10000,
                'status' => $status,
            ]);
        }

        $summary = (new BuyerCredibilityService())->summarize($buyer);

        $this->assertSame('needs_attention', $summary['level']);
        $this->assertSame('Perlu Perhatian', $summary['label']);
        $this->assertSame(2, $summary['cancelled_or_refunded']);
    }
}
