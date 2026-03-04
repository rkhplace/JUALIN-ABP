<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Http\Responses\ApiResponse;
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
