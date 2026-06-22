<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\Facades\Notification;
use Tymon\JWTAuth\Facades\JWTAuth;
use App\Models\User;
use App\Notifications\LoginLockedNotification;

class AuthControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function testRegisterReturnsTokens()
    {
        JWTAuth::shouldReceive('fromUser')->once()->andReturn('access-token-xyz');

        $res = $this->json('POST', '/api/v1/register', [
            'username' => 'newuser',
            'email' => 'new@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'customer',
        ]);

        $res->assertStatus(201)
            ->assertJsonStructure(['message', 'user', 'access_token', 'refresh_token', 'role']);
    }

    public function testRegisterNormalizesEmailBeforeSaving()
    {
        JWTAuth::shouldReceive('fromUser')->once()->andReturn('access-token-xyz');

        $res = $this->json('POST', '/api/v1/register', [
            'username' => 'normaluser',
            'email' => '  NewUser@Example.COM  ',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'customer',
        ]);

        $res->assertStatus(201);
        $this->assertDatabaseHas('users', ['email' => 'newuser@example.com']);
    }

    public function testRegisteredUserCanRequestPasswordResetLink()
    {
        Notification::fake();

        $user = User::create([
            'username' => 'resetuser',
            'email' => 'ResetUser@Example.com',
            'password' => 'password123',
            'role' => 'customer',
        ]);

        $res = $this->json('POST', '/api/v1/password/email', [
            'email' => 'resetuser@example.com',
        ]);

        $res->assertOk()
            ->assertJson(['message' => 'Jika email terdaftar, link reset password akan dikirim.']);

        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'ResetUser@Example.com',
        ]);

        Notification::assertSentTo($user, ResetPassword::class);
    }

    public function testForgotPasswordResponseDoesNotRevealUnknownEmail()
    {
        Notification::fake();

        $res = $this->json('POST', '/api/v1/password/email', [
            'email' => 'unknown@example.com',
        ]);

        $res->assertOk()
            ->assertJson(['message' => 'Jika email terdaftar, link reset password akan dikirim.']);

        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'unknown@example.com',
        ]);

        Notification::assertNothingSent();
    }

    public function testLoginInvalidCredentialsReturns401()
    {
        $res = $this->json('POST', '/api/v1/login', [
            'email' => 'nope@example.com',
            'password' => 'password123',
            'remember' => true,
        ]);

        $res->assertStatus(401)->assertJson(['message' => 'Email atau kata sandi tidak sesuai.']);
    }

    public function testAccountIsTemporarilyLocked_after_three_wrong_passwords()
    {
        Notification::fake();
        $user = User::create([
            'username' => 'locked-user',
            'email' => 'locked@example.com',
            'password' => 'correct-password',
            'role' => 'customer',
        ]);

        for ($attempt = 1; $attempt <= 2; $attempt++) {
            $this->postJson('/api/v1/login', [
                'email' => $user->email,
                'password' => 'wrong-password',
            ])->assertUnauthorized()
                ->assertJsonPath('errors.remaining_attempts', 3 - $attempt);
        }

        $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'wrong-password',
        ])->assertStatus(429)
            ->assertJsonPath('errors.reason', 'login_locked')
            ->assertJsonPath('errors.remaining_attempts', 0)
            ->assertJsonPath('errors.reset_email_sent', true)
            ->assertJsonStructure(['errors' => ['retry_after', 'locked_until']]);

        $this->assertNotNull($user->fresh()->login_locked_until);
        Notification::assertSentTo($user, LoginLockedNotification::class);
    }

    public function test_correct_password_cannot_bypass_an_active_login_lock()
    {
        $user = User::create([
            'username' => 'already-locked-user',
            'email' => 'already-locked@example.com',
            'password' => 'correct-password',
            'role' => 'customer',
            'failed_login_attempts' => 3,
            'login_locked_until' => now()->addMinutes(15),
        ]);

        $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'correct-password',
        ])->assertStatus(429)->assertJsonPath('errors.reason', 'login_locked');
    }

    public function test_short_wrong_passwords_are_counted_and_lock_the_account(): void
    {
        Notification::fake();
        $user = User::create([
            'username' => 'short-password-attempts',
            'email' => 'short-attempts@example.com',
            'password' => 'correct-password',
            'role' => 'customer',
        ]);

        foreach ([2, 1] as $remainingAttempts) {
            $this->postJson('/api/v1/login', [
                'email' => $user->email,
                'password' => 'x',
            ])->assertUnauthorized()
                ->assertJsonPath('errors.remaining_attempts', $remainingAttempts);
        }

        $this->postJson('/api/v1/login', [
            'email' => $user->email,
            'password' => 'x',
        ])->assertStatus(429)
            ->assertJsonPath('errors.reason', 'login_locked');

        $this->assertNotNull($user->fresh()->login_locked_until);
    }

    public function testMeReturnsAuthenticatedUser()
    {
        $user = User::create([
            'username' => 'meuser',
            'email' => 'me@example.com',
            'password' => 'pw',
            'role' => 'customer',
        ]);

        $this->actingAs($user, 'api');
        $res = $this->json('GET', '/api/v1/me');

        $res->assertStatus(200)->assertJsonFragment([
            'username' => 'meuser',
            'email' => 'me@example.com',
        ]);
    }

    public function testRefreshTokenSuccess()
    {
        $user = User::create([
            'username' => 'rtuser',
            'email' => 'rt@example.com',
            'password' => 'pw',
            'role' => 'customer',
            'refresh_token' => 'old-refresh',
        ]);

        JWTAuth::shouldReceive('fromUser')->once()->andReturn('new-access-token');

        $res = $this->json('POST', '/api/v1/refresh-token', [
            'refresh_token' => 'old-refresh',
        ]);

        $res->assertStatus(200)
            ->assertJsonStructure(['message', 'data' => ['access_token', 'refresh_token']]);
    }
}
