<?php

namespace App\Repositories;

use App\Models\Product;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Storage;

class ProductRepository
{
    public function getAll(array $filters = []): LengthAwarePaginator
    {
        $q = Product::query()->with('seller');

        if (!empty($filters['seller_id'])) {
            $q->where('seller_id', $filters['seller_id']);
        }

        if (!empty($filters['category'])) {
            $q->whereRaw('LOWER(category) = ?', [mb_strtolower($filters['category'])]);
        }

        if (!empty($filters['location'])) {
            $location = $filters['location'];
            $q->whereHas('seller', function ($sq) use ($location) {
                $sq->where('city', $location)->orWhere('region', $location);
            });
        }

        if (!empty($filters['name'])) {
            $needle = $filters['name'];
            $safe = '%' . mb_strtolower($needle) . '%';
            $q->where(function ($sq) use ($safe) {
                $sq->whereRaw('LOWER(name) LIKE ?', [$safe])
                   ->orWhereRaw('LOWER(description) LIKE ?', [$safe]);
            });
        }

        if (isset($filters['price_min']) && $filters['price_min'] !== '') {
            $q->where('price', '>=', $filters['price_min']);
        }

        if (isset($filters['price_max']) && $filters['price_max'] !== '') {
            $q->where('price', '<=', $filters['price_max']);
        }

        if (isset($filters['min_stock'])) {
            $q->where('stock_quantity', '>=', $filters['min_stock']);
        }

        $allowedSort = ['price', 'name', 'created_at'];
        if (!empty($filters['sort_by']) && in_array($filters['sort_by'], $allowedSort, true)) {
            $direction = 'asc';
            if (!empty($filters['sort_dir']) && in_array(strtolower($filters['sort_dir']), ['asc', 'desc'], true)) {
                $direction = strtolower($filters['sort_dir']);
            }
            $q->orderBy($filters['sort_by'], $direction);
        } else {
            $q->orderByDesc('created_at');
        }

        $perPage = isset($filters['per_page']) && (int) $filters['per_page'] > 0
            ? (int) $filters['per_page']
            : 10;

        return $q->paginate($perPage);
    }

    public function find(int $id): ?Product
    {
        return Product::with('seller')->find($id);
    }

    public function create(array $data): Product
    {
        $data['image'] = $this->prepareImageValue($this->processImages($data));
        return Product::create($data);
    }

    public function update(int $id, array $data): ?Product
    {
        $product = $this->find($id);
        if (!$product) {
            return null;
        }

        $newImages = $this->processImages($data);
        if ($newImages !== null) {
            // Delete old images when new ones are provided
            $oldImages = $this->extractStoredImages($product->getRawOriginal('image'));
            if (!empty($oldImages)) {
                foreach ($oldImages as $oldImage) {
                    if ($oldImage && Storage::disk('public')->exists($oldImage)) {
                        Storage::disk('public')->delete($oldImage);
                    }
                }
            }
            $data['image'] = $this->prepareImageValue($newImages);
        }

        $product->fill($data);
        $product->save();
        return $product;
    }

    /**
     * Process single or multiple image uploads
     * Returns array of image paths or null if no images
     */
    private function processImages(array $data): ?array
    {
        // Handle multiple images from 'images' array
        if (isset($data['images']) && is_array($data['images']) && !empty($data['images'])) {
            $imagePaths = [];
            foreach ($data['images'] as $file) {
                if ($file instanceof \Illuminate\Http\UploadedFile) {
                    $imagePaths[] = $file->store('products', 'public');
                }
            }
            if (!empty($imagePaths)) {
                return $imagePaths;
            }
        }

        // Handle single image from 'image' field (backward compatibility)
        if (isset($data['image']) && $data['image'] instanceof \Illuminate\Http\UploadedFile) {
            return [$data['image']->store('products', 'public')];
        }

        return null;
    }

    private function prepareImageValue(?array $images): ?string
    {
        if ($images === null) {
            return null;
        }

        return json_encode(array_values($images));
    }

    private function extractStoredImages($value): array
    {
        if (!$value) {
            return [];
        }

        if (is_array($value)) {
            return array_values(array_filter($value));
        }

        if (is_string($value)) {
            $decoded = json_decode($value, true);
            if (is_array($decoded)) {
                return array_values(array_filter($decoded));
            }

            return [$value];
        }

        return [];
    }

    public function delete(int $id): bool
    {
        $product = $this->find($id);
        if (!$product) {
            return false;
        }

        // Delete all images
        $images = $this->extractStoredImages($product->getRawOriginal('image'));
        if (!empty($images)) {
            foreach ($images as $image) {
                if ($image && Storage::disk('public')->exists($image)) {
                    Storage::disk('public')->delete($image);
                }
            }
        }

        return (bool) $product->delete();
    }
}
