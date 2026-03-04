<?php

namespace App\Http\Controllers;

use App\Http\Requests\TransactionStoreRequest;
use App\Http\Responses\ApiResponse;
use App\Models\Transaction;
use App\Models\TransactionItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class TransactionController extends Controller
{
    public function store(TransactionStoreRequest $request): JsonResponse
    {
        $user = Auth::user();

        if (!in_array($user->role, ['customer', 'admin'])) {
            return ApiResponse::error(
                'Only customers and admins can create transactions',
                null,
                403
            );
        }

        try {
            DB::beginTransaction();

            $customerId = $user->id;
            $totalAmount = 0;
            $items = [];
            $productsToUpdate = [];

            foreach ($request->items as $itemData) {
                $product = \App\Models\Product::findOrFail($itemData['product_id']);
                $quantity = $itemData['quantity'];

                if ($product->stock_quantity < $quantity) {
                    DB::rollBack();
                    return ApiResponse::error(
                        'Insufficient stock for ' . $product->name . '. Available: ' . $product->stock_quantity,
                        null,
                        400
                    );
                }

                $subtotal = $product->price * $quantity;
                $totalAmount += $subtotal;

                $items[] = [
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'price_at_purchase' => $product->price,
                    'subtotal' => $subtotal,
                ];

                $productsToUpdate[] = [
                    'product' => $product,
                    'quantity' => $quantity,
                ];
            }

            $transaction = Transaction::create([
                'customer_id' => $customerId,
                'seller_id' => $request->seller_id,
                'total_amount' => $totalAmount,
                'status' => 'pending',
            ]);

            foreach ($items as $item) {
                TransactionItem::create([
                    'transaction_id' => $transaction->id,
                    ...$item,
                ]);
            }

            foreach ($productsToUpdate as $item) {
                $item['product']->decrement('stock_quantity', $item['quantity']);
            }

            DB::commit();

            $transaction->load(['items.product', 'customer', 'seller']);

            return ApiResponse::success(
                'Transaction created successfully',
                $transaction,
                201
            );
        } catch (\Exception $e) {
            DB::rollBack();
            return ApiResponse::error(
                'Failed to create transaction',
                ['error' => $e->getMessage()],
                500
            );
        }
    }

    public function index(Request $request): JsonResponse
    {
        $user = Auth::user();

        $transactions = Transaction::with(['items.product', 'customer', 'seller', 'payment'])
            ->where(function ($query) use ($user) {
                $query->where('customer_id', $user->id)
                    ->orWhere('seller_id', $user->id);
            })
            ->latest()
            ->paginate((int) $request->get('per_page', 10));

        return ApiResponse::success(
            'Transactions retrieved successfully',
            $transactions,
            200
        );
    }

    public function show(string $id): JsonResponse
    {
        try {
            $transaction = Transaction::with(['items.product', 'customer', 'seller', 'payment'])
                ->findOrFail($id);

            if (
                $transaction->customer_id !== auth()->id() &&
                $transaction->seller_id !== auth()->id()
            ) {
                return ApiResponse::error(
                    'Unauthorized',
                    null,
                    403
                );
            }

            return ApiResponse::success(
                'Transaction retrieved successfully',
                $transaction,
                200
            );
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return ApiResponse::error(
                'Transaction not found',
                null,
                404
            );
        }
    }

    public function incomeStatistics(Request $request): JsonResponse
    {
        $user = Auth::user();
        $period = $request->get('period', 'Month'); // Year, Month, Week

        // Get all transactions for this seller
        $transactions = Transaction::where('seller_id', $user->id)
            ->with('payment')
            ->get();

        // Calculate Balance (total of all transactions)
        $balance = $transactions->sum('total_amount');

        // Calculate Transferred (total of paid/completed transactions)
        $transferred = $transactions
            ->whereIn('status', ['paid', 'completed'])
            ->sum('total_amount');

        // Group transactions by period for chart data
        $chartData = $this->groupTransactionsByPeriod($transactions, $period);

        return ApiResponse::success(
            'Income statistics retrieved successfully',
            [
                'balance' => (float) $balance,
                'transferred' => (float) $transferred,
                'chart_data' => $chartData,
                'period' => $period,
            ],
            200
        );
    }

    private function groupTransactionsByPeriod($transactions, $period): array
    {
        $grouped = [];
        $groupedWithDate = []; // Store date for sorting

        foreach ($transactions as $transaction) {
            $date = \Carbon\Carbon::parse($transaction->created_at);
            $key = '';
            $sortDate = $date;

            switch ($period) {
                case 'Year':
                    $key = $date->format('Y');
                    $sortDate = $date->copy()->startOfYear();
                    break;
                case 'Month':
                    $key = $date->format('M Y'); // e.g., "Jan 2024"
                    $sortDate = $date->copy()->startOfMonth();
                    break;
                case 'Week':
                    $weekStart = $date->copy()->startOfWeek();
                    $weekEnd = $date->copy()->endOfWeek();
                    $key = $weekStart->format('M d') . ' - ' . $weekEnd->format('M d, Y');
                    $sortDate = $weekStart;
                    break;
                default:
                    $key = $date->format('M Y');
                    $sortDate = $date->copy()->startOfMonth();
            }

            if (!isset($grouped[$key])) {
                $grouped[$key] = 0;
                $groupedWithDate[$key] = $sortDate;
            }

            $grouped[$key] += (float) $transaction->total_amount;
        }

        // Convert to array format for chart with sorting
        $chartData = [];
        foreach ($grouped as $label => $amount) {
            $chartData[] = [
                'label' => $label,
                'income' => $amount,
                'sort_date' => $groupedWithDate[$label],
            ];
        }

        // Sort by date (ascending)
        usort($chartData, function ($a, $b) {
            return $a['sort_date']->compare($b['sort_date']);
        });

        // Remove sort_date before returning
        $chartData = array_map(function ($item) {
            unset($item['sort_date']);
            return $item;
        }, $chartData);

        // Limit to last 6-12 periods for better visualization
        $maxPeriods = $period === 'Year' ? 5 : ($period === 'Month' ? 12 : 8);
        $chartData = array_slice($chartData, -$maxPeriods);

        return $chartData;
    }
}
