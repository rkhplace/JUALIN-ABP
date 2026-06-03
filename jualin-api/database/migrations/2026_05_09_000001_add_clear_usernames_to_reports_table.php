<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->string('reporter_username')->nullable()->after('reporter_id');
            $table->string('reported_username')->nullable()->after('reported_user_id');
        });

        DB::table('reports')
            ->whereNull('reporter_username')
            ->update(['reporter_username' => DB::raw('username')]);

        DB::table('reports')
            ->whereNull('reported_username')
            ->update(['reported_username' => DB::raw('target_username')]);
    }

    public function down(): void
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->dropColumn(['reporter_username', 'reported_username']);
        });
    }
};
