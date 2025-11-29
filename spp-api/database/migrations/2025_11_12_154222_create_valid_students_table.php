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
        Schema::create('valid_students', function (Blueprint $table) {
            $table->string('nisn', 10)->primary()->comment('Nomor Induk Siswa Nasional');
            $table->string('nama', 100);
            $table->string('kelas', 20)->nullable();
            $table->string('jurusan', 50)->nullable();
            $table->enum('status_kelulusan', ['aktif', 'lulus', 'pindah', 'keluar'])->default('aktif');
            $table->boolean('is_registered')->default(false)->comment('Sudah pernah registrasi atau belum');
            $table->year('tahun_lulus')->nullable()->comment('Tahun kelulusan jika status = lulus');
            $table->timestamps();
            
            // Index for faster lookup
            $table->index('status_kelulusan');
            $table->index('is_registered');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('valid_students');
    }
};
