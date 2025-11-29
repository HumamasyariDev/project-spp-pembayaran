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
        // Tabel Kelas (X, XI, XII)
        Schema::create('kelas', function (Blueprint $table) {
            $table->id();
            $table->string('nama')->unique(); // X, XI, XII
            $table->string('keterangan')->nullable();
            $table->boolean('aktif')->default(true);
            $table->timestamps();
        });

        // Tabel Jurusan (RPL, TKJ, TKR, TPM, LAS, LISTRIK)
        Schema::create('jurusan', function (Blueprint $table) {
            $table->id();
            $table->string('kode')->unique(); // RPL, TKJ, dll
            $table->string('nama'); // Nama lengkap jurusan
            $table->text('deskripsi')->nullable();
            $table->boolean('aktif')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('jurusan');
        Schema::dropIfExists('kelas');
    }
};
