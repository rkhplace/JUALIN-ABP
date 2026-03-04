<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TransactionItemSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('transaction_items')->insert([
            [
                'transaction_id' => 1,
                'product_id' => 1,
                'quantity' => 1,
                'price_at_purchase' => 599000,
                'subtotal' => 599000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 1,
                'product_id' => 2,
                'quantity' => 1,
                'price_at_purchase' => 1299000,
                'subtotal' => 1299000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 2,
                'product_id' => 3,
                'quantity' => 1,
                'price_at_purchase' => 850000,
                'subtotal' => 850000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 2,
                'product_id' => 5,
                'quantity' => 2,
                'price_at_purchase' => 300000,
                'subtotal' => 600000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'transaction_id' => 3,
                'product_id' => 4,
                'quantity' => 1,
                'price_at_purchase' => 450000,
                'subtotal' => 450000,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
