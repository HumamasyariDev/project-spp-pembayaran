<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\ValidStudent;

class ValidStudentSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $students = [
            // ✅ SISWA AKTIF - Bisa registrasi
            // 🎯 CONTOH: Andi sudah bayar Januari-Februari (LUNAS)
            [
                'nisn' => '0051234567', 
                'nama' => 'Andi Pratama', 
                'kelas' => 'XII', 
                'jurusan' => 'RPL', 
                'status_kelulusan' => 'aktif',
                'data_pembayaran' => [
                    ['bulan' => 1, 'status' => 'lunas', 'jumlah' => 500000],
                    ['bulan' => 2, 'status' => 'lunas', 'jumlah' => 500000],
                    // Bulan 3-12 tidak ada = otomatis belum bayar
                ]
            ],
            
            // 🎯 CONTOH: Siti TIDAK ada data pembayaran (semua belum bayar)
            ['nisn' => '0051234568', 'nama' => 'Siti Nurhaliza', 'kelas' => 'XI', 'jurusan' => 'TKJ', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234569', 'nama' => 'Joko Widodo', 'kelas' => 'X', 'jurusan' => 'TPM', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234570', 'nama' => 'Dewi Sartika', 'kelas' => 'XII', 'jurusan' => 'TKR', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234571', 'nama' => 'Ahmad Dahlan', 'kelas' => 'XI', 'jurusan' => 'LAS', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234572', 'nama' => 'Kartini Wijaya', 'kelas' => 'XII', 'jurusan' => 'LISTRIK', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234573', 'nama' => 'Budi Santoso', 'kelas' => 'X', 'jurusan' => 'RPL', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234574', 'nama' => 'Rina Melati', 'kelas' => 'XI', 'jurusan' => 'TKJ', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234575', 'nama' => 'Hendra Gunawan', 'kelas' => 'XII', 'jurusan' => 'RPL', 'status_kelulusan' => 'aktif'],
            ['nisn' => '0051234576', 'nama' => 'Maya Sari', 'kelas' => 'X', 'jurusan' => 'TKR', 'status_kelulusan' => 'aktif'],
            
            // ❌ SISWA LULUS - Tidak bisa registrasi
            ['nisn' => '0041234567', 'nama' => 'Rudi Hermawan', 'kelas' => 'XII', 'jurusan' => 'RPL', 'status_kelulusan' => 'lulus', 'tahun_lulus' => 2024],
            ['nisn' => '0041234568', 'nama' => 'Sinta Dewi', 'kelas' => 'XII', 'jurusan' => 'TKJ', 'status_kelulusan' => 'lulus', 'tahun_lulus' => 2024],
            ['nisn' => '0041234569', 'nama' => 'Agus Salim', 'kelas' => 'XII', 'jurusan' => 'TPM', 'status_kelulusan' => 'lulus', 'tahun_lulus' => 2024],
            ['nisn' => '0041234570', 'nama' => 'Lia Amalia', 'kelas' => 'XII', 'jurusan' => 'TKR', 'status_kelulusan' => 'lulus', 'tahun_lulus' => 2024],
            ['nisn' => '0041234571', 'nama' => 'Dedi Kurniawan', 'kelas' => 'XII', 'jurusan' => 'LISTRIK', 'status_kelulusan' => 'lulus', 'tahun_lulus' => 2023],
            
            // ❌ SISWA PINDAH/KELUAR - Tidak bisa registrasi
            ['nisn' => '0051234577', 'nama' => 'Bambang Suryanto', 'kelas' => 'XI', 'jurusan' => 'RPL', 'status_kelulusan' => 'pindah'],
            ['nisn' => '0051234578', 'nama' => 'Ani Widiastuti', 'kelas' => 'X', 'jurusan' => 'TKJ', 'status_kelulusan' => 'keluar'],
        ];

        foreach ($students as $student) {
            ValidStudent::create($student);
        }

        echo "\n";
        echo "✅ Valid Students Seeder berhasil!\n";
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        echo "📊 Total: " . count($students) . " data siswa\n";
        echo "✅ Aktif (bisa registrasi): 10 siswa\n";
        echo "❌ Lulus (tidak bisa): 5 siswa\n";
        echo "❌ Pindah/Keluar: 2 siswa\n";
        echo "\n";
        echo "🧪 Contoh NISN untuk testing:\n";
        echo "✅ AKTIF (DENGAN DATA PEMBAYARAN):  0051234567 (Andi - Lunas Jan-Feb)\n";
        echo "✅ AKTIF (TANPA DATA PEMBAYARAN):   0051234568 (Siti - Semua belum bayar)\n";
        echo "❌ LULUS:  0041234567 (Rudi Hermawan - Lulus 2024)\n";
        echo "❌ PINDAH: 0051234577 (Bambang Suryanto)\n";
        echo "❌ INVALID: 9999999999 (Tidak ada di database)\n";
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        echo "\n";
    }
}
