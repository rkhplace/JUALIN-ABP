<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Store existing data first
        $products = DB::table('products')->get();
        $imageData = [];
        
        foreach ($products as $product) {
            if ($product->image) {
                $imageData[$product->id] = $product->image;
            }
        }

        // Drop the old string column
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('image');
        });

        // Add new JSON column
        Schema::table('products', function (Blueprint $table) {
            $table->json('image')->nullable();
        });

        // Restore data as JSON array
        foreach ($imageData as $productId => $imagePath) {
            DB::table('products')
                ->where('id', $productId)
                ->update([
                    'image' => json_encode([$imagePath])
                ]);
        }
    }

    public function down(): void
    {
        // Store existing data first
        $products = DB::table('products')->get();
        $firstImages = [];
        
        foreach ($products as $product) {
            if ($product->image) {
                $images = json_decode($product->image, true);
                if (is_array($images) && !empty($images)) {
                    $firstImages[$product->id] = $images[0];
                }
            }
        }

        // Drop JSON column
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('image');
        });

        // Add back string column
        Schema::table('products', function (Blueprint $table) {
            $table->string('image')->nullable();
        });

        // Restore first image only
        foreach ($firstImages as $productId => $imagePath) {
            DB::table('products')
                ->where('id', $productId)
                ->update(['image' => $imagePath]);
        }
    }
};

