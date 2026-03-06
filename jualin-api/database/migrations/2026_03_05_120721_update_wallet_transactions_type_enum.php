<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('wallet_transactions', function (Blueprint $table) {
            DB::statement('ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check');
            DB::statement("ALTER TABLE wallet_transactions ADD CONSTRAINT wallet_transactions_type_check CHECK (type::text = ANY (ARRAY['purchase'::character varying, 'refund'::character varying, 'claim'::character varying, 'withdraw'::character varying]::text[]))");
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('wallet_transactions', function (Blueprint $table) {
            DB::statement('ALTER TABLE wallet_transactions DROP CONSTRAINT IF EXISTS wallet_transactions_type_check');
            DB::statement("ALTER TABLE wallet_transactions ADD CONSTRAINT wallet_transactions_type_check CHECK (type::text = ANY (ARRAY['refund'::character varying, 'claim'::character varying, 'withdraw'::character varying]::text[]))");
        });
    }
};
