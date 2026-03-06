<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$transactions = \App\Models\Transaction::latest()->take(5)->get(['id', 'status', 'auth_code'])->toArray();
$payments = \App\Models\Payment::latest()->take(5)->get(['id', 'transaction_id', 'transaction_status'])->toArray();

echo "--- Recent Transactions ---\n";
print_r($transactions);
echo "\n--- Recent Payments ---\n";
print_r($payments);
