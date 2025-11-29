<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Announcement;
use Carbon\Carbon;

class AnnouncementSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $announcements = [
            [
                'title' => 'Pengumuman Libur Nasional',
                'content' => 'Sekolah akan libur pada tanggal 28-29 Maret 2025 dalam rangka Hari Raya Nyepi. Kegiatan belajar mengajar akan dilanjutkan kembali pada tanggal 30 Maret 2025.',
                'image' => null, // Using local assets
                'category' => 'libur',
                'is_important' => true,
                'publish_date' => Carbon::now()->subDays(2),
                'created_by' => 1,
            ],
            [
                'title' => 'Info Kegiatan Ekstrakurikuler',
                'content' => 'Pendaftaran kegiatan ekstrakurikuler semester genap telah dibuka. Tersedia berbagai pilihan: Pramuka, PMR, Basket, Futsal, Band, dan lainnya. Daftarkan dirimu di Gedung Olahraga.',
                'image' => null, // Using local assets
                'category' => 'ekstrakurikuler',
                'is_important' => false,
                'publish_date' => Carbon::now()->subDays(5),
                'created_by' => 1,
            ],
            [
                'title' => 'Jadwal Ujian Akhir Semester',
                'content' => 'Ujian Akhir Semester akan dilaksanakan mulai tanggal 15-25 April 2025. Jadwal lengkap dapat dilihat di papan pengumuman sekolah.',
                'image' => null, // Using local assets
                'category' => 'pengumuman_umum',
                'is_important' => true,
                'publish_date' => Carbon::now()->subDays(1),
                'created_by' => 1,
            ],
            [
                'title' => 'Penerimaan Siswa Baru 2025/2026',
                'content' => 'Pendaftaran siswa baru untuk tahun ajaran 2025/2026 akan dibuka mulai bulan Mei 2025. Info lengkap dapat diakses di website sekolah.',
                'image' => null, // Using local assets
                'category' => 'pengumuman_umum',
                'is_important' => false,
                'publish_date' => Carbon::now()->subDays(7),
                'created_by' => 1,
            ],
        ];

        foreach ($announcements as $announcement) {
            Announcement::create($announcement);
        }
    }
}

