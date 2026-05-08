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
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Auth\Events\PasswordReset;
use Kreait\Firebase\Factory;

class AuthController extends Controller
{
    private const RESET_LINK_SENT_RESPONSE = 'Jika email terdaftar, link reset password akan dikirim.';
    private const RESET_PASSWORD_FAILED_RESPONSE = 'Token reset password tidak valid atau sudah kedaluwarsa.';

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
            'id' => $result['user']->id,
            'username' => $result['user']->username,
            'email' => $result['user']->email,
            'access_token' => $result['access_token'],
            'refresh_token' => $result['refresh_token'],
            'role' => $result['user']->role,
            'wallet_balance' => $result['user']->wallet_balance,
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
        $request->merge([
            'email' => $this->normalizeEmail($request->input('email')),
        ]);

        $request->validate(['email' => 'required|email']);

        $email = $request->input('email');
        $brokerName = config('auth.defaults.passwords', 'users');
        $user = $this->findUserByEmail($email);

        Log::info('Password reset link requested', [
            'email' => $email,
            'user_found' => (bool) $user,
            'password_broker' => $brokerName,
            'password_provider' => config("auth.passwords.$brokerName.provider"),
            'password_token_table' => $this->passwordTokenTable($brokerName),
            'mail_mailer' => config('mail.default'),
            'queue_connection' => config('queue.default'),
        ]);

        if (!$user) {
            return response()->json([
                'message' => self::RESET_LINK_SENT_RESPONSE,
            ]);
        }

        try {
            $status = Password::broker($brokerName)->sendResetLink([
                'email' => $user->email,
            ]);

            Log::info('Password reset link handled', [
                'email' => $email,
                'user_id' => $user->id,
                'status' => $status,
                'token_created' => $this->passwordResetTokenExists($brokerName, $user->email),
                'mail_sent' => $status === Password::RESET_LINK_SENT,
            ]);
        } catch (\Throwable $e) {
            Log::error('Password reset email failed', [
                'email' => $email,
                'user_id' => $user->id,
                'password_broker' => $brokerName,
                'password_token_table' => $this->passwordTokenTable($brokerName),
                'token_created' => $this->passwordResetTokenExists($brokerName, $user->email),
                'mail_mailer' => config('mail.default'),
                'mail_host' => config('mail.mailers.smtp.host'),
                'mail_port' => config('mail.mailers.smtp.port'),
                'exception' => $e->getMessage(),
            ]);

            return response()->json([
                'message' => 'Gagal mengirim email reset password. Silakan coba lagi beberapa saat.',
            ], 503);
        }

        return response()->json([
            'message' => self::RESET_LINK_SENT_RESPONSE,
        ]);
    }

    public function resetPassword(Request $request)
    {
        $request->merge([
            'email' => $this->normalizeEmail($request->input('email')),
        ]);

        $validated = $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|min:6|confirmed',
        ]);

        $brokerName = config('auth.defaults.passwords', 'users');
        $user = $this->findUserByEmail($validated['email']);

        if (!$user) {
            Log::warning('Password reset attempted for unknown email', [
                'email' => $validated['email'],
                'password_broker' => $brokerName,
            ]);

            return response()->json(['message' => self::RESET_PASSWORD_FAILED_RESPONSE], 400);
        }

        $validated['email'] = $user->email;

        $status = Password::broker($brokerName)->reset(
            $validated,
            function ($user, $password) {
                $user->forceFill([
                    'password' => Hash::make($password)
                ])->save();

                event(new PasswordReset($user));
            }
        );

        Log::info('Password reset completed', [
            'email' => $request->input('email'),
            'user_id' => $user->id,
            'status' => $status,
        ]);

        return $status === Password::PASSWORD_RESET
            ? response()->json(['message' => __($status)])
            : response()->json(['message' => self::RESET_PASSWORD_FAILED_RESPONSE], 400);
    }

    private function normalizeEmail(?string $email): string
    {
        return Str::lower(trim((string) $email));
    }

    private function findUserByEmail(string $email): ?User
    {
        return User::query()
            ->whereRaw('LOWER(email) = ?', [$this->normalizeEmail($email)])
            ->first();
    }

    private function passwordTokenTable(string $brokerName): string
    {
        return config("auth.passwords.$brokerName.table", 'password_reset_tokens');
    }

    private function passwordResetTokenExists(string $brokerName, string $email): bool
    {
        try {
            return DB::table($this->passwordTokenTable($brokerName))
                ->where('email', $email)
                ->exists();
        } catch (\Throwable $e) {
            Log::warning('Unable to inspect password reset token table', [
                'email' => $this->normalizeEmail($email),
                'password_broker' => $brokerName,
                'password_token_table' => $this->passwordTokenTable($brokerName),
                'exception' => $e->getMessage(),
            ]);

            return false;
        }
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
