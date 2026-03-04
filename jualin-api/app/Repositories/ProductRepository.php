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
        if (isset($data['image']) && $data['image'] instanceof \Illuminate\Http\UploadedFile) {
            $data['image'] = $data['image']->store('products', 'public');
        }
        return Product::create($data);
    }

    public function update(int $id, array $data): ?Product
    {
        $product = $this->find($id);
        if (!$product) {
            return null;
        }

        if (isset($data['image']) && $data['image'] instanceof \Illuminate\Http\UploadedFile) {
            $old = $product->getRawOriginal('image');
            if ($old && Storage::disk('public')->exists($old)) {
                Storage::disk('public')->delete($old);
            }
            $data['image'] = $data['image']->store('products', 'public');
        }

        $product->fill($data);
        $product->save();
        return $product;
    }

    public function delete(int $id): bool
    {
        $product = $this->find($id);
        if (!$product) {
            return false;
        }

        $old = $product->getRawOriginal('image');
        if ($old && Storage::disk('public')->exists($old)) {
            Storage::disk('public')->delete($old);
        }

        return (bool) $product->delete();
    }
}