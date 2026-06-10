<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function testAdminCanBanReportedUserFromReport()
    {
        $admin = User::create([
            'username' => 'adminuser',
            'email' => 'admin@example.com',
            'password' => 'password',
            'role' => 'admin',
        ]);

        $reportedUser = User::create([
            'username' => 'reported-seller',
            'email' => 'seller@example.com',
            'password' => 'password',
            'role' => 'seller',
        ]);

        $reporter = User::create([
            'username' => 'customer-reporter',
            'email' => 'reporter@example.com',
            'password' => 'password',
            'role' => 'customer',
        ]);

        $report = Report::create([
            'reporter_id' => $reporter->id,
            'reporter_username' => $reporter->username,
            'reported_user_id' => $reportedUser->id,
            'reported_username' => $reportedUser->username,
            'username' => $reporter->username,
            'type' => 'Laporan Pengguna',
            'target_username' => $reportedUser->username,
            'description' => 'Reported seller issue',
            'status' => 'pending',
        ]);

        $this->actingAs($admin, 'api');

        $res = $this->json('PATCH', "/api/v1/reports/{$report->id}/ban", [
            'duration_days' => 7,
        ]);

        $res->assertOk()
            ->assertJsonPath('data.user.is_banned', true)
            ->assertJsonStructure(['data' => ['ban_started_at', 'banned_until']]);

        $reportedUser->refresh();
        $reporter->refresh();
        $this->assertTrue($reportedUser->is_banned);
        $this->assertFalse($reporter->is_banned);
        $this->assertNotNull($reportedUser->banned_until);
        $this->assertTrue($reportedUser->banned_until->greaterThan(now()->addDays(6)));
    }

    public function testStoreUserViolationReportUsesAuthenticatedReporterAndSelectedTarget()
    {
        $reporter = User::create([
            'username' => 'customer-reporter',
            'email' => 'customer@example.com',
            'password' => 'password',
            'role' => 'customer',
        ]);

        $reportedUser = User::create([
            'username' => 'violator-user',
            'email' => 'violator@example.com',
            'password' => 'password',
            'role' => 'seller',
        ]);

        $this->actingAs($reporter, 'api');

        $res = $this->json('POST', '/api/v1/reports', [
            'type' => 'Laporan Pengguna',
            'reported_user_id' => $reportedUser->id,
            'description' => 'This user is violating marketplace rules.',
        ]);

        $res->assertStatus(201)
            ->assertJsonPath('data.reporter_id', $reporter->id)
            ->assertJsonPath('data.reporter_username', $reporter->username)
            ->assertJsonPath('data.reported_user_id', $reportedUser->id)
            ->assertJsonPath('data.reported_username', $reportedUser->username);

        $this->assertDatabaseHas('reports', [
            'reporter_id' => $reporter->id,
            'reported_user_id' => $reportedUser->id,
            'username' => $reporter->username,
            'target_username' => $reportedUser->username,
        ]);
    }

    public function testStoreProductReportStoresProductAndSellerInformation()
    {
        $seller = User::create([
            'username' => 'seller-owner',
            'email' => 'seller-owner@example.com',
            'password' => 'password',
            'role' => 'seller',
        ]);

        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'Fake Product',
            'description' => 'Product used for report tests',
            'price' => 100000,
            'stock_quantity' => 10,
            'category' => 'Elektronik',
            'status' => 'active',
        ]);

        $reporter = User::create([
            'username' => 'customer-reporter',
            'email' => 'customer@example.com',
            'password' => 'password',
            'role' => 'customer',
        ]);

        $this->actingAs($reporter, 'api');

        $res = $this->json('POST', '/api/v1/reports', [
            'product_id' => $product->id,
            'type' => 'Penipuan',
            'description' => 'Produk terlihat penipuan dan tidak sesuai.',
        ]);

        $res->assertStatus(201)
            ->assertJsonPath('data.product_id', $product->id)
            ->assertJsonPath('data.reported_user_id', $seller->id)
            ->assertJsonPath('data.reported_username', $seller->username);

        $this->assertDatabaseHas('reports', [
            'product_id' => $product->id,
            'reported_user_id' => $seller->id,
            'type' => 'Penipuan',
            'description' => 'Produk terlihat penipuan dan tidak sesuai.',
        ]);
    }

    public function testStoreUserViolationReportRejectsSelfTarget()
    {
        $reporter = User::create([
            'username' => 'self-reporter',
            'email' => 'self@example.com',
            'password' => 'password',
            'role' => 'customer',
        ]);

        $this->actingAs($reporter, 'api');

        $res = $this->json('POST', '/api/v1/reports', [
            'type' => 'Laporan Pengguna',
            'reported_user_id' => $reporter->id,
            'description' => 'Trying to report myself.',
        ]);

        $res->assertStatus(422);
    }

    public function testAdminCanUpdateReportStatus()
    {
        $admin = User::create([
            'username' => 'adminuser',
            'email' => 'admin@example.com',
            'password' => 'password',
            'role' => 'admin',
        ]);

        $reporter = User::create([
            'username' => 'customer-reporter',
            'email' => 'customer@example.com',
            'password' => 'password',
            'role' => 'customer',
        ]);

        $reportedUser = User::create([
            'username' => 'violator-user',
            'email' => 'violator@example.com',
            'password' => 'password',
            'role' => 'seller',
        ]);

        $report = Report::create([
            'reporter_id' => $reporter->id,
            'reporter_username' => $reporter->username,
            'reported_user_id' => $reportedUser->id,
            'reported_username' => $reportedUser->username,
            'username' => $reporter->username,
            'type' => 'Laporan Pengguna',
            'target_username' => $reportedUser->username,
            'description' => 'Review this report',
            'status' => 'pending',
        ]);

        $this->actingAs($admin, 'api');

        $res = $this->json('PATCH', "/api/v1/reports/{$report->id}/status", [
            'status' => 'rejected',
        ]);

        $res->assertOk()
            ->assertJsonPath('data.status', 'rejected');

        $this->assertDatabaseHas('reports', [
            'id' => $report->id,
            'status' => 'rejected',
        ]);
    }

    public function test_admin_can_filter_pending_reports_and_set_page_size()
    {
        $admin = User::create([
            'username' => 'filter-admin',
            'email' => 'filter-admin@example.com',
            'password' => 'password',
            'role' => 'admin',
        ]);
        $reporter = User::create([
            'username' => 'filter-reporter',
            'email' => 'filter-reporter@example.com',
            'password' => 'password',
            'role' => 'customer',
        ]);

        Report::create([
            'reporter_id' => $reporter->id,
            'reporter_username' => $reporter->username,
            'username' => $reporter->username,
            'type' => 'Pending report',
            'description' => 'Needs review',
            'status' => 'pending',
        ]);

        Report::create([
            'reporter_id' => $reporter->id,
            'reporter_username' => $reporter->username,
            'username' => $reporter->username,
            'type' => 'Resolved report',
            'description' => 'Already handled',
            'status' => 'resolved',
        ]);

        $this->actingAs($admin, 'api')
            ->getJson('/api/v1/reports?status=pending&per_page=100')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status', 'pending')
            ->assertJsonPath('pagination.per_page', 100);
    }
}
