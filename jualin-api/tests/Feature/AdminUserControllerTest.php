<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminUserControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function test_admin_can_delete_customer_account(): void
    {
        $admin = $this->createUser('admin', 'admin-delete@example.com', 'admin');
        $customer = $this->createUser('customer-delete', 'customer-delete@example.com', 'customer');

        $this->actingAs($admin, 'api')
            ->deleteJson("/api/v1/users/{$customer->id}")
            ->assertOk()
            ->assertJsonPath('message', 'User deleted');

        $this->assertDatabaseMissing('users', ['id' => $customer->id]);
    }

    public function test_admin_cannot_delete_another_admin_account(): void
    {
        $admin = $this->createUser('admin', 'admin@example.com', 'admin');
        $otherAdmin = $this->createUser('other-admin', 'other-admin@example.com', 'admin');

        $this->actingAs($admin, 'api')
            ->deleteJson("/api/v1/users/{$otherAdmin->id}")
            ->assertStatus(422);

        $this->assertDatabaseHas('users', ['id' => $otherAdmin->id]);
    }

    public function test_deleting_unknown_user_returns_not_found(): void
    {
        $admin = $this->createUser('admin', 'admin-not-found@example.com', 'admin');

        $this->actingAs($admin, 'api')
            ->deleteJson('/api/v1/users/999999')
            ->assertNotFound();
    }

    private function createUser(string $username, string $email, string $role): User
    {
        return User::create([
            'username' => $username,
            'email' => $email,
            'password' => 'password',
            'role' => $role,
        ]);
    }
}
