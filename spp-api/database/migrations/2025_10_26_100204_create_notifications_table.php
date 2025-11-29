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
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title'); // Judul notifikasi
            $table->text('message'); // Isi pesan notifikasi
            $table->string('type'); // queue, payment, general
            $table->json('data')->nullable(); // Data tambahan (id antrian, id payment, dll)
            $table->boolean('is_read')->default(false); // Status sudah dibaca atau belum
            $table->timestamp('read_at')->nullable(); // Waktu dibaca
            $table->timestamps();
            
            // Index untuk query cepat
            $table->index('user_id');
            $table->index(['user_id', 'is_read']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
