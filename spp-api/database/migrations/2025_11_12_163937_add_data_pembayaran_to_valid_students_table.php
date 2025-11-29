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
        Schema::table('valid_students', function (Blueprint $table) {
            // ✅ JSON column untuk menyimpan histori pembayaran SPP
            // Format: [
            //   {'bulan': 1, 'status': 'lunas', 'tanggal_bayar': '2025-01-05', 'jumlah': 500000},
            //   {'bulan': 2, 'status': 'belum_dibayar', 'tanggal_bayar': null, 'jumlah': 500000},
            //   ...
            // ]
            $table->json('data_pembayaran')->nullable()->after('is_registered');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('valid_students', function (Blueprint $table) {
            $table->dropColumn('data_pembayaran');
        });
    }
};
