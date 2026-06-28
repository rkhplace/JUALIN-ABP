<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateProfileRequest;
use App\Http\Responses\ApiResponse;
use App\Services\SellerVerificationService;
use App\Services\UserService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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

    public function becomeSeller(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'admin') {
            return ApiResponse::error('Admin accounts cannot register as sellers.', null, 422);
        }

        if ($user->role === 'seller') {
            return ApiResponse::success('Akun Anda sudah terdaftar sebagai penjual.', $user->fresh());
        }

        $user->forceFill([
            'role' => 'seller',
            'is_verified' => false,
            'total_sales' => $user->total_sales ?? 0,
        ])->save();

        $this->verificationService->updateSellerVerification($user->id);

        return ApiResponse::success(
            'Akun berhasil didaftarkan sebagai penjual.',
            $user->fresh()
        );
    }

    public function requestDeletion(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'admin') {
            return ApiResponse::error('Admin accounts cannot be deleted from profile', null, 422);
        }

        $validated = $request->validate([
            'password' => 'required|string',
            'confirmation_phrase' => 'required|string|in:HAPUS AKUN',
        ]);

        if (!Hash::check($validated['password'], $user->password)) {
            return ApiResponse::error('Password akun Jualin tidak sesuai.', null, 422);
        }

        $scheduledAt = now()->addDays(14);
        $user->forceFill([
            'deletion_requested_at' => now(),
            'scheduled_deletion_at' => $scheduledAt,
            'refresh_token' => null,
        ])->save();

        auth()->guard('api')->logout();

        return ApiResponse::success('Penghapusan akun dijadwalkan.', [
            'scheduled_deletion_at' => $scheduledAt->toIso8601String(),
            'recovery_days' => 14,
        ]);
    }

    public function cancelDeletion(Request $request)
    {
        $user = $request->user();

        if (!$user->scheduled_deletion_at) {
            return ApiResponse::error('Akun ini tidak sedang dijadwalkan untuk dihapus.', null, 422);
        }

        $user->forceFill([
            'deletion_requested_at' => null,
            'scheduled_deletion_at' => null,
        ])->save();

        return ApiResponse::success('Penghapusan akun berhasil dibatalkan.', $user->fresh());
    }
}
