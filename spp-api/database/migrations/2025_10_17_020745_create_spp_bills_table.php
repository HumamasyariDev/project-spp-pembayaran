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
        Schema::create('spp_bills', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('nomor_tagihan')->unique();
            $table->string('bulan');
            $table->string('tahun');
            $table->decimal('jumlah', 15, 2);
            $table->enum('status', ['belum_dibayar', 'menunggu_verifikasi', 'lunas'])->default('belum_dibayar');
            $table->date('tanggal_jatuh_tempo');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('spp_bills');
    }
};
