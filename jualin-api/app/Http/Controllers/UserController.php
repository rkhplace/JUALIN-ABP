<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Http\Responses\ApiResponse;
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
        $this->service->delete($id);
        return ApiResponse::success('User deleted');
    }
}
