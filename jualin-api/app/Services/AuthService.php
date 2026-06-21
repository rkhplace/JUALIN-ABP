<?php

namespace App\Services;

use App\Repositories\UserRepository;
use Tymon\JWTAuth\Facades\JWTAuth;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    protected $userRepository;

    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }

    public function register(array $data)
    {
        if (isset($data['profile_picture']) && $data['profile_picture'] instanceof \Illuminate\Http\UploadedFile) {
            $data['profile_picture'] = $data['profile_picture']->store('profile_pictures', 'public');
        }

        $user = $this->userRepository->create($data);
        $accessToken = JWTAuth::fromUser($user);
        $refreshToken = Str::random(60);

        $user->update(['refresh_token' => $refreshToken]);

        return [
            'user' => $user,
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken
        ];
    }

    public function login(array $credentials)
    {
        $loginCredentials = Arr::only($credentials, ['email', 'password']);
        $email = Str::lower(trim((string) ($loginCredentials['email'] ?? '')));
        $user = $this->userRepository->findByEmail($email);

        if (!$user) {
            return [
                'success' => false,
                'message' => 'Email atau kata sandi tidak sesuai.',
                'status' => 401,
            ];
        }

        if ($user->login_locked_until && Carbon::now()->lt($user->login_locked_until)) {
            return $this->lockedResult($user);
        }

        if ($user->login_locked_until) {
            $user->forceFill([
                'failed_login_attempts' => 0,
                'login_locked_until' => null,
            ])->save();
        }

        if (!Hash::check((string) ($loginCredentials['password'] ?? ''), $user->password)) {
            return DB::transaction(function () use ($user) {
                $lockedUser = $user->newQuery()->lockForUpdate()->findOrFail($user->id);

                if ($lockedUser->login_locked_until && Carbon::now()->lt($lockedUser->login_locked_until)) {
                    return $this->lockedResult($lockedUser);
                }

                $attempts = min(3, $lockedUser->failed_login_attempts + 1);
                $lockedUntil = $attempts >= 3 ? Carbon::now()->addMinutes(15) : null;
                $lockedUser->forceFill([
                    'failed_login_attempts' => $attempts,
                    'login_locked_until' => $lockedUntil,
                ])->save();

                if ($lockedUntil) {
                    return array_merge($this->lockedResult($lockedUser), ['send_lock_email' => true]);
                }

                return [
                    'success' => false,
                    'message' => 'Email atau kata sandi tidak sesuai. Tersisa ' . (3 - $attempts) . ' percobaan.',
                    'status' => 401,
                    'reason' => 'invalid_credentials',
                    'remaining_attempts' => 3 - $attempts,
                ];
            });
        }

        $loginCredentials['email'] = $email;
        $token = Auth::guard('api')->attempt($loginCredentials);

        if (!$token) {
            return [
                'success' => false,
                'message' => 'Email atau kata sandi tidak sesuai.',
                'status' => 401,
            ];
        }

        $user = Auth::guard('api')->user();

        $user->forceFill([
            'failed_login_attempts' => 0,
            'login_locked_until' => null,
        ])->save();

        if ($user->is_banned && $user->banned_until && Carbon::now()->lt($user->banned_until)) {
            Auth::guard('api')->logout();

            return [
                'success' => false,
                'message' => 'Your account has been suspended until ' . $user->banned_until->format('Y-m-d H:i:s'),
                'status' => 403,
            ];
        }

        if ($user->is_banned && (!$user->banned_until || Carbon::now()->gte($user->banned_until))) {
            $user->update([
                'is_banned' => false,
                'banned_until' => null,
            ]);
        }

        // Generate refresh token
        $refreshToken = Str::random(60);

        // Save refresh token to user
        $user->update(['refresh_token' => $refreshToken]);

        return [
            'success' => true,
            'user' => $user,
            'access_token' => $token,
            'refresh_token' => $refreshToken,
        ];
    }

    private function lockedResult($user): array
    {
        $retryAfter = max(1, Carbon::now()->diffInSeconds($user->login_locked_until, false));

        return [
            'success' => false,
            'message' => 'Terlalu banyak percobaan login. Coba lagi setelah waktu tunggu berakhir atau reset kata sandi Anda.',
            'status' => 429,
            'reason' => 'login_locked',
            'remaining_attempts' => 0,
            'retry_after' => $retryAfter,
            'locked_until' => $user->login_locked_until->toIso8601String(),
            'user' => $user,
        ];
    }


    public function logout()
    {
        $user = Auth::guard('api')->user();

        if ($user) {
            // Hapus refresh token
            $user->update(['refresh_token' => null]);
        }

        // Invalidate access token
        Auth::guard('api')->logout();

        return true;
    }
}
