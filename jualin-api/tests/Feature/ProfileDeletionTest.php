<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfileDeletionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function test_deletion_requires_the_current_password_and_exact_phrase(): void
    {
        $user = $this->makeCustomer();

        $this->actingAs($user, 'api')
            ->postJson('/api/v1/me/deletion-request', [
                'password' => 'wrong-password',
                'confirmation_phrase' => 'HAPUS AKUN',
            ])
            ->assertStatus(422);

        $this->actingAs($user, 'api')
            ->postJson('/api/v1/me/deletion-request', [
                'password' => 'secret-password',
                'confirmation_phrase' => 'hapus akun',
            ])
            ->assertStatus(422);

        $this->assertNull($user->fresh()->scheduled_deletion_at);
    }

    public function test_deletion_is_scheduled_for_fourteen_days_and_can_be_cancelled(): void
    {
        $user = $this->makeCustomer();

        $this->actingAs($user, 'api')
            ->postJson('/api/v1/me/deletion-request', [
                'password' => 'secret-password',
                'confirmation_phrase' => 'HAPUS AKUN',
            ])
            ->assertOk()
            ->assertJsonPath('data.recovery_days', 14);

        $this->assertTrue($user->fresh()->scheduled_deletion_at->between(
            now()->addDays(14)->subMinute(),
            now()->addDays(14)->addMinute(),
        ));

        $this->actingAs($user->fresh(), 'api')
            ->deleteJson('/api/v1/me/deletion-request')
            ->assertOk();

        $this->assertNull($user->fresh()->deletion_requested_at);
        $this->assertNull($user->fresh()->scheduled_deletion_at);
    }

    public function test_purge_command_only_deletes_accounts_after_recovery_deadline(): void
    {
        $user = $this->makeCustomer();
        $user->forceFill([
            'deletion_requested_at' => now(),
            'scheduled_deletion_at' => now()->addDay(),
        ])->save();

        $this->artisan('accounts:purge-scheduled')->assertSuccessful();
        $this->assertDatabaseHas('users', ['id' => $user->id]);

        $user->forceFill(['scheduled_deletion_at' => now()->subMinute()])->save();
        $this->artisan('accounts:purge-scheduled')->assertSuccessful();
        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }

    private function makeCustomer(): User
    {
        return User::create([
            'username' => 'deletion-customer',
            'email' => 'deletion@example.com',
            'password' => 'secret-password',
            'role' => 'customer',
        ]);
    }
}
