<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('users')->insert([
            [
                'username' => 'admin_master',
                'email' => 'admin@example.com',
                'password' => Hash::make('password123'),
                'role' => 'admin',
                'bio' => 'Super admin of the platform',
                'gender' => 'other',
                'birthday' => '1990-01-01',
                'region' => 'Central',
                'city' => 'Jakarta',
                'followers' => 0,
                'following' => 0,
                'remember_token' => Str::random(10),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'username' => 'seller_adam',
                'email' => 'seller1@example.com',
                'password' => Hash::make('password123'),
                'role' => 'seller',
                'bio' => 'Seller specializing in electronics',
                'gender' => 'male',
                'birthday' => '1995-03-10',
                'region' => 'West',
                'city' => 'Bandung',
                'followers' => 15,
                'following' => 3,
                'remember_token' => Str::random(10),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'username' => 'seller_calwa',
                'email' => 'seller2@example.com',
                'password' => Hash::make('password123'),
                'role' => 'seller',
                'bio' => 'Seller focusing on fashion products',
                'gender' => 'female',
                'birthday' => '1994-07-22',
                'region' => 'East',
                'city' => 'Surabaya',
                'followers' => 20,
                'following' => 5,
                'remember_token' => Str::random(10),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'username' => 'customer_rakha',
                'email' => 'customer1@example.com',
                'password' => Hash::make('password123'),
                'role' => 'customer',
                'bio' => 'Enjoys shopping tech gadgets',
                'gender' => 'male',
                'birthday' => '2000-11-15',
                'region' => 'South',
                'city' => 'Yogyakarta',
                'followers' => 2,
                'following' => 10,
                'remember_token' => Str::random(10),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'username' => 'customer_rizki',
                'email' => 'customer2@example.com',
                'password' => Hash::make('password123'),
                'role' => 'customer',
                'bio' => 'Loves handmade items and art',
                'gender' => 'female',
                'birthday' => '2001-06-30',
                'region' => 'North',
                'city' => 'Medan',
                'followers' => 5,
                'following' => 12,
                'remember_token' => Str::random(10),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
