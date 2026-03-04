<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ForumCommentSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('forum_comments')->insert([
            // Thread 1: Headphone (customer_neo)
            [
                'thread_id' => 1,
                'commented_by_id' => 2, // seller_alpha
                'comment' => 'Ya kak, produk ini sudah support Bluetooth 5.0 dan bisa digunakan di semua perangkat.',
                'created_at' => now()->subDays(6)->addMinutes(10),
                'updated_at' => now()->subDays(6)->addMinutes(10),
            ],
            [
                'thread_id' => 1,
                'commented_by_id' => 4, // customer_neo
                'comment' => 'Mantap, saya checkout sekarang. Terima kasih infonya!',
                'created_at' => now()->subDays(6)->addMinutes(20),
                'updated_at' => now()->subDays(6)->addMinutes(20),
            ],

            // Thread 2: Smart Watch (customer_luna)
            [
                'thread_id' => 2,
                'commented_by_id' => 3, // seller_bravo
                'comment' => 'Baterainya bisa bertahan 7 hari untuk penggunaan normal.',
                'created_at' => now()->subDays(5)->addMinutes(15),
                'updated_at' => now()->subDays(5)->addMinutes(15),
            ],
            [
                'thread_id' => 2,
                'commented_by_id' => 5, // customer_luna
                'comment' => 'Wah lumayan lama juga, worth it nih!',
                'created_at' => now()->subDays(5)->addMinutes(25),
                'updated_at' => now()->subDays(5)->addMinutes(25),
            ],

            // Thread 3: Tas Kulit (seller_alpha)
            [
                'thread_id' => 3,
                'commented_by_id' => 3, // seller_bravo
                'comment' => 'Setuju banget, tas kulit premium memang awet kalau dirawat dengan benar.',
                'created_at' => now()->subDays(3)->addMinutes(5),
                'updated_at' => now()->subDays(3)->addMinutes(5),
            ],
            [
                'thread_id' => 3,
                'commented_by_id' => 2, // seller_alpha
                'comment' => 'Betul kak, saya sarankan pakai leather conditioner tiap 2 bulan.',
                'created_at' => now()->subDays(3)->addMinutes(8),
                'updated_at' => now()->subDays(3)->addMinutes(8),
            ],

            // Thread 4: Jaket Denim (seller_bravo)
            [
                'thread_id' => 4,
                'commented_by_id' => 4, // customer_neo
                'comment' => 'Saya juga punya jaket denim ini, nyaman banget dipakai!',
                'created_at' => now()->subDays(2)->addMinutes(12),
                'updated_at' => now()->subDays(2)->addMinutes(12),
            ],
            [
                'thread_id' => 4,
                'commented_by_id' => 3, // seller_bravo
                'comment' => 'Terima kasih kak! Jangan lupa cuci dengan air dingin biar warna tahan lama.',
                'created_at' => now()->subDays(2)->addMinutes(20),
                'updated_at' => now()->subDays(2)->addMinutes(20),
            ],

            // Thread 5: Jam Tangan (customer_neo)
            [
                'thread_id' => 5,
                'commented_by_id' => 2, // seller_alpha
                'comment' => 'Jam tangan ini water resistant hingga 30 meter, jadi aman buat hujan ringan.',
                'created_at' => now()->subDay()->addMinutes(15),
                'updated_at' => now()->subDay()->addMinutes(15),
            ],
            [
                'thread_id' => 5,
                'commented_by_id' => 4, // customer_neo
                'comment' => 'Oke kak, noted. Makasih penjelasannya!',
                'created_at' => now()->subDay()->addMinutes(20),
                'updated_at' => now()->subDay()->addMinutes(20),
            ],
        ]);
    }
}
