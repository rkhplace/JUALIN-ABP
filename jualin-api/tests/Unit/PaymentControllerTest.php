<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use App\Models\User;
use App\Models\Product;
use App\Models\Transaction;
use App\Models\TransactionItem;

class PaymentControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }


    public function testCreatePaymentForbiddenForSellerRole()
    {
        $seller = User::create([
            'username' => 'seller',
            'email' => 'seller@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);

        $this->actingAs($seller, 'api');

        $res = $this->json('POST', '/api/v1/payments/create', ['transaction_id' => 1]);

        $res->assertStatus(403)
            ->assertJson([
                'success' => false,
                'status_code' => 403,
                'message' => 'Forbidden: you do not have permission to access this resource.',
                'errors' => null,
            ]);
    }

    public function testCreatePaymentSuccessReturnsSnapToken()
    {
        $customer = User::create([
            'username' => 'cust',
            'email' => 'cust@example.com',
            'password' => 'pw',
            'role' => 'customer',
        ]);
        $seller = User::create([
            'username' => 'seller',
            'email' => 'seller@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);
        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Item',
            'price' => 50000,
            'stock_quantity' => 5,
        ]);
        $trx = Transaction::create([
            'customer_id' => $customer->id,
            'seller_id' => $seller->id,
            'total_amount' => 50000,
            'status' => 'pending',
        ]);
        TransactionItem::create([
            'transaction_id' => $trx->id,
            'product_id' => $product->id,
            'quantity' => 1,
            'price_at_purchase' => 50000,
            'subtotal' => 50000,
        ]);

        Mockery::mock('alias:Midtrans\Snap')
            ->shouldReceive('createTransaction')
            ->once()
            ->andReturn((object)['token' => 'SNAP_TOKEN','redirect_url' => 'https://pay.example/redirect']);

        $this->actingAs($customer, 'api');

        $res = $this->json('POST', '/api/v1/payments/create', [
            'transaction_id' => $trx->id,
            'customer_details' => ['email' => $customer->email,'first_name' => $customer->username],
        ]);

        $res->assertStatus(201)
            ->assertJsonStructure(['message', 'data' => ['snap_token', 'snap_url', 'order_id', 'transaction_id']]);
    }

    public function testCheckStatusReturnsSuccess()
    {
        $user = User::create([
            'username' => 'u1',
            'email' => 'u1@example.com',
            'password' => 'pw',
            'role' => 'customer',
        ]);
        $this->actingAs($user, 'api');

        Mockery::mock('alias:Midtrans\Transaction')
            ->shouldReceive('status')
            ->once()
            ->andReturn((object)['transaction_status' => 'pending', 'status_code' => '201']);

        $res = $this->json('GET', '/api/v1/payments/status/ORDER-1');
        $res->assertStatus(200)->assertJsonStructure(['message', 'data']);
    }
}