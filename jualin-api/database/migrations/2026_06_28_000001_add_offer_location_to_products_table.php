<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->string('location_label')->nullable()->after('status');
            $table->unsignedSmallInteger('location_radius_km')->nullable()->after('location_label');
            $table->decimal('latitude', 10, 7)->nullable()->after('location_radius_km');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn([
                'location_label',
                'location_radius_km',
                'latitude',
                'longitude',
            ]);
        });
    }
};
