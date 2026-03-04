<?php

namespace Tests\Unit;

use Tests\TestCase;
use Mockery;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Services\AuthService;
use App\Repositories\UserRepository;
use App\Models\User;
use Tymon\JWTAuth\Facades\JWTAuth;
use Illuminate\Support\Facades\Auth;

class AuthServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function testRegisterCreatesUserAndReturnsTokens()
    {
        $repo = new UserRepository();
        JWTAuth::shouldReceive('fromUser')->once()->andReturn('access-token-123');

        $service = new AuthService($repo);
        $result = $service->register([
            'username' => 'u1',
            'email' => 'u1@example.com',
            'password' => 'secret123',
            'role' => 'customer',
        ]);

        $this->assertInstanceOf(User::class, $result['user']);
        $this->assertSame('access-token-123', $result['access_token']);
        $this->assertNotEmpty($result['refresh_token']);
        $this->assertNotNull($result['user']->refresh_token);
    }

    public function testLoginInvalidCredentialsReturnsError()
    {
        $service = new AuthService(new UserRepository());
        $guard = Mockery::mock();
        $guard->shouldReceive('attempt')->once()->andReturn(false);
        Auth::shouldReceive('guard')->with('api')->andReturn($guard);

        $result = $service->login(['email' => 'x@example.com', 'password' => 'badpassword']);
        $this->assertFalse($result['success']);
    }

    public function testLoginSuccessReturnsTokensAndSetsRefresh()
    {
        $user = User::create([
            'username' => 'u2',
            'email' => 'u2@example.com',
            'password' => 'secretpassword',
            'role' => 'customer',
        ]);

        $guard = Mockery::mock();
        $guard->shouldReceive('attempt')->once()->andReturn('jwt-access-token');
        $guard->shouldReceive('user')->andReturn($user);
        Auth::shouldReceive('guard')->with('api')->andReturn($guard);

        $service = new AuthService(new UserRepository());
        $result = $service->login(['email' => $user->email, 'password' => 'secretpassword']);

        $this->assertTrue($result['success']);
        $this->assertSame('jwt-access-token', $result['access_token']);
        $this->assertNotEmpty($result['refresh_token']);
        $this->assertNotNull($user->fresh()->refresh_token);
    }

    public function testLogoutClearsRefreshTokenAndLogsOut()
    {
        $user = User::create([
            'username' => 'u3',
            'email' => 'u3@example.com',
            'password' => 'secret',
            'role' => 'customer',
            'refresh_token' => 'rt1',
        ]);

        $guard = Mockery::mock();
        $guard->shouldReceive('user')->andReturn($user);
        $guard->shouldReceive('logout')->once();
        Auth::shouldReceive('guard')->with('api')->andReturn($guard);

        $service = new AuthService(new UserRepository());
        $ok = $service->logout();

        $this->assertTrue($ok);
        $this->assertNull($user->fresh()->refresh_token);
    }
}