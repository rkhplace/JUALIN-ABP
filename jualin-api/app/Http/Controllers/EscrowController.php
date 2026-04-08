<?php

namespace App\Http\Controllers;

use App\Http\Responses\ApiResponse;
use App\Models\Transaction;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class EscrowController extends Controller
{
    /**
     * Seller claims the payment using the auth code.
     */
    public function claim(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'auth_code' => 'required|string',
        ]);

        $user = Auth::user();
        
        try {
            DB::beginTransaction();

            // Lock the transaction row to prevent race conditions (double claim)
            $transaction = Transaction::where('id', $id)->lockForUpdate()->firstOrFail();

            if ($transaction->seller_id !== $user->id) {
                return ApiResponse::error('Unauthorized', null, 403);
            }

            if ($transaction->status !== 'waiting_cod') {
                return ApiResponse::error('Transaction is not in waiting_cod status', null, 400);
            }

            if ($transaction->auth_code !== $request->auth_code) {
                return ApiResponse::error('Invalid authentication code', null, 400);
            }

            // Update transaction
            $transaction->status = 'verified';
            $transaction->save();

            // Lock the seller row so concurrent wallet updates stay consistent.
            $seller = User::where('id', $transaction->seller_id)->lockForUpdate()->firstOrFail();
            $seller->wallet_balance += $transaction->total_amount;
            $seller->save();

            // Record wallet transaction
            WalletTransaction::create([
                'user_id' => $seller->id,
                'amount' => $transaction->total_amount,
                'type' => 'claim',
                'reference_transaction_id' => $transaction->id,
            ]);

            DB::commit();

            return ApiResponse::success('Escrow claimed successfully', [
                'transaction' => $transaction->fresh(),
                'wallet_balance' => (float) $seller->wallet_balance,
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            DB::rollBack();
            return ApiResponse::error('Transaction not found', null, 404);
        } catch (\Exception $e) {
            DB::rollBack();
            return ApiResponse::error('Failed to claim escrow', ['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Buyer requests a refund (rejects the product).
     */
    public function refund(Request $request, string $id): JsonResponse
    {
        $user = Auth::user();

        try {
            DB::beginTransaction();

            // Lock the transaction row
            $transaction = Transaction::where('id', $id)->lockForUpdate()->firstOrFail();

            if ($transaction->customer_id !== $user->id) {
                return ApiResponse::error('Unauthorized', null, 403);
            }

            if ($transaction->status !== 'waiting_cod') {
                return ApiResponse::error('Transaction is not in a valid state for refund', null, 400);
            }

            // Update transaction
            $transaction->status = 'refunded';
            $transaction->save();

            // Lock the buyer row so refund credits do not race with other wallet actions.
            $buyer = User::where('id', $transaction->customer_id)->lockForUpdate()->firstOrFail();
            $buyer->wallet_balance += $transaction->total_amount;
            $buyer->save();

            // Record wallet transaction
            WalletTransaction::create([
                'user_id' => $buyer->id,
                'amount' => $transaction->total_amount,
                'type' => 'refund',
                'reference_transaction_id' => $transaction->id,
            ]);
            
            // Restore stock since the transaction is refunded
            foreach ($transaction->items as $item) {
                if ($item->product) {
                    $item->product->increment('stock_quantity', $item->quantity);
                }
            }

            DB::commit();

            return ApiResponse::success('Refund processed successfully', [
                'transaction' => $transaction->fresh(),
                'wallet_balance' => (float) $buyer->wallet_balance,
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            DB::rollBack();
            return ApiResponse::error('Transaction not found', null, 404);
        } catch (\Exception $e) {
            DB::rollBack();
            return ApiResponse::error('Failed to process refund', ['error' => $e->getMessage()], 500);
        }
    }
}
