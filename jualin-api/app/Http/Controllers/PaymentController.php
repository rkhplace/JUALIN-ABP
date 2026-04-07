<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use App\Models\Transaction;
use App\Models\Payment;
use App\Services\MidtransService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PaymentController extends Controller
{
    protected $midtransService;

    public function __construct(MidtransService $midtransService)
    {
        $this->midtransService = $midtransService;
    }

    public function createPayment(Request $request): JsonResponse
    {
        $user = Auth::user();

        if (!in_array($user->role, ['customer', 'admin'])) {
            return ApiResponse::error(
                'Only customers and admins can create payments',
                null,
                403
            );
        }

        try {
            $transaction = Transaction::with(['items.product', 'customer'])->findOrFail($request->transaction_id);

            if ($transaction->customer_id !== $user->id && $user->role !== 'admin') {
                return ApiResponse::error(
                    'Unauthorized access to transaction',
                    null,
                    403
                );
            }

            $customerDetails = $request->customer_details;

            if (empty($customerDetails['email'])) {
                $customerDetails['email'] = $user->email;
            }
            if (empty($customerDetails['first_name'])) {
                $customerDetails['first_name'] = $user->username;
            }

            $result = $this->midtransService->createSnapToken(
                $transaction,
                $customerDetails
            );

            return ApiResponse::success(
                'Payment token created successfully',
                [
                    'snap_token' => $result['snap_token'],
                    'snap_url' => $result['snap_url'],
                    'order_id' => $result['order_id'],
                    'transaction_id' => $transaction->id,
                ],
                201
            );
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return ApiResponse::error(
                'Transaction not found',
                null,
                404
            );
        } catch (\Exception $e) {
            return ApiResponse::error(
                'Failed to create payment',
                ['error' => $e->getMessage()],
                500
            );
        }
    }

    public function handleNotification(Request $request): JsonResponse
    {
        try {
            $notification = $request->all();
            $payment = $this->midtransService->handleNotification($notification);

            return ApiResponse::success('Notification processed', $payment, 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return ApiResponse::success('Notification received (payment not found)', [], 200);
        } catch (\Exception $e) {
            return ApiResponse::success('Notification received (ignored)', [], 200);
        }
    }

    public function checkStatus(Request $request, string $orderId): JsonResponse
    {
        try {
            $status = $this->midtransService->getTransactionStatus($orderId);

            \Illuminate\Support\Facades\Log::info("Midtrans status sync", [
                'order_id' => $orderId,
                'status' => $status
            ]);

            if (!empty($status['transaction_status'])) {
                try {
                    $payment = Payment::where('order_id', $orderId)->first();
                    
                    if ($payment) {
                        $this->midtransService->syncPaymentStatus(
                            $payment,
                            $status['transaction_status'],
                            [
                                'transaction_id' => $status['transaction_id'] ?? null,
                                'payment_type' => $status['payment_type'] ?? null,
                                'bank_or_channel' => $status['bank'] ?? ($status['payment_type'] ?? null),
                                'transaction_time' => isset($status['transaction_time'])
                                    ? date('Y-m-d H:i:s', strtotime($status['transaction_time']))
                                    : now(),
                                'fraud_status' => $status['fraud_status'] ?? null,
                            ]
                        );
                    }
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::error("Failed to auto-sync payment: " . $e->getMessage());
                }
            }

            return ApiResponse::success(
                'Payment status retrieved successfully',
                $status,
                200
            );
        } catch (\Exception $e) {
            return ApiResponse::error(
                'Failed to check status',
                ['error' => $e->getMessage()],
                500
            );
        }
    }
    
    public function getPaymentsByUser(Request $request): JsonResponse
    {
        $user = Auth::user();

        $payments = Payment::with(['transaction.items.product', 'transaction.seller'])
            ->whereHas('transaction', function ($query) use ($user) {
                $query->where('customer_id', $user->id);
            })
            ->latest() // Order by latest to get the most recent attempt first
            ->get()
            ->groupBy('transaction_id')
            ->map(function ($groupedPayments) {
                // Take the most recent payment attempt for this transaction
                return $groupedPayments->first();
            })
            ->values() // Reset array keys
            ->map(function ($payment) {
                $transaction = $payment->transaction;
                $firstItem = $transaction->items->first();
                $product = $firstItem ? $firstItem->product : null;
                $seller = $transaction->seller;

                return [
                    'payment_id' => $payment->id,
                    'transaction_id' => $transaction->id,
                    'order_id' => $payment->order_id,
                    'snap_token' => $payment->transaction_status === 'pending' ? $payment->snap_token : null,
                    'snap_url' => $payment->transaction_status === 'pending' ? $payment->snap_url : null,
                    'transaction_status' => $transaction->status, // Escrow status
                    'midtrans_status' => $payment->transaction_status,
                    'gross_amount' => $payment->gross_amount,
                    'transaction_time' => $payment->created_at,
                    'first_item_name' => $product ? $product->name : 'Unknown Product',
                    'first_item_category' => $product ? $product->category : null,
                    'seller_name' => $seller ? ($seller->shop_name ?? $seller->username) : 'Unknown Seller',
                    'transaction' => [
                        'auth_code' => $transaction->auth_code,
                    ],
                ];
            });

        if ($payments->isEmpty()) {
            return ApiResponse::error('No payments found', [], 404);
        }

        return ApiResponse::success('Payments retrieved successfully', $payments, 200);
    }

    public function reissuePaymentToken(Request $request, int $paymentId): JsonResponse
    {
        $user = Auth::user();
        if (!in_array($user->role, ['customer','admin'])) {
            return ApiResponse::error('Only customers and admins can reissue payments', null, 403);
        }

        try {
            $payment = Payment::with('transaction.customer')->findOrFail($paymentId);

            if ($payment->transaction->customer_id !== $user->id && $user->role !== 'admin') {
                return ApiResponse::error('Unauthorized access to payment', null, 403);
            }

            if (strtolower($payment->transaction_status) !== 'pending') {
                return ApiResponse::error('Only pending payments can be reissued', null, 422);
            }

            $customerDetails = $request->customer_details ?? [];
            $customerDetails['email'] ??= $payment->transaction->customer->email;
            $customerDetails['first_name'] ??= $payment->transaction->customer->username ?? $payment->transaction->customer->name;

            $result = $this->midtransService->reissueSnapToken($payment, $customerDetails);

            return ApiResponse::success('Payment token reissued', [
                'snap_token' => $result['snap_token'],
                'snap_url'   => $result['snap_url'],
                'order_id'   => $result['order_id'],
                'payment_id' => $payment->id,
            ], 200);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return ApiResponse::error('Payment not found', null, 404);
        } catch (\Exception $e) {
            return ApiResponse::error('Failed to reissue token', ['error' => $e->getMessage()], 500);
        }
    }
}
