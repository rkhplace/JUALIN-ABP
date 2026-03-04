<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ChatMessageSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('chat_messages')->insert([
            // Room 1 (customer_neo & seller_alpha)
            [
                'chat_room_id' => 1,
                'sender_id' => 4, // customer_neo
                'message' => 'Halo kak, apakah headphone ini masih tersedia?',
                'sent_at' => now()->subDays(7)->addMinutes(3),
                'is_read' => true,
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(7),
            ],
            [
                'chat_room_id' => 1,
                'sender_id' => 2, // seller_alpha
                'message' => 'Hai! Masih tersedia kak, stok 3 lagi ya.',
                'sent_at' => now()->subDays(7)->addMinutes(5),
                'is_read' => true,
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(7),
            ],

            // Room 2 (customer_luna & seller_bravo)
            [
                'chat_room_id' => 2,
                'sender_id' => 5, // customer_luna
                'message' => 'Kak, bisa kirim foto tambahan untuk tasnya?',
                'sent_at' => now()->subDays(5)->addMinutes(10),
                'is_read' => false,
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],
            [
                'chat_room_id' => 2,
                'sender_id' => 3, // seller_bravo
                'message' => 'Bisa banget, ini saya kirim ya.',
                'sent_at' => now()->subDays(5)->addMinutes(12),
                'is_read' => true,
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],

            // Room 3 (customer_neo & seller_bravo)
            [
                'chat_room_id' => 3,
                'sender_id' => 4,
                'message' => 'Kak, ukuran jaketnya fit to L ya?',
                'sent_at' => now()->subDays(3)->addMinutes(2),
                'is_read' => false,
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],
            [
                'chat_room_id' => 3,
                'sender_id' => 3,
                'message' => 'Betul kak, fit to L tapi agak slim fit ya.',
                'sent_at' => now()->subDays(3)->addMinutes(4),
                'is_read' => true,
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],

            // Room 4 (group: admin + sellers)
            [
                'chat_room_id' => 4,
                'sender_id' => 1, // admin_master
                'message' => 'Halo seller, tolong pastikan stok selalu diperbarui setiap hari.',
                'sent_at' => now()->subDays(2)->addMinutes(1),
                'is_read' => true,
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'chat_room_id' => 4,
                'sender_id' => 2, // seller_alpha
                'message' => 'Siap admin, stok saya sudah saya update barusan.',
                'sent_at' => now()->subDays(2)->addMinutes(5),
                'is_read' => true,
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'chat_room_id' => 4,
                'sender_id' => 3, // seller_bravo
                'message' => 'Noted, saya juga update nanti sore.',
                'sent_at' => now()->subDays(2)->addMinutes(6),
                'is_read' => true,
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],

            // Room 5 (group: admin + customers)
            [
                'chat_room_id' => 5,
                'sender_id' => 1,
                'message' => 'Halo semua pelanggan setia Jualin! Ada promo baru minggu ini 🎉',
                'sent_at' => now()->subHours(6),
                'is_read' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'chat_room_id' => 5,
                'sender_id' => 4,
                'message' => 'Wah, promonya untuk semua produk kak?',
                'sent_at' => now()->subHours(5)->addMinutes(10),
                'is_read' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'chat_room_id' => 5,
                'sender_id' => 1,
                'message' => 'Iya, berlaku untuk semua produk aktif sampai akhir minggu ini ya!',
                'sent_at' => now()->subHours(5),
                'is_read' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
