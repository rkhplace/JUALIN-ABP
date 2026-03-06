<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$payment = \App\Models\Payment::latest()->where('transaction_status', 'pending')->first();
if (!$payment) {
    die("No pending payments found to test.\n");
}

echo "Testing webhook for Order ID: " . $payment->order_id . "\n";

$midtransService = app(\App\Services\MidtransService::class);
$timestamp = now()->toDateTimeString();

$signatureKey = hash('sha512', $payment->order_id . '200' . $payment->gross_amount . config('midtrans.server_key'));

$notification = [
    'order_id' => $payment->order_id,
    'status_code' => '200',
    'gross_amount' => $payment->gross_amount,
    'signature_key' => $signatureKey,
    'transaction_status' => 'settlement',
    'transaction_id' => 'mock-mid-'.rand(1000,9999),
    'payment_type' => 'gopay',
    'transaction_time' => $timestamp,
];

try {
    $updatedPayment = $midtransService->handleNotification($notification);
    echo "Webhook Success!\n";
    $transaction = $updatedPayment->transaction;
    echo "Payment Status: " . $updatedPayment->transaction_status . "\n";
    echo "Transaction Status: " . $transaction->status . "\n";
    echo "Auth Code: " . $transaction->auth_code . "\n";
} catch (\Exception $e) {
    echo "Webhook Failed: " . $e->getMessage() . "\n";
}
