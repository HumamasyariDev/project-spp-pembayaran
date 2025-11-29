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
        Schema::create('tagihan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('bulan'); // e.g., "Januari 2025"
            $table->integer('tahun'); // e.g., 2025
            $table->integer('jumlah'); // Amount in IDR
            $table->enum('status', ['unpaid', 'paid', 'pending', 'failed', 'refund'])->default('unpaid');
            $table->date('jatuh_tempo'); // Due date
            $table->timestamp('tanggal_bayar')->nullable(); // Payment date
            $table->string('metode_bayar')->nullable(); // Payment method
            $table->integer('denda')->default(0); // Late fee
            $table->text('catatan')->nullable(); // Notes
            $table->string('transaction_id')->nullable(); // Midtrans transaction ID
            $table->timestamps();

            // Index for better query performance
            $table->index('user_id');
            $table->index('status');
            $table->index(['user_id', 'tahun']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tagihan');
    }
};

