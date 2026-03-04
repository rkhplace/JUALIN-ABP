<?php

namespace App\Services;

use Midtrans\Config;
use Midtrans\Snap;
use Midtrans\Transaction as MidtransTransaction;
use Midtrans\Notification;
use App\Models\Transaction;
use App\Models\Payment;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class MidtransService
{
    public function __construct()
    {
        Config::$serverKey = config('midtrans.server_key');
        Config::$isProduction = config('midtrans.is_production');
        Config::$isSanitized = config('midtrans.is_sanitized');
        Config::$is3ds = config('midtrans.is_3ds');
    }

    public function createSnapToken(Transaction $transaction, array $customerDetails): array
    {
        $orderId = 'ORDER-' . Str::upper(Str::random(10)) . '-' . $transaction->id;


        $payment = Payment::create([
            'order_id' => $orderId,
            'transaction_id' => $transaction->id,
            'gross_amount' => $transaction->total_amount,
            'transaction_status' => 'pending',
        ]);

        $items = [];
        foreach ($transaction->items as $item) {
            $items[] = [
                'id' => $item->product_id,
                'price' => $item->price_at_purchase,
                'quantity' => $item->quantity,
                'name' => $item->product->name,
            ];
        }

        $params = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $transaction->total_amount,
            ],
            'item_details' => $items,
            'customer_details' => [
                'first_name' => $customerDetails['first_name'] ?? $transaction->customer->name,
                'last_name' => $customerDetails['last_name'] ?? '',
                'email' => $customerDetails['email'] ?? $transaction->customer->email,
                'phone' => $customerDetails['phone'] ?? '',
            ],
        ];

        try {
            $snapResponse = Snap::createTransaction($params);
            $snapToken = $snapResponse->token;
            $snapUrl = $snapResponse->redirect_url;


            $payment->update([
                'snap_token' => $snapToken,
                'snap_url' => $snapUrl,
            ]);

            return [
                'snap_token' => $snapToken,
                'snap_url' => $snapUrl,
                'order_id' => $orderId,
                'payment_id' => $payment->id,
            ];
        } catch (\Exception $e) {
            throw new \Exception('Failed to create payment token: ' . $e->getMessage());
        }
    }

    private function isValidSignature(array $data): bool
    {
        if (!isset($data['order_id'], $data['status_code'], $data['gross_amount'], $data['signature_key'])) {
            return false;
        }
        $expected = hash('sha512', $data['order_id'] . $data['status_code'] . $data['gross_amount'] . Config::$serverKey);
        return hash_equals($expected, $data['signature_key']);
    }

    public function handleNotification(array $notificationData): Payment
    {
        try {
            if (!$this->isValidSignature($notificationData)) {
                throw new \Exception('Invalid signature');
            }

            $orderId = $notificationData['order_id'];
            $transactionStatus = $notificationData['transaction_status'];
            $fraudStatus = $notificationData['fraud_status'] ?? null;

            $payment = Payment::where('order_id', $orderId)->firstOrFail();

            $payment->update([
                'midtrans_transaction_id' => $notificationData['transaction_id'] ?? $payment->midtrans_transaction_id,
                'payment_type' => $notificationData['payment_type'] ?? $payment->payment_type,
                'bank_or_channel' => $this->getBankOrChannel($notificationData),
                'transaction_status' => $transactionStatus,
                'transaction_time' => isset($notificationData['transaction_time'])
                    ? date('Y-m-d H:i:s', strtotime($notificationData['transaction_time']))
                    : now(),
            ]);

            $this->updateTransactionStatus($payment, $transactionStatus, $fraudStatus);

            return $payment->fresh();
        } catch (\Exception $e) {
            throw $e;
        }
    }

    private function updateTransactionStatus(Payment $payment, string $transactionStatus, ?string $fraudStatus): void
    {
        $transaction = $payment->transaction;
        $oldStatus = $transaction->status;
        $newStatus = match ($transactionStatus) {
            'capture' => $fraudStatus === 'accept'
            ? 'paid'
            : ($fraudStatus === 'challenge' ? 'pending' : null),
            'settlement' => 'paid',
            'pending' => 'pending',
            'deny' => 'failed',
            'expire' => 'expired',
            default => null,
        };

        if (!$newStatus) {
            return;
        }

        $transaction->update(['status' => $newStatus]);

        $failedStatuses = ['failed', 'expired', 'cancelled', 'refunded'];
        if (in_array($newStatus, $failedStatuses) && !in_array($oldStatus, $failedStatuses)) {
            $this->restoreStock($transaction);
        }
    }

    private function restoreStock(Transaction $transaction): void
    {
        try {
            DB::beginTransaction();

            $transaction->load('items.product');

            foreach ($transaction->items as $item) {
                if ($item->product) {
                    $item->product->increment('stock_quantity', $item->quantity);
                }
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to restore stock for transaction: ' . $transaction->id, [
                'error' => $e->getMessage()
            ]);
        }
    }

    private function getBankOrChannel(array $notification): ?string
    {
        if (isset($notification['va_numbers']) && !empty($notification['va_numbers'])) {
            // Handle array structure: va_numbers is typically list of objects or arrays
            $va = $notification['va_numbers'][0];
            return is_array($va) ? $va['bank'] : $va->bank;
        }

        if (isset($notification['payment_type'])) {
            if (in_array($notification['payment_type'], ['gopay', 'shopeepay', 'qris'])) {
                return $notification['payment_type'];
            }
        }

        if (isset($notification['bank'])) {
            return $notification['bank'];
        }

        return $notification['payment_type'] ?? null;
    }

    public function getTransactionStatus(string $orderId): array
    {
        try {
            $status = MidtransTransaction::status($orderId);
            return (array) $status;
        } catch (\Exception $e) {
            throw new \Exception('Failed to check transaction status: ' . $e->getMessage());
        }
    }

    public function reissueSnapToken(Payment $payment, array $customerDetails): array
    {
        $transaction = $payment->transaction;
        $orderId = 'ORDER-' . Str::upper(Str::random(10)) . '-' . $transaction->id;

        $items = [];
        foreach ($transaction->items as $item) {
            $items[] = [
                'id' => $item->product_id,
                'price' => $item->price_at_purchase,
                'quantity' => $item->quantity,
                'name' => $item->product->name,
            ];
        }

        $params = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $transaction->total_amount,
            ],
            'item_details' => $items,
            'customer_details' => [
                'first_name' => $customerDetails['first_name'] ?? $transaction->customer->name,
                'last_name' => $customerDetails['last_name'] ?? '',
                'email' => $customerDetails['email'] ?? $transaction->customer->email,
                'phone' => $customerDetails['phone'] ?? '',
            ],
        ];

        $snapResponse = Snap::createTransaction($params);

        $payment->update([
            'order_id' => $orderId,
            'snap_token' => $snapResponse->token,
            'snap_url' => $snapResponse->redirect_url,
            'midtrans_transaction_id' => null,
            'transaction_status' => 'pending',
            'transaction_time' => now(),
        ]);

        return [
            'snap_token' => $snapResponse->token,
            'snap_url' => $snapResponse->redirect_url,
            'order_id' => $orderId,
            'payment_id' => $payment->id,
        ];
    }
}