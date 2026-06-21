<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProtectedAuthCodeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function test_customer_can_reveal_own_code_with_correct_password(): void
    {
        [$customer, $transaction] = $this->makeProtectedTransaction();

        $this->actingAs($customer, 'api')
            ->postJson("/api/v1/transactions/{$transaction->id}/reveal-auth-code", [
                'verification_method' => 'password',
                'password' => 'secret-password',
            ])
            ->assertOk()
            ->assertJsonPath('data.auth_code', 'ABC123')
            ->assertJsonStructure(['data' => ['expires_at']]);
    }

    public function test_wrong_password_cannot_reveal_code(): void
    {
        [$customer, $transaction] = $this->makeProtectedTransaction();

        $this->actingAs($customer, 'api')
            ->postJson("/api/v1/transactions/{$transaction->id}/reveal-auth-code", [
                'verification_method' => 'password',
                'password' => 'wrong-password',
            ])
            ->assertStatus(422)
            ->assertJsonMissing(['auth_code' => 'ABC123']);
    }

    public function test_customer_cannot_reveal_another_customers_code(): void
    {
        [, $transaction] = $this->makeProtectedTransaction();
        $otherCustomer = User::create([
            'username' => 'other-customer',
            'email' => 'other@example.com',
            'password' => 'secret-password',
            'role' => 'customer',
        ]);

        $this->actingAs($otherCustomer, 'api')
            ->postJson("/api/v1/transactions/{$transaction->id}/reveal-auth-code", [
                'verification_method' => 'password',
                'password' => 'secret-password',
            ])
            ->assertForbidden()
            ->assertJsonMissing(['auth_code' => 'ABC123']);
    }

    public function test_auth_code_is_hidden_from_normal_transaction_serialization(): void
    {
        [, $transaction] = $this->makeProtectedTransaction();

        $this->assertArrayNotHasKey('auth_code', $transaction->toArray());
    }

    private function makeProtectedTransaction(): array
    {
        $customer = User::create([
            'username' => 'protected-customer',
            'email' => 'protected@example.com',
            'password' => 'secret-password',
            'role' => 'customer',
        ]);
        $seller = User::create([
            'username' => 'protected-seller',
            'email' => 'seller-protected@example.com',
            'password' => 'secret-password',
            'role' => 'seller',
        ]);
        $transaction = Transaction::create([
            'customer_id' => $customer->id,
            'seller_id' => $seller->id,
            'total_amount' => 100000,
            'status' => 'waiting_cod',
            'auth_code' => 'ABC123',
        ]);

        return [$customer, $transaction];
    }
}
