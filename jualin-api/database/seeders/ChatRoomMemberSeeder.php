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
            // Room 1 - Private (customer_neo & seller_alpha)
            [
                'chat_room_id' => 1,
                'user_id' => 2, // seller_alpha
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(7),
            ],
            [
                'chat_room_id' => 1,
                'user_id' => 4, // customer_neo
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(7),
            ],

            // Room 2 - Private (customer_luna & seller_bravo)
            [
                'chat_room_id' => 2,
                'user_id' => 3, // seller_bravo
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],
            [
                'chat_room_id' => 2,
                'user_id' => 5, // customer_luna
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],

            // Room 3 - Private (customer_neo & seller_bravo)
            [
                'chat_room_id' => 3,
                'user_id' => 3, // seller_bravo
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],
            [
                'chat_room_id' => 3,
                'user_id' => 4, // customer_neo
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],

            // Room 4 - Group (admin + 2 seller)
            [
                'chat_room_id' => 4,
                'user_id' => 1, // admin_master
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'chat_room_id' => 4,
                'user_id' => 2, // seller_alpha
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'chat_room_id' => 4,
                'user_id' => 3, // seller_bravo
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
                'user_id' => 4, // customer_neo
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'chat_room_id' => 5,
                'user_id' => 5, // customer_luna
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
