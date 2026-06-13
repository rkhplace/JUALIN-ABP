<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateProfileRequest;
use App\Http\Responses\ApiResponse;
use App\Services\UserService;

class ProfileController extends Controller
{
    public function __construct(private readonly UserService $userService)
    {
    }

    public function update(UpdateProfileRequest $request)
    {
        $user = $request->user();
        $data = $request->validated();

        if ($request->hasFile('profile_picture')) {
            $data['profile_picture'] = $request->file('profile_picture');
        }

        $updatedUser = $this->userService->update($user->id, $data);

        return ApiResponse::success(
            'Profile updated',
            $updatedUser->fresh()
        );
    }
}
