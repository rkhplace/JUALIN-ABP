<?php

namespace Tests\Unit;

use Tests\TestCase;
use Mockery;
use App\Services\ProductService;
use App\Repositories\ProductRepository;
use Illuminate\Pagination\LengthAwarePaginator;
use App\Models\Product;

class ProductServiceTest extends TestCase
{
    public function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function testDelegatesToRepository()
    {
        $repo = Mockery::mock(ProductRepository::class);

        // Typed paginator return
        $paginator = new LengthAwarePaginator([], 0, 15);
        $repo->shouldReceive('getAll')->once()->andReturn($paginator);

        // find() returns a Product
        $product = new Product();
        $product->id = 10;
        $product->name = 'PRODUCT';
        $repo->shouldReceive('find')->once()->with(10)->andReturn($product);

        // create() returns a Product
        $created = new Product();
        $created->id = 11;
        $created->name = 'CREATED';
        $repo->shouldReceive('create')->once()->with(['a' => 1])->andReturn($created);

        // update() returns a Product (nullable return in repo; here return instance)
        $updated = new Product();
        $updated->id = 10;
        $updated->name = 'UPDATED';
        $repo->shouldReceive('update')->once()->with(10, ['b' => 2])->andReturn($updated);

        // delete() returns bool
        $repo->shouldReceive('delete')->once()->with(10)->andReturn(true);

        $svc = new ProductService($repo);

        $this->assertInstanceOf(LengthAwarePaginator::class, $svc->listAll());

        $got = $svc->get(10);
        $this->assertInstanceOf(Product::class, $got);
        $this->assertSame('PRODUCT', $got->name);

        $resCreated = $svc->create(['a' => 1]);
        $this->assertInstanceOf(Product::class, $resCreated);
        $this->assertSame('CREATED', $resCreated->name);

        $resUpdated = $svc->update(10, ['b' => 2]);
        $this->assertInstanceOf(Product::class, $resUpdated);
        $this->assertSame('UPDATED', $resUpdated->name);

        $this->assertTrue($svc->delete(10));
    }
}