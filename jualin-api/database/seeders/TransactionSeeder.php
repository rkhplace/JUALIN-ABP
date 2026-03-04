<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TransactionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Transaksi 1 - customer_neo beli dari seller_alpha
        $transaction1Id = DB::table('transactions')->insertGetId([
            'customer_id' => 4, // customer_neo
            'seller_id' => 2,   // seller_alpha
            'total_amount' => 599000 + 1299000, // dua produk
            'status' => 'completed',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('transaction_items')->insert([
            [
                'transaction_id' => $transaction1Id,
                'product_id' => 1, // Wireless Headphones
                'quantity' => 1,
                'price_at_purchase' => 599000,
                'subtotal' => 599000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => $transaction1Id,
                'product_id' => 2, // Smart Watch
                'quantity' => 1,
                'price_at_purchase' => 1299000,
                'subtotal' => 1299000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // Transaksi 2 - customer_luna beli dari seller_bravo
        $transaction2Id = DB::table('transactions')->insertGetId([
            'customer_id' => 5, // customer_luna
            'seller_id' => 3,   // seller_bravo
            'total_amount' => 850000 + 300000,
            'status' => 'paid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('transaction_items')->insert([
            [
                'transaction_id' => $transaction2Id,
                'product_id' => 3, // Leather Handbag
                'quantity' => 1,
                'price_at_purchase' => 850000,
                'subtotal' => 850000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => $transaction2Id,
                'product_id' => 5, // Minimalist Watch
                'quantity' => 1,
                'price_at_purchase' => 300000,
                'subtotal' => 300000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // Transaksi 3 - customer_neo beli lagi dari seller_bravo
        $transaction3Id = DB::table('transactions')->insertGetId([
            'customer_id' => 4,
            'seller_id' => 3,
            'total_amount' => 450000,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('transaction_items')->insert([
            [
                'transaction_id' => $transaction3Id,
                'product_id' => 4, // Denim Jacket
                'quantity' => 1,
                'price_at_purchase' => 450000,
                'subtotal' => 450000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
