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
        Schema::table('users', function (Blueprint $table) {
            $table->string('nis')->nullable()->after('email');
            $table->string('nisn')->nullable()->after('nis');
            $table->string('telepon')->nullable()->after('nisn');
            $table->text('alamat')->nullable()->after('telepon');
            $table->string('kelas')->nullable()->after('alamat');
            $table->enum('jenis_kelamin', ['L', 'P'])->nullable()->after('kelas');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['nis', 'nisn', 'telepon', 'alamat', 'kelas', 'jenis_kelamin']);
        });
    }
};
