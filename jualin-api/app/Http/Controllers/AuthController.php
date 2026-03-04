<?php

namespace App\Http\Controllers;

use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Responses\ApiResponse;
use App\Models\User;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Tymon\JWTAuth\Facades\JWTAuth;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Hash;
use Illuminate\Auth\Events\PasswordReset;
use Kreait\Firebase\Factory;

class AuthController extends Controller
{
    protected $authService;

    public function __construct(AuthService $authService)
    {
        $this->authService = $authService;
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->authService->register($request->validated());
        return response()->json([
            'message' => 'User registered successfully',
            'user' => $result['user'],
            'access_token' => $result['access_token'],
            'refresh_token' => $result['refresh_token'],
            'role' => $result['user']->role,
            'firebase_token' => $this->generateFirebaseToken($result['user']->id),
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login($request->validated());

        if (!$result['success']) {
            return ApiResponse::error('Invalid credentials', null, 401);
        }

        // Generate Firebase Custom Token
        // Generate Firebase Custom Token
        $firebaseToken = $this->generateFirebaseToken($result['user']->id);

        return ApiResponse::success('Login success', [
            'username' => $result['user']->username,
            'email' => $result['user']->email,
            'access_token' => $result['access_token'],
            'refresh_token' => $result['refresh_token'],
            'role' => $result['user']->role,
            'firebase_token' => $firebaseToken, // <--- Sent to frontend
        ]);
    }

    public function logout(): JsonResponse
    {
        $this->authService->logout();
        return response()->json(['message' => 'Successfully logged out']);
    }

    public function refreshToken(Request $request): JsonResponse
    {
        $refreshToken = $request->input('refresh_token');

        $user = User::where('refresh_token', $refreshToken)->first();

        if (!$user) {
            return ApiResponse::error('Invalid refresh token', null, 401);
        }

        $newAccessToken = JWTAuth::fromUser($user);
        $newRefreshToken = Str::random(60);

        $user->update(['refresh_token' => $newRefreshToken]);

        return ApiResponse::success('Token refreshed', [
            'access_token' => $newAccessToken,
            'refresh_token' => $newRefreshToken
        ]);
    }


    public function me(): JsonResponse
    {
        $user = auth()->guard('api')->user();
        if ($user) {
            $user->firebase_token = $this->generateFirebaseToken($user->id);
        }
        return response()->json($user);
    }

    public function sendResetLinkEmail(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $status = Password::sendResetLink(
            $request->only('email')
        );

        return $status === Password::RESET_LINK_SENT
            ? response()->json(['message' => __($status)])
            : response()->json(['message' => __($status)], 400);
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|min:6|confirmed',
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->forceFill([
                    'password' => Hash::make($password)
                ])->save();

                event(new PasswordReset($user));
            }
        );

        return $status === Password::PASSWORD_RESET
            ? response()->json(['message' => __($status)])
            : response()->json(['message' => __($status)], 400);
    }

    private function generateFirebaseToken($userId)
    {
        try {
            $serviceAccountPath = storage_path('app/firebase-credentials.json');

            if (!file_exists($serviceAccountPath)) {
                \Illuminate\Support\Facades\Log::warning("Firebase credentials not found at: " . $serviceAccountPath);
                return null;
            }

            $factory = (new \Kreait\Firebase\Factory)->withServiceAccount($serviceAccountPath);
            $auth = $factory->createAuth();
            return $auth->createCustomToken((string) $userId)->toString();
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error("Firebase Token Generation Error: " . $e->getMessage());
            return null;
        }
    }
}