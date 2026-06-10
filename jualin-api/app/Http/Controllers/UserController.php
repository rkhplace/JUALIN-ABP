<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Http\Responses\ApiResponse;
use App\Models\Notification;
use App\Models\User;
use App\Services\UserService;
use Illuminate\Http\Request;

class UserController extends Controller
{
    protected $service;

    public function __construct(UserService $service)
    {
        $this->service = $service;
    }

    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 10);

        return ApiResponse::success(
            'Users retrieved',
            $this->service->getAll($perPage)
        );
    }

    public function show($id)
    {
        return ApiResponse::success('User fetched', $this->service->getById($id));
    }

    public function search(Request $request)
    {
        $query = trim((string) $request->input('q', ''));
        $limit = min(max((int) $request->input('limit', 8), 1), 10);

        $users = User::query()
            ->select('id', 'username', 'role')
            ->when($query !== '', function ($userQuery) use ($query) {
                $userQuery->where('username', 'like', "%{$query}%");
            })
            ->when($request->user(), function ($userQuery, $currentUser) {
                $userQuery->where('id', '!=', $currentUser->id);
            })
            ->orderBy('username')
            ->limit($limit)
            ->get();

        return ApiResponse::success('Users found', $users);
    }

    public function store(StoreUserRequest $request)
    {
        $data = $request->validated();

        if ($request->hasFile('profile_picture')) {
            $data['profile_picture'] = $request->file('profile_picture');
        }

        return ApiResponse::success('User created', $this->service->create($data), 201);
    }

    public function update(UpdateUserRequest $request, $id)
    {
        $data = $request->validated();

        if ($request->hasFile('profile_picture')) {
            $data['profile_picture'] = $request->file('profile_picture');
        }

        return ApiResponse::success('User updated', $this->service->update($id, $data));
    }

    public function destroy($id)
    {
        $user = User::find($id);

        if (!$user) {
            return ApiResponse::error('User not found', null, 404);
        }

        if ($user->role === 'admin') {
            return ApiResponse::error('Admin accounts cannot be deleted', null, 422);
        }

        $this->service->delete($id);

        return ApiResponse::success('User deleted');
    }

    public function banUser(Request $request, $id)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'duration_days' => 'required|integer|in:1,7,30',
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Validation error', $validator->errors(), 422);
        }

        try {
            $user = User::find($id);

            if (!$user) {
                return ApiResponse::error('User not found', null, 404);
            }

            if (!in_array($user->role, ['customer', 'seller'], true)) {
                return ApiResponse::error('Only customer or seller accounts can be banned', null, 422);
            }

            $banStartsAt = \Illuminate\Support\Carbon::now();
            $banEndsAt = $banStartsAt->copy()->addDays((int) $request->duration_days);

            $user->update([
                'is_banned' => true,
                'banned_until' => $banEndsAt,
            ]);

            Notification::create([
                'user_id' => $user->id,
                'title' => 'Akun dibatasi admin',
                'body' => sprintf(
                    'Akun Anda dibatasi sampai %s. Hubungi admin jika merasa ini keliru.',
                    $banEndsAt->format('d/m/Y H:i')
                ),
                'type' => 'account',
            ]);

            return ApiResponse::success('User banned successfully', [
                'user' => $user->fresh(),
                'ban_started_at' => $banStartsAt->toDateTimeString(),
                'banned_until' => $banEndsAt->toDateTimeString(),
            ]);
        } catch (\Exception $e) {
            return ApiResponse::error('Failed to ban user', $e->getMessage(), 500);
        }
    }

    public function unbanUser($id)
    {
        try {
            $user = User::find($id);

            if (!$user) {
                return ApiResponse::error('User not found', null, 404);
            }

            if (!in_array($user->role, ['customer', 'seller'], true)) {
                return ApiResponse::error('Only customer or seller accounts can be unbanned', null, 422);
            }

            $user->update([
                'is_banned' => false,
                'banned_until' => null,
            ]);

            Notification::create([
                'user_id' => $user->id,
                'title' => 'Pembatasan akun dicabut',
                'body' => 'Akun Anda sudah tidak dibatasi. Anda dapat menggunakan fitur Jualin kembali.',
                'type' => 'account',
            ]);

            return ApiResponse::success('User unbanned successfully', [
                'user' => $user->fresh(),
            ]);
        } catch (\Exception $e) {
            return ApiResponse::error('Failed to unban user', $e->getMessage(), 500);
        }
    }
}
