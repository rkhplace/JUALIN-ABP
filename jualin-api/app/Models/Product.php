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
        'image' => 'array',
    ];

    public function seller()
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function getImageAttribute($value)
    {
        // Jika null atau kosong
        if (!$value) {
            return [];
        }

        // Jika sudah array dari casting
        if (is_array($value)) {
            return array_map(function ($image) {
                if (!$image) {
                    return null;
                }

                if (filter_var($image, FILTER_VALIDATE_URL)) {
                    return $image;
                }

                return asset('storage/' . $image);
            }, $value);
        }

        // Jika masih string (fallback)
        if (is_string($value)) {
            $decoded = json_decode($value, true);
            if (is_array($decoded)) {
                return array_map(function ($image) {
                    if (!$image) {
                        return null;
                    }

                    if (filter_var($image, FILTER_VALIDATE_URL)) {
                        return $image;
                    }

                    return asset('storage/' . $image);
                }, $decoded);
            }
        }

        return [];
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

        if (filter_var($first, FILTER_VALIDATE_URL)) {
            return $first;
        }

        return asset('storage/' . $first);
    }
}
