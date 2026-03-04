<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ForumThreadSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('forum_threads')->insert([
            [
                'product_id' => 1,
                'created_by_id' => 4, // customer_neo
                'title' => 'Apakah headphone ini support Bluetooth 5.0?',
                'body' => 'Saya ingin tahu apakah produk ini kompatibel dengan iPhone terbaru.',
                'created_at' => now()->subDays(6),
                'updated_at' => now()->subDays(6),
            ],
            [
                'product_id' => 2,
                'created_by_id' => 5, // customer_luna
                'title' => 'Baterai smartwatch ini tahan berapa lama?',
                'body' => 'Saya tertarik membeli tapi ingin tahu estimasi daya tahannya.',
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],
            [
                'product_id' => 3,
                'created_by_id' => 2, // seller_alpha
                'title' => 'Rekomendasi tas kulit terbaik',
                'body' => 'Thread ini untuk berbagi pengalaman penggunaan tas kulit premium.',
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],
            [
                'product_id' => 4,
                'created_by_id' => 3, // seller_bravo
                'title' => 'Tips merawat jaket denim agar tahan lama',
                'body' => 'Saya ingin berbagi tips dan trik agar bahan denim tidak cepat pudar.',
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'product_id' => 5,
                'created_by_id' => 4, // customer_neo
                'title' => 'Apakah jam tangan ini waterproof?',
                'body' => 'Ada yang sudah coba pakai jam ini saat berenang?',
                'created_at' => now()->subDay(),
                'updated_at' => now()->subDay(),
            ],
        ]);
    }
}
