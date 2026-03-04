<?php

namespace Tests\Unit;

use Tests\TestCase;
use Mockery;
use App\Services\MidtransService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use App\Models\User;
use App\Models\Product;
use App\Models\Transaction;
use App\Models\TransactionItem;
use App\Models\Payment;

class MidtransServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Config::set('midtrans.server_key', 'server_test_key');
        Config::set('midtrans.is_production', false);
        Config::set('midtrans.is_sanitized', true);
        Config::set('midtrans.is_3ds', true);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    private function makeTransactionWithItem(): Transaction
    {
        $customer = User::create([
            'username' => 'customer1',
            'email' => 'customer1@example.com',
            'password' => 'password',
            'role' => 'customer',
        ]);
        $seller = User::create([
            'username' => 'seller1',
            'email' => 'seller1@example.com',
            'password' => 'password',
            'role' => 'seller',
        ]);
        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Sample Product',
            'description' => 'Desc',
            'price' => 100000,
            'stock_quantity' => 10,
            'status' => 'active',
            'condition' => 'new',
        ]);
        $trx = Transaction::create([
            'customer_id' => $customer->id,
            'seller_id' => $seller->id,
            'total_amount' => 300000,
            'status' => 'pending',
        ]);
        TransactionItem::create([
            'transaction_id' => $trx->id,
            'product_id' => $product->id,
            'quantity' => 3,
            'price_at_purchase' => 100000,
            'subtotal' => 300000,
        ]);
        return $trx->fresh()->load(['items.product', 'customer']);
    }

    public function testCreateSnapTokenCreatesPaymentAndReturnsTokenData()
    {
        Mockery::mock('alias:Midtrans\Snap')
            ->shouldReceive('createTransaction')
            ->once()
            ->andReturn((object)['token' => 'SNAP_TOKEN','redirect_url' => 'https://pay.example/redirect']);

        $transaction = $this->makeTransactionWithItem();
        $service = new MidtransService();
        $result = $service->createSnapToken($transaction, ['first_name' => 'John','email' => 'john@example.com']);

        $this->assertSame('SNAP_TOKEN', $result['snap_token']);
        $this->assertSame('https://pay.example/redirect', $result['snap_url']);
        $this->assertNotEmpty($result['order_id']);

        $payment = Payment::find($result['payment_id']);
        $this->assertNotNull($payment);
        $this->assertSame('pending', $payment->transaction_status);
    }

    public function testHandleNotificationSettlementUpdatesRecords()
    {
        $trx = $this->makeTransactionWithItem();
        $orderId = 'ORDER-ABC123-' . $trx->id;
        Payment::create([
            'order_id' => $orderId,
            'transaction_id' => $trx->id,
            'gross_amount' => $trx->total_amount,
            'transaction_status' => 'pending',
        ]);

        $statusCode = '200';
        $gross = (string)$trx->total_amount;
        $signature = hash('sha512', $orderId . $statusCode . $gross . config('midtrans.server_key'));

        $service = new MidtransService();
        $updated = $service->handleNotification([
            'order_id' => $orderId,
            'status_code' => $statusCode,
            'gross_amount' => $gross,
            'signature_key' => $signature,
            'transaction_status' => 'settlement',
            'payment_type' => 'gopay',
            'transaction_time' => '2025-01-01 10:00:00',
            'transaction_id' => 'midtrans-123',
        ]);

        $this->assertSame('settlement', $updated->transaction_status);
        $this->assertSame('paid', $updated->transaction->fresh()->status);
    }

    public function testHandleNotificationExpireRestoresStock()
    {
        $trx = $this->makeTransactionWithItem();
        $product = $trx->items->first()->product;
        $initialStock = $product->stock_quantity;
        $qty = $trx->items->first()->quantity;

        $orderId = 'ORDER-EXP-' . $trx->id;
        Payment::create([
            'order_id' => $orderId,
            'transaction_id' => $trx->id,
            'gross_amount' => $trx->total_amount,
            'transaction_status' => 'pending',
        ]);

        $statusCode = '200';
        $gross = (string)$trx->total_amount;
        $signature = hash('sha512', $orderId . $statusCode . $gross . config('midtrans.server_key'));

        $service = new MidtransService();
        $service->handleNotification([
            'order_id' => $orderId,
            'status_code' => $statusCode,
            'gross_amount' => $gross,
            'signature_key' => $signature,
            'transaction_status' => 'expire',
            'payment_type' => 'bank_transfer',
            'transaction_time' => '2025-01-01 12:00:00',
        ]);

        $this->assertSame($initialStock + $qty, $product->fresh()->stock_quantity);
        $this->assertSame('expired', $trx->fresh()->status);
    }

    public function testGetTransactionStatusReturnsArray()
    {
        Mockery::mock('alias:Midtrans\Transaction')
            ->shouldReceive('status')
            ->once()
            ->with('ORDER-123')
            ->andReturn((object)['status_code' => '201','transaction_status' => 'pending']);

        $service = new MidtransService();
        $status = $service->getTransactionStatus('ORDER-123');
        $this->assertIsArray($status);
        $this->assertSame('201', $status['status_code']);
    }

    public function testReissueSnapTokenResetsPaymentAndReturnsNewToken()
    {
        Mockery::mock('alias:Midtrans\Snap')
            ->shouldReceive('createTransaction')
            ->once()
            ->andReturn((object)['token' => 'NEW_TOKEN','redirect_url' => 'https://pay.example/new']);

        $trx = $this->makeTransactionWithItem();

        $payment = Payment::create([
            'order_id' => 'ORDER-OLD-' . $trx->id,
            'transaction_id' => $trx->id,
            'gross_amount' => $trx->total_amount,
            'transaction_status' => 'pending',
            'snap_token' => 'OLD_TOKEN',
            'snap_url' => 'https://pay.example/old',
            'midtrans_transaction_id' => 'mt-old-1',
        ]);

        $service = new MidtransService();
        $result = $service->reissueSnapToken($payment->fresh(), ['first_name' => 'Jane','email' => 'jane@example.com']);

        $payment = $payment->fresh();
        $this->assertSame('NEW_TOKEN', $payment->snap_token);
        $this->assertSame('https://pay.example/new', $payment->snap_url);
        $this->assertNull($payment->midtrans_transaction_id);
        $this->assertSame('NEW_TOKEN', $result['snap_token']);
    }
}