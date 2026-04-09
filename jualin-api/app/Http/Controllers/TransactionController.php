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
use App\Models\WalletTransaction;
use Illuminate\Support\Str;

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

    public function payWallet(Request $request): JsonResponse
    {
        $user = Auth::user();

        if (!in_array($user->role, ['customer', 'admin'])) {
            return ApiResponse::error(
                'Only customers and admins can create transactions',
                null,
                403
            );
        }

        $request->validate([
            'seller_id' => 'required|integer|exists:users,id',
            'product_id' => 'required|integer|exists:products,id',
        ]);

        try {
            return DB::transaction(function () use ($user, $request) {
                $buyer = \App\Models\User::where('id', $user->id)->lockForUpdate()->firstOrFail();
                $product = \App\Models\Product::where('id', $request->product_id)->lockForUpdate()->firstOrFail();
                $quantity = 1;

                if ($product->stock_quantity < $quantity) {
                    throw new \Exception('Insufficient stock for ' . $product->name . '. Available: ' . $product->stock_quantity);
                }

                if ($buyer->wallet_balance < $product->price) {
                    throw new \Exception('Insufficient wallet balance');
                }

                $totalAmount = $product->price * $quantity;

                // Deduct wallet balance
                $buyer->wallet_balance -= $totalAmount;
                $buyer->save();

                // Create transaction
                $transaction = Transaction::create([
                    'customer_id' => $buyer->id,
                    'seller_id' => $request->seller_id,
                    'total_amount' => $totalAmount,
                    'status' => 'waiting_cod',
                    'auth_code' => strtoupper(Str::random(6)),
                ]);

                // Create transaction item
                TransactionItem::create([
                    'transaction_id' => $transaction->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'price_at_purchase' => $product->price,
                    'subtotal' => $totalAmount,
                ]);

                // Decrement product stock
                $product->stock_quantity -= $quantity;
                $product->save();

                // Record wallet transaction
                WalletTransaction::create([
                    'user_id' => $buyer->id,
                    'amount' => -$totalAmount,
                    'type' => 'purchase',
                    'reference_transaction_id' => $transaction->id,
                ]);

                // Create a Payment record so it appears in the purchase history API
                $orderId = 'WALLET-' . $transaction->id . '-' . time();
                \App\Models\Payment::create([
                    'transaction_id' => $transaction->id,
                    'order_id' => $orderId,
                    'gross_amount' => $totalAmount,
                    'payment_type' => 'jualin_wallet',
                    'transaction_status' => 'settlement',
                    'transaction_time' => now(),
                ]);

                $transaction->load(['items.product', 'customer', 'seller']);

                return ApiResponse::success(
                    'Wallet payment successful',
                    $transaction,
                    201
                );
            });
        } catch (\Exception $e) {
            $statusCode = $e->getMessage() === 'Insufficient wallet balance' || str_contains($e->getMessage(), 'Insufficient stock') ? 400 : 500;
            return ApiResponse::error(
                $e->getMessage() ?: 'Failed to process wallet payment',
                null,
                $statusCode
            );
        }
    }

    public function index(Request $request): JsonResponse
    {
        $user = Auth::user();

        $query = Transaction::with(['items.product', 'customer', 'seller', 'payment' => function($q) {
                // Ensure we get the latest payment attempt if there are multiple
                $q->latest();
            }]);

        if ($user->role !== 'admin') {
            $query->where(function ($q) use ($user) {
                $q->where('customer_id', $user->id)
                    ->orWhere('seller_id', $user->id);
            });
        }

        $transactions = $query->latest()
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
        $period = $request->get('period', 'Month'); // Year, Month, Week, Day
        [$startDate, $endDate] = $this->resolveChartRange($request, $period);

        $claimed = (float) WalletTransaction::query()
            ->where('user_id', $user->id)
            ->where('type', 'claim')
            ->sum(DB::raw('ABS(amount)'));

        $successfulWithdrawals = $this->successfulWithdrawalsQuery($user->id);

        $withdrawn = (float) (clone $successfulWithdrawals)
            ->sum(DB::raw('ABS(amount)'));

        $chartData = $this->groupWithdrawTransactionsByPeriod(
            clone $successfulWithdrawals,
            $period,
            $startDate,
            $endDate
        );
        $labels = array_column($chartData, 'label');
        $fullLabels = array_column($chartData, 'full_label');
        $data = array_map(fn ($item) => (float) $item['amount'], $chartData);
        $chartTotal = array_sum($data);

        return ApiResponse::success(
            'Income statistics retrieved successfully',
            [
                'balance' => (float) $user->wallet_balance,
                'chart_total' => (float) $chartTotal,
                'claimed' => $claimed,
                'transferred' => $withdrawn,
                'withdrawn' => $withdrawn,
                'current_balance' => (float) $user->wallet_balance,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'labels' => $labels,
                'full_labels' => $fullLabels,
                'data' => $data,
                'chart_data' => $chartData,
                'period' => $period,
            ],
            200
        );
    }

    private function successfulWithdrawalsQuery(int $userId)
    {
        return WalletTransaction::query()
            ->where('user_id', $userId)
            ->where('type', 'withdraw')
            ->where('amount', '<', 0);
    }

    private function resolveChartRange(Request $request, string $period): array
    {
        $today = now();
        $hasCustomStart = $request->filled('start_date');
        $hasCustomEnd = $request->filled('end_date');

        if ($hasCustomStart || $hasCustomEnd) {
            $startDate = $hasCustomStart
                ? \Carbon\Carbon::parse($request->get('start_date'))->startOfDay()
                : $today->copy()->startOfDay();
            $endDate = $hasCustomEnd
                ? \Carbon\Carbon::parse($request->get('end_date'))->endOfDay()
                : $today->copy()->endOfDay();

            if ($startDate->gt($endDate)) {
                [$startDate, $endDate] = [$endDate->copy()->startOfDay(), $startDate->copy()->endOfDay()];
            }

            return [$startDate, $endDate];
        }

        return match ($period) {
            'Year' => [$today->copy()->subYears(4)->startOfYear(), $today->copy()->endOfYear()],
            'Week' => [$today->copy()->subWeeks(7)->startOfWeek(), $today->copy()->endOfWeek()],
            'Day' => [$today->copy()->subDays(13)->startOfDay(), $today->copy()->endOfDay()],
            default => [$today->copy()->subMonths(11)->startOfMonth(), $today->copy()->endOfMonth()],
        };
    }

    private function groupWithdrawTransactionsByPeriod($query, string $period, $startDate, $endDate): array
    {
        $driver = DB::connection()->getDriverName();
        $normalizedPeriod = in_array($period, ['Year', 'Month', 'Week', 'Day'], true) ? $period : 'Month';

        if ($normalizedPeriod === 'Year') {
            return $this->groupWithdrawByYear($query, $driver, $startDate, $endDate);
        }

        if ($normalizedPeriod === 'Week') {
            return $this->groupWithdrawByWeek($query, $driver, $startDate, $endDate);
        }

        if ($normalizedPeriod === 'Day') {
            return $this->groupWithdrawByDay($query, $driver, $startDate, $endDate);
        }

        return $this->groupWithdrawByMonth($query, $driver, $startDate, $endDate);
    }

    private function groupWithdrawByYear($query, string $driver, $startDate, $endDate): array
    {
        $query->whereBetween('created_at', [$startDate, $endDate]);

        if ($driver === 'sqlite') {
            $rows = $query
                ->selectRaw("CAST(strftime('%Y', created_at) AS INTEGER) AS period_year")
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw("strftime('%Y', created_at)")
                ->orderByRaw("CAST(strftime('%Y', created_at) AS INTEGER)")
                ->get();
        } else {
            $rows = $query
                ->selectRaw('EXTRACT(YEAR FROM created_at)::INT AS period_year')
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw('EXTRACT(YEAR FROM created_at)')
                ->orderByRaw('EXTRACT(YEAR FROM created_at)')
                ->get();
        }

        $totalsByYear = $rows->mapWithKeys(function ($row) {
            return [(string) $row->period_year => (float) $row->total_amount];
        });

        $period = \Carbon\CarbonPeriod::create(
            $startDate->copy()->startOfYear(),
            '1 year',
            $endDate->copy()->startOfYear()
        );

        return collect($period)->map(function ($date) use ($totalsByYear) {
            $periodKey = $date->format('Y');

            return [
                'label' => $periodKey,
                'full_label' => $periodKey,
                'amount' => (float) ($totalsByYear[$periodKey] ?? 0),
                'income' => (float) ($totalsByYear[$periodKey] ?? 0),
                'period_key' => $periodKey,
            ];
        })->values()->all();
    }

    private function groupWithdrawByMonth($query, string $driver, $startDate, $endDate): array
    {
        $query->whereBetween('created_at', [$startDate, $endDate]);

        if ($driver === 'sqlite') {
            $rows = $query
                ->selectRaw("CAST(strftime('%Y', created_at) AS INTEGER) AS period_year")
                ->selectRaw("CAST(strftime('%m', created_at) AS INTEGER) AS period_month")
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw("strftime('%Y', created_at), strftime('%m', created_at)")
                ->orderByRaw("CAST(strftime('%Y', created_at) AS INTEGER)")
                ->orderByRaw("CAST(strftime('%m', created_at) AS INTEGER)")
                ->get();
        } else {
            $rows = $query
                ->selectRaw('EXTRACT(YEAR FROM created_at)::INT AS period_year')
                ->selectRaw('EXTRACT(MONTH FROM created_at)::INT AS period_month')
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw('EXTRACT(YEAR FROM created_at), EXTRACT(MONTH FROM created_at)')
                ->orderByRaw('EXTRACT(YEAR FROM created_at)')
                ->orderByRaw('EXTRACT(MONTH FROM created_at)')
                ->get();
        }

        $totalsByMonth = $rows->mapWithKeys(function ($row) {
            $date = \Carbon\Carbon::create((int) $row->period_year, (int) $row->period_month, 1);

            return [$date->format('Y-m') => (float) $row->total_amount];
        });

        $period = \Carbon\CarbonPeriod::create(
            $startDate->copy()->startOfMonth(),
            '1 month',
            $endDate->copy()->startOfMonth()
        );

        return collect($period)->map(function ($date) use ($totalsByMonth) {
            $periodKey = $date->format('Y-m');

            return [
                'label' => $date->format('M'),
                'full_label' => $date->format('M Y'),
                'amount' => (float) ($totalsByMonth[$periodKey] ?? 0),
                'income' => (float) ($totalsByMonth[$periodKey] ?? 0),
                'period_key' => $periodKey,
            ];
        })->values()->all();
    }

    private function groupWithdrawByWeek($query, string $driver, $startDate, $endDate): array
    {
        $query->whereBetween('created_at', [$startDate, $endDate]);

        if ($driver === 'sqlite') {
            $rows = $query
                ->selectRaw("CAST(strftime('%Y', created_at) AS INTEGER) AS period_year")
                ->selectRaw("CAST(strftime('%W', created_at) AS INTEGER) AS period_week")
                ->selectRaw("MIN(date(created_at)) AS period_start")
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw("strftime('%Y', created_at), strftime('%W', created_at)")
                ->orderByRaw("CAST(strftime('%Y', created_at) AS INTEGER)")
                ->orderByRaw("CAST(strftime('%W', created_at) AS INTEGER)")
                ->get();
        } else {
            $rows = $query
                ->selectRaw('EXTRACT(ISOYEAR FROM created_at)::INT AS period_year')
                ->selectRaw('EXTRACT(WEEK FROM created_at)::INT AS period_week')
                ->selectRaw("MIN(DATE_TRUNC('week', created_at)) AS period_start")
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw('EXTRACT(ISOYEAR FROM created_at), EXTRACT(WEEK FROM created_at)')
                ->orderByRaw('EXTRACT(ISOYEAR FROM created_at)')
                ->orderByRaw('EXTRACT(WEEK FROM created_at)')
                ->get();
        }

        $totalsByWeek = $rows->mapWithKeys(function ($row) {
            $weekStart = \Carbon\Carbon::parse($row->period_start)->startOfWeek();
            $periodKey = $weekStart->format('o') . '-W' . $weekStart->format('W');

            return [$periodKey => (float) $row->total_amount];
        });

        $period = \Carbon\CarbonPeriod::create(
            $startDate->copy()->startOfWeek(),
            '1 week',
            $endDate->copy()->startOfWeek()
        );

        return collect($period)->map(function ($date) use ($totalsByWeek) {
            $periodKey = $date->format('o') . '-W' . $date->format('W');

            return [
                'label' => 'W' . $date->format('W'),
                'full_label' => 'Week ' . $date->format('W') . ' ' . $date->format('o'),
                'amount' => (float) ($totalsByWeek[$periodKey] ?? 0),
                'income' => (float) ($totalsByWeek[$periodKey] ?? 0),
                'period_key' => $periodKey,
            ];
        })->values()->all();
    }

    private function groupWithdrawByDay($query, string $driver, $startDate, $endDate): array
    {
        $query->whereBetween('created_at', [$startDate, $endDate]);

        if ($driver === 'sqlite') {
            $rows = $query
                ->selectRaw("date(created_at) AS period_day")
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw("date(created_at)")
                ->orderByRaw("date(created_at)")
                ->get();
        } else {
            $rows = $query
                ->selectRaw("DATE(created_at) AS period_day")
                ->selectRaw('SUM(ABS(amount)) AS total_amount')
                ->groupByRaw('DATE(created_at)')
                ->orderByRaw('DATE(created_at)')
                ->get();
        }

        $totalsByDate = $rows->mapWithKeys(function ($row) {
            return [(string) $row->period_day => (float) $row->total_amount];
        });

        $period = \Carbon\CarbonPeriod::create($startDate->copy()->startOfDay(), '1 day', $endDate->copy()->startOfDay());

        return collect($period)->map(function ($date) use ($totalsByDate) {
            $periodKey = $date->format('Y-m-d');

            return [
                'label' => $date->format('d'),
                'full_label' => $date->format('d M Y'),
                'amount' => (float) ($totalsByDate[$periodKey] ?? 0),
                'income' => (float) ($totalsByDate[$periodKey] ?? 0),
                'date' => $periodKey,
                'period_key' => $periodKey,
            ];
        })->values()->all();
    }
    public function withdraw(Request $request): JsonResponse
    {
        $user = Auth::user();

        if ($user->role !== 'seller') {
            return ApiResponse::error('Only sellers can withdraw wallet balances', null, 403);
        }

        $request->validate([
            'amount' => 'required|numeric|min:1',
            'bank_name' => 'required|string',
            'account_number' => 'required|string',
            'account_name' => 'required|string',
        ]);

        $amount = $request->amount;

        try {
            return DB::transaction(function () use ($user, $amount) {
                // Lock the user row for update
                $lockedUser = \App\Models\User::where('id', $user->id)->lockForUpdate()->first();

                if ($amount > $lockedUser->wallet_balance) {
                    return ApiResponse::error('Insufficient wallet balance', null, 400);
                }

                // Deduct balance
                $lockedUser->wallet_balance -= $amount;
                $lockedUser->save();

                // Create wallet transaction record
                WalletTransaction::create([
                    'user_id' => $lockedUser->id,
                    'amount' => -$amount,
                    'type' => 'withdraw',
                    'reference_transaction_id' => null,
                ]);

                return ApiResponse::success(
                    'Withdrawal successful',
                    ['remaining_balance' => $lockedUser->wallet_balance],
                    200
                );
            });
        } catch (\Exception $e) {
            return ApiResponse::error('Withdrawal failed', ['error' => $e->getMessage()], 500);
        }
    }
}
