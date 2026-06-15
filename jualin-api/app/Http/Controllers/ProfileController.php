<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateProfileRequest;
use App\Http\Responses\ApiResponse;
use App\Services\SellerVerificationService;
use App\Services\UserService;

class ProfileController extends Controller
{
    public function __construct(
        private readonly UserService $userService,
        private readonly SellerVerificationService $verificationService,
    )
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

        if ($updatedUser->role === 'seller') {
            $this->verificationService->updateSellerVerification($updatedUser->id);
            $updatedUser->refresh();
        }

        return ApiResponse::success(
            'Profile updated',
            $updatedUser->fresh()
        );
    }

    public function destroy(\Illuminate\Http\Request $request)
    {
        $user = $request->user();

        if ($user->role === 'admin') {
            return ApiResponse::error('Admin accounts cannot be deleted from profile', null, 422);
        }

        $this->userService->delete($user->id);

        return ApiResponse::success('Account deleted');
    }
}
