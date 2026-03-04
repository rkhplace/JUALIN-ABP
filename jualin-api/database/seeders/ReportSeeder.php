<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ReportSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('reports')->insert([
            [
                'reporter_id' => 4, // customer_neo
                'reported_user_id' => 2, // seller_alpha
                'product_id' => 1, // Wireless Headphones
                'description' => 'Produk tidak sesuai dengan deskripsi, kualitas sangat buruk.',
                'status' => 'pending',
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'reporter_id' => 5, // customer_luna
                'reported_user_id' => 3, // seller_bravo
                'product_id' => 3, // Leather Handbag
                'description' => 'Barang yang diterima palsu, berbeda dengan foto.',
                'status' => 'reviewed',
                'created_at' => now()->subDays(4),
                'updated_at' => now()->subDays(1),
            ],
            [
                'reporter_id' => 4,
                'reported_user_id' => 3,
                'product_id' => 4, // Denim Jacket
                'description' => 'Produk ini tampaknya diposting berulang kali dengan nama berbeda.',
                'status' => 'resolved',
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(2),
            ],
            [
                'reporter_id' => 5,
                'reported_user_id' => 2,
                'product_id' => 2, // Smart Watch
                'description' => 'Penjual meminta pembayaran di luar platform.',
                'status' => 'reviewed',
                'created_at' => now()->subDays(3),
                'updated_at' => now(),
            ],
            [
                'reporter_id' => 4,
                'reported_user_id' => 3,
                'product_id' => 5, // Minimalist Watch
                'description' => 'Deskripsi produk berisi kata-kata tidak pantas.',
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}