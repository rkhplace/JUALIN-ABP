<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\Facades\Notification;
use Tymon\JWTAuth\Facades\JWTAuth;
use App\Models\User;

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
        ]);

        $res->assertStatus(401)->assertJson(['message' => 'Invalid credentials']);
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
