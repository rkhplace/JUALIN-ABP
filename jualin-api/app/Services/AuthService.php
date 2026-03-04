<?php

namespace App\Services;

use App\Repositories\UserRepository;
use Tymon\JWTAuth\Facades\JWTAuth;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

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
        if (!$token = Auth::guard('api')->attempt($credentials)) {
            return [
                'success' => false,
                'message' => 'Invalid credentials'
            ];
        }

        $user = Auth::guard('api')->user();

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
