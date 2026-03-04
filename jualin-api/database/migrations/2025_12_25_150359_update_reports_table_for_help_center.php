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
        Schema::table('reports', function (Blueprint $table) {
            // Make existing FK columns nullable in case we want to keep data, 
            // or drop them if they are strict. 
            // Since we are changing the nature of the table, let's make them nullable 
            // and add our new columns.
            
            // Drop valid foreign keys if they exist to avoid constraints issues
            $table->dropForeign(['reporter_id']);
            $table->dropForeign(['reported_user_id']);
            $table->dropForeign(['product_id']);

            // Make old columns nullable
            $table->unsignedBigInteger('reporter_id')->nullable()->change();
            $table->unsignedBigInteger('reported_user_id')->nullable()->change();
            $table->unsignedBigInteger('product_id')->nullable()->change();

            // Add new columns for Help Center
            $table->string('username')->nullable(); // String username from form
            $table->string('type')->default('Lainnya');
            $table->string('target_username')->nullable(); // String target from form
            
            // Modify description to be text and nullable (already text nullable in old migration)
            // Modify status to string to allow custom statuses beyond enum if needed, or update enum
            // For safety, drop old status and add new string status
            $table->dropColumn('status');
        });
        
        Schema::table('reports', function (Blueprint $table) {
             $table->string('status')->default('pending');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reports', function (Blueprint $table) {
             // Reverting is complex due to data loss, simplify for dev
            $table->dropColumn(['username', 'type', 'target_username']);
            $table->dropColumn('status');
        });
         
        Schema::table('reports', function (Blueprint $table) {
            $table->enum('status', ['pending', 'reviewed', 'resolved'])->default('pending');
        });
    }
};
