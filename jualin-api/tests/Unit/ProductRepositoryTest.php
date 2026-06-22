<?php

namespace Tests\Unit;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\UploadedFile;
use App\Repositories\ProductRepository;
use App\Models\Product;
use App\Models\User;

class ProductRepositoryTest extends TestCase
{
    use RefreshDatabase;

    private function makeSeller(string $suffix = ''): User
    {
        return User::create([
            'username' => 'seller' . $suffix,
            'email' => 'seller' . $suffix . '@example.com',
            'password' => 'pw',
            'role' => 'seller',
            'city' => 'Bandung',
            'region' => 'Jawa Barat',
        ]);
    }

    public function testGetAllFiltersAndPagination()
    {
        $seller = $this->makeSeller('X');
        foreach (range(1, 3) as $i) {
            Product::create([
                'seller_id' => $seller->id,
                'category' => 'Elektronik',
                'name' => 'Laptop Keren ' . $i,
                'price' => 5000000,
                'stock_quantity' => 5,
            ]);
        }

        $repo = new ProductRepository();
        $page = $repo->getAll([
            'category' => 'elektronik',
            'name' => 'lap',
            'price_min' => 1000000,
            'price_max' => 6000000,
            'min_stock' => 1,
            'sort_by' => 'price',
            'sort_dir' => 'desc',
            'per_page' => 2,
        ]);

        $this->assertCount(2, $page->items());
        $this->assertGreaterThanOrEqual(2, $page->total());
        $this->assertSame(2, $page->perPage());
    }

    public function testCreateStoresImage()
    {
        Storage::fake('public');
        $seller = $this->makeSeller('Y');

        $repo = new ProductRepository();
        $product = $repo->create([
            'seller_id' => $seller->id,
            'name' => 'AA',
            'price' => 10000,
            'stock_quantity' => 1,
            'image' => UploadedFile::fake()->create('p.jpg', 12, 'image/jpeg'),
        ]);

        $storedImages = json_decode($product->getRawOriginal('image'), true);
        $this->assertNotEmpty($storedImages);
        $this->assertTrue(Storage::disk('public')->exists($storedImages[0]));
    }

    public function testUpdateReplacesImageAndDeletesOld()
    {
        Storage::fake('public');
        $seller = $this->makeSeller('Z');

        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'AA',
            'price' => 10000,
            'stock_quantity' => 1,
            'image' => 'products/old.jpg',
        ]);
        Storage::disk('public')->put('products/old.jpg', 'x');

        $repo = new ProductRepository();
        $updated = $repo->update($product->id, [
            'name' => 'BB',
            'image' => UploadedFile::fake()->create('new.jpg', 12, 'image/jpeg'),
        ]);

        $this->assertSame('BB', $updated->name);
        $this->assertFalse(Storage::disk('public')->exists('products/old.jpg'));
        $storedImages = json_decode($updated->getRawOriginal('image'), true);
        $this->assertNotEmpty($storedImages);
        $this->assertTrue(Storage::disk('public')->exists($storedImages[0]));
    }

    public function testDeleteRemovesImageAndReturnsTrue()
    {
        Storage::fake('public');
        $seller = $this->makeSeller('W');

        $product = Product::create([
            'seller_id' => $seller->id,
            'name' => 'AA',
            'price' => 10000,
            'stock_quantity' => 1,
            'image' => 'products/old.jpg',
        ]);
        Storage::disk('public')->put('products/old.jpg', 'x');

        $repo = new ProductRepository();
        $ok = $repo->delete($product->id);

        $this->assertTrue($ok);
        $this->assertFalse(Storage::disk('public')->exists('products/old.jpg'));
        $this->assertNull(Product::find($product->id));
    }
}
