<?php

namespace App\Repositories;

use App\Models\User;
use Illuminate\Pagination\LengthAwarePaginator;

class UserRepository
{
    public function create(array $data)
    {
        return User::create([
            'username' => $data['username'],
            'email' => $data['email'],
            'profile_picture' => $data['profile_picture'] ?? null,
            'password' => bcrypt($data['password']),
            'role' => $data['role'] ?? 'customer',
            'bio' => $data['bio'] ?? null,
            'gender' => $data['gender'] ?? null,
            'birthday' => $data['birthday'] ?? null,
            'region' => $data['region'] ?? null,
            'city' => $data['city'] ?? null,
        ]);
    }

    public function findByEmail(string $email)
    {
        return User::where('email', $email)->first();
    }

    public function findByUsername(string $username)
    {
        return User::where('username', $username)->first();
    }

    public function getAll(array $filters = []): LengthAwarePaginator
    {
        $q = User::query();

        $perPage = isset($filters['per_page']) && (int) $filters['per_page'] > 0
            ? (int) $filters['per_page']
            : 10;

        return $q->orderByDesc('created_at')->paginate($perPage);
    }

    public function all()
    {
        return User::all();
    }

    public function find($id)
    {
        return User::find($id);
    }

    public function update($id, array $data)
    {
        $user = User::find($id);
        $user->update($data);
        return $user;
    }

    public function delete($id)
    {
        return User::destroy($id);
    }
}
