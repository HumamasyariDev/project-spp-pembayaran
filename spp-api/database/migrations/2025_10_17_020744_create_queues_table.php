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
        Schema::create('queues', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('nomor_antrian');
            $table->enum('status', ['menunggu', 'dipanggil', 'dilayani', 'selesai', 'dibatalkan'])->default('menunggu');
            $table->date('tanggal_antrian');
            $table->foreignId('dipanggil_oleh')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('waktu_dipanggil')->nullable();
            $table->timestamp('waktu_dilayani')->nullable();
            $table->timestamp('waktu_selesai')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('queues');
    }
};
