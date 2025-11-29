<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class KelasJurusanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // ========== KELAS ==========
        $kelas = [
            [
                'nama' => 'X',
                'keterangan' => 'Kelas 10',
                'aktif' => true,
            ],
            [
                'nama' => 'XI',
                'keterangan' => 'Kelas 11',
                'aktif' => true,
            ],
            [
                'nama' => 'XII',
                'keterangan' => 'Kelas 12',
                'aktif' => true,
            ],
        ];

        foreach ($kelas as $k) {
            DB::table('kelas')->insert([
                'nama' => $k['nama'],
                'keterangan' => $k['keterangan'],
                'aktif' => $k['aktif'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // ========== JURUSAN ==========
        $jurusan = [
            [
                'kode' => 'RPL',
                'nama' => 'Rekayasa Perangkat Lunak',
                'deskripsi' => 'Jurusan yang mempelajari pemrograman dan pengembangan software',
                'aktif' => true,
            ],
            [
                'kode' => 'TKJ',
                'nama' => 'Teknik Komputer dan Jaringan',
                'deskripsi' => 'Jurusan yang mempelajari jaringan komputer dan hardware',
                'aktif' => true,
            ],
            [
                'kode' => 'TKR',
                'nama' => 'Teknik Kendaraan Ringan',
                'deskripsi' => 'Jurusan yang mempelajari mekanik dan sistem kendaraan',
                'aktif' => true,
            ],
            [
                'kode' => 'TPM',
                'nama' => 'Teknik Pemesinan',
                'deskripsi' => 'Jurusan yang mempelajari teknik mesin dan produksi',
                'aktif' => true,
            ],
            [
                'kode' => 'LAS',
                'nama' => 'Teknik Pengelasan',
                'deskripsi' => 'Jurusan yang mempelajari teknik pengelasan logam',
                'aktif' => true,
            ],
            [
                'kode' => 'LISTRIK',
                'nama' => 'Teknik Instalasi Tenaga Listrik',
                'deskripsi' => 'Jurusan yang mempelajari instalasi dan sistem kelistrikan',
                'aktif' => true,
            ],
        ];

        foreach ($jurusan as $j) {
            DB::table('jurusan')->insert([
                'kode' => $j['kode'],
                'nama' => $j['nama'],
                'deskripsi' => $j['deskripsi'],
                'aktif' => $j['aktif'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $this->command->info('✅ Kelas dan Jurusan berhasil di-seed!');
        $this->command->info('📊 Kelas: X, XI, XII');
        $this->command->info('📊 Jurusan: RPL, TKJ, TKR, TPM, LAS, LISTRIK');
    }
}
