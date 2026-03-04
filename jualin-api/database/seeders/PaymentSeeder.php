<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;


class PaymentSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('payments')->insert([
            [
                'transaction_id' => 1,
                'order_id' => 'ORD-' . strtoupper(Str::random(8)),
                'midtrans_transaction_id' => 'MID-' . strtoupper(Str::random(10)),
                'payment_type' => 'bank_transfer',
                'gross_amount' => 1898000,
                'bank_or_channel' => 'bca',
                'transaction_status' => 'settlement',
                'transaction_time' => now()->subDays(5),
                'created_at' => now()->subDays(5),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 2,
                'order_id' => 'ORD-' . strtoupper(Str::random(8)),
                'midtrans_transaction_id' => 'MID-' . strtoupper(Str::random(10)),
                'payment_type' => 'qris',
                'gross_amount' => 1150000,
                'bank_or_channel' => 'qris',
                'transaction_status' => 'settlement',
                'transaction_time' => now()->subDays(3),
                'created_at' => now()->subDays(3),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 3,
                'order_id' => 'ORD-' . strtoupper(Str::random(8)),
                'midtrans_transaction_id' => 'MID-' . strtoupper(Str::random(10)),
                'payment_type' => 'bank_transfer',
                'gross_amount' => 450000,
                'bank_or_channel' => 'bri',
                'transaction_status' => 'pending',
                'transaction_time' => now()->subDays(1),
                'created_at' => now()->subDays(1),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 2,
                'order_id' => 'ORD-' . strtoupper(Str::random(8)),
                'midtrans_transaction_id' => 'MID-' . strtoupper(Str::random(10)),
                'payment_type' => 'gopay',
                'gross_amount' => 1150000,
                'bank_or_channel' => 'gopay',
                'transaction_status' => 'expire',
                'transaction_time' => now()->subDays(7),
                'created_at' => now()->subDays(7),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 1,
                'order_id' => 'ORD-' . strtoupper(Str::random(8)),
                'midtrans_transaction_id' => 'MID-' . strtoupper(Str::random(10)),
                'payment_type' => 'credit_card',
                'gross_amount' => 1898000,
                'bank_or_channel' => 'visa',
                'transaction_status' => 'cancel',
                'transaction_time' => now()->subDays(10),
                'created_at' => now()->subDays(10),
                'updated_at' => now(),
            ],
        ]);
    }
}
