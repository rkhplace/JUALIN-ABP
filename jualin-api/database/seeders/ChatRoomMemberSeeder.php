<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ChatRoomMemberSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
         DB::table('chat_room_member')->insert([
            // Room 1 - Private (customer_rakha & seller_celsyka)
            [
                'chat_room_id' => 1,
                'user_id' => 2, // seller_celsyka
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(7),
            ],
            [
                'chat_room_id' => 1,
                'user_id' => 5, // customer_rakha
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(7),
            ],

            // Room 2 - Private (customer_galih & seller_latifah)
            [
                'chat_room_id' => 2,
                'user_id' => 3, // seller_latifah
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],
            [
                'chat_room_id' => 2,
                'user_id' => 6, // customer_galih
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],

            // Room 3 - Private (customer_rizki & seller_aryo)
            [
                'chat_room_id' => 3,
                'user_id' => 4, // seller_aryo
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],
            [
                'chat_room_id' => 3,
                'user_id' => 7, // customer_rizki
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],

            // Room 4 - Group (admin + semua seller)
            [
                'chat_room_id' => 4,
                'user_id' => 1, // admin_master
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'chat_room_id' => 4,
                'user_id' => 2, // seller_celsyka
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'chat_room_id' => 4,
                'user_id' => 3, // seller_latifah
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'chat_room_id' => 4,
                'user_id' => 4, // seller_aryo
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],

            // Room 5 - Group (admin + semua customer)
            [
                'chat_room_id' => 5,
                'user_id' => 1, // admin_master
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'chat_room_id' => 5,
                'user_id' => 5, // customer_rakha
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'chat_room_id' => 5,
                'user_id' => 6, // customer_galih
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'chat_room_id' => 5,
                'user_id' => 7, // customer_rizki
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
