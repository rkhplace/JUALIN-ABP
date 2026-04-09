<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class Product extends Model
{
    use HasFactory;

    protected $table = 'products';

    protected $fillable = [
        'seller_id',
        'name',
        'description',
        'price',
        'stock_quantity',
        'image',
        'category',
        'condition',
        'status',
    ];
    protected $casts = [
        'price' => 'integer',
        'stock_quantity' => 'integer',
    ];

    public function seller()
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function getImageAttribute($value)
    {
        return $this->normalizeImages($value);
    }

    /**
     * Get first image (for backward compatibility and thumbnails)
     */
    public function getFirstImageAttribute()
    {
        $images = $this->image;

        if (!$images || !is_array($images) || empty($images)) {
            return 'https://via.placeholder.com/400x400?text=No+Image';
        }

        $first = $images[0];
        if (!$first) {
            return 'https://via.placeholder.com/400x400?text=No+Image';
        }

        return $first;
    }

    private function normalizeImages($value): array
    {
        if (!$value) {
            return [];
        }

        $images = [];

        if (is_array($value)) {
            $images = $value;
        } elseif (is_string($value)) {
            $decoded = json_decode($value, true);
            if (is_array($decoded)) {
                $images = $decoded;
            } else {
                $images = [$value];
            }
        }

        return array_values(array_filter(array_map(
            fn ($image) => $this->resolveImageUrl($image),
            $images
        )));
    }

    private function resolveImageUrl($image): ?string
    {
        if (!$image || !is_string($image)) {
            return null;
        }

        if (filter_var($image, FILTER_VALIDATE_URL)) {
            return $image;
        }

        $baseUrl = rtrim(request()?->getSchemeAndHttpHost() ?: config('app.url', ''), '/');
        $cleanPath = ltrim($image, '/');
        $storagePath = str_starts_with($cleanPath, 'storage/')
            ? $cleanPath
            : 'storage/' . $cleanPath;

        return $baseUrl ? "{$baseUrl}/{$storagePath}" : "/{$storagePath}";
    }
}
