<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\User;
use App\Models\Product;

class ProductControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['auth.guards.api.driver' => 'session']);
    }

    public function testIndexReturnsProducts()
    {
        $seller = User::create([
            'username' => 'seller',
            'email' => 'seller@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);

        Product::create([
            'seller_id' => $seller->id,
            'name' => 'P1',
            'price' => 10000,
            'stock_quantity' => 1,
        ]);

        $res = $this->json('GET', '/api/v1/products');
        $res->assertStatus(200)->assertJsonStructure([
            'products', 'totalProducts', 'totalPages', 'currentPage'
        ]);
    }

    public function testShowNotFoundReturns404()
    {
        $res = $this->json('GET', '/api/v1/products/999999');
        $res->assertStatus(404)->assertJson(['message' => 'Product not found']);
    }

    public function testIndexMeReturnsOnlyOwnProductsForSeller()
    {
        $seller1 = User::create([
            'username' => 'seller1',
            'email' => 'seller1@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);
        $seller2 = User::create([
            'username' => 'seller2',
            'email' => 'seller2@example.com',
            'password' => 'pw',
            'role' => 'seller',
        ]);

        Product::create([
            'seller_id' => $seller1->id,
            'name' => 'Mine',
            'price' => 10000,
            'stock_quantity' => 1,
        ]);
        Product::create([
            'seller_id' => $seller2->id,
            'name' => 'NotMine',
            'price' => 10000,
            'stock_quantity' => 1,
        ]);

        $this->actingAs($seller1, 'api');
        $res = $this->json('GET', '/api/v1/seller/products');

        $res->assertStatus(200)
            ->assertJsonFragment(['name' => 'Mine'])
            ->assertJsonMissing(['name' => 'NotMine']);
    }
}