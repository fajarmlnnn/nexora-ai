<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table): void {
            $table->string('idempotency_key', 100)->nullable()->after('note');
            $table->unique(['user_id', 'idempotency_key'], 'transactions_user_id_idempotency_unique');
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table): void {
            $table->dropUnique('transactions_user_id_idempotency_unique');
            $table->dropColumn('idempotency_key');
        });
    }
};
