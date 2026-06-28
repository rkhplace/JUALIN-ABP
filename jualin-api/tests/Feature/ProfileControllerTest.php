<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfileControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function testAuthenticatedUserCanUpdateOwnProfile(): void
    {
        $user = User::create([
            'username' => 'profileuser',
            'email' => 'profile@example.com',
            'password' => 'password123',
            'role' => 'customer',
        ]);

        $this->actingAs($user, 'api');

        $response = $this->patchJson('/api/v1/profile/update', [
            'username' => 'updateduser',
            'email' => 'UPDATED@EXAMPLE.COM',
            'phone' => '081234567890',
            'region' => 'Jawa Barat',
            'city' => 'Bandung',
            'bio' => 'Profil yang sudah diperbarui.',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.username', 'updateduser')
            ->assertJsonPath('data.email', 'updated@example.com')
            ->assertJsonPath('data.phone', '081234567890');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'username' => 'updateduser',
            'email' => 'updated@example.com',
            'phone' => '081234567890',
            'region' => 'Jawa Barat',
            'city' => 'Bandung',
            'bio' => 'Profil yang sudah diperbarui.',
        ]);
    }

    public function testProfileUpdateAllowsKeepingCurrentEmailAndUsername(): void
    {
        $user = User::create([
            'username' => 'sameuser',
            'email' => 'same@example.com',
            'password' => 'password123',
            'role' => 'seller',
        ]);

        $this->actingAs($user, 'api');

        $this->patchJson('/api/v1/profile/update', [
            'username' => 'sameuser',
            'email' => 'same@example.com',
            'city' => 'Jakarta',
        ])->assertOk();

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'city' => 'Jakarta',
        ]);
    }

    public function testCustomerCanRegisterSameAccountAsSeller(): void
    {
        $user = User::create([
            'username' => 'future_seller',
            'email' => 'future-seller@example.com',
            'password' => 'password123',
            'role' => 'customer',
        ]);

        $this->actingAs($user, 'api');

        $this->postJson('/api/v1/me/become-seller')
            ->assertOk()
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.email', 'future-seller@example.com')
            ->assertJsonPath('data.role', 'seller');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'email' => 'future-seller@example.com',
            'role' => 'seller',
        ]);
    }

    public function testAdminCannotRegisterAsSellerFromProfile(): void
    {
        $admin = User::create([
            'username' => 'admin_user',
            'email' => 'admin-user@example.com',
            'password' => 'password123',
            'role' => 'admin',
        ]);

        $this->actingAs($admin, 'api');

        $this->postJson('/api/v1/me/become-seller')
            ->assertStatus(422);

        $this->assertDatabaseHas('users', [
            'id' => $admin->id,
            'role' => 'admin',
        ]);
    }
}
