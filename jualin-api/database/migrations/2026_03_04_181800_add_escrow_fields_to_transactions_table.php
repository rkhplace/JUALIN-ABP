<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->string('auth_code')->nullable()->after('total_amount');
        });
        
        DB::statement('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_status_check');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropColumn('auth_code');
        });
        
        // We can optionally add it back, but practically dropping it down is sufficient for rollback.
    }
};
