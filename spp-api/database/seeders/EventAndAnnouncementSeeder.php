<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Event;
use App\Models\Announcement;
use App\Models\User;
use Carbon\Carbon;

class EventAndAnnouncementSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get admin user for created_by
        $admin = User::role('admin')->first();
        $adminId = $admin ? $admin->id : 1;

        // Clear existing data
        Event::truncate();
        Announcement::truncate();

        // ===================== EVENTS =====================
        
        $events = [
            // Ujian
            [
                'title' => 'Ujian Akhir Semester Gasal',
                'description' => 'Ujian Akhir Semester Gasal untuk tahun ajaran 2025/2026. Persiapkan diri dengan baik!',
                'date' => '2025-12-01',
                'time' => '08:00:00',
                'location' => 'Gedung A & B',
                'category' => 'ujian',
                'participants_count' => 500,
                'is_featured' => true,
                'image' => null, // Will use default
            ],
            [
                'title' => 'Ujian Praktik Kejuruan RPL',
                'description' => 'Ujian praktik untuk siswa kelas XII jurusan Rekayasa Perangkat Lunak.',
                'date' => '2025-11-25',
                'time' => '09:30:00',
                'location' => 'Lab Komputer RPL',
                'category' => 'ujian',
                'participants_count' => 80,
                'is_featured' => false,
                'image' => null,
            ],

            // Olahraga
            [
                'title' => 'Class Meeting: Turnamen Futsal',
                'description' => 'Turnamen futsal antar kelas dalam rangka class meeting akhir semester.',
                'date' => '2025-12-10',
                'time' => '10:00:00',
                'location' => 'Lapangan Olahraga Sekolah',
                'category' => 'olahraga',
                'participants_count' => 200,
                'is_featured' => true,
                'image' => null,
            ],
            [
                'title' => 'Seleksi Atlet O2SN Cabor Atletik',
                'description' => 'Seleksi siswa untuk Olimpiade Olahraga Siswa Nasional cabang atletik.',
                'date' => '2026-01-15',
                'time' => '07:30:00',
                'location' => 'Stadion Mini',
                'category' => 'olahraga',
                'participants_count' => 150,
                'is_featured' => false,
                'image' => null,
            ],

            // Ekskul
            [
                'title' => 'Pentas Seni Eskul Musik',
                'description' => 'Pentas seni dan unjuk kebolehan dari anggota ekstrakurikuler musik.',
                'date' => '2025-11-29',
                'time' => '19:00:00',
                'location' => 'Aula Sekolah',
                'category' => 'ekskul',
                'participants_count' => 300,
                'is_featured' => true,
                'image' => null,
            ],
            [
                'title' => 'Latihan Gabungan Paskibra',
                'description' => 'Latihan gabungan bersama sekolah lain untuk persiapan upacara hari besar.',
                'date' => '2026-02-05',
                'time' => '14:00:00',
                'location' => 'Lapangan Utama',
                'category' => 'ekskul',
                'participants_count' => 120,
                'is_featured' => false,
                'image' => null,
            ],
        ];

        foreach ($events as $eventData) {
            Event::create([
                'title' => $eventData['title'],
                'description' => $eventData['description'],
                'event_date' => $eventData['date'],
                'event_time' => $eventData['time'],
                'location' => $eventData['location'],
                'category' => $eventData['category'],
                'participants_count' => $eventData['participants_count'],
                'is_featured' => $eventData['is_featured'],
                'image' => $eventData['image'],
                'created_by' => $adminId,
            ]);
        }

        // ===================== ANNOUNCEMENTS =====================

        // Pengumuman Penting
        Announcement::create([
            'title' => 'Perubahan Jadwal Ujian Tengah Semester',
            'content' => 'Diinformasikan kepada seluruh siswa bahwa jadwal Ujian Tengah Semester mengalami perubahan. Ujian dimajukan 2 hari dari jadwal sebelumnya. Silakan cek jadwal terbaru di website sekolah atau pengumuman di mading.',
            'category' => 'pengumuman_umum',
            'is_important' => true,
            'publish_date' => Carbon::now(),
            'created_by' => $adminId,
        ]);

        Announcement::create([
            'title' => 'Wajib Bayar SPP Sebelum 10 Desember',
            'content' => 'Kepada seluruh siswa yang belum melunasi pembayaran SPP bulan ini, dimohon untuk segera melakukan pembayaran paling lambat tanggal 10 Desember 2024. Keterlambatan akan dikenakan denda sesuai ketentuan.',
            'category' => 'pengumuman_umum',
            'is_important' => true,
            'publish_date' => Carbon::now()->subDays(1),
            'created_by' => $adminId,
        ]);

        Announcement::create([
            'title' => 'Pengumpulan Berkas Prakerin',
            'content' => 'Siswa kelas XI yang akan mengikuti Praktek Kerja Industri (Prakerin) semester depan wajib mengumpulkan berkas pendaftaran ke guru pembimbing masing-masing jurusan paling lambat 20 November 2024.',
            'category' => 'pengumuman_umum',
            'is_important' => true,
            'publish_date' => Carbon::now()->subDays(2),
            'created_by' => $adminId,
        ]);

        // Pengumuman Umum
        Announcement::create([
            'title' => 'Pembagian Raport Semester Ganjil',
            'content' => 'Pembagian raport semester ganjil akan dilaksanakan pada tanggal 20 Desember 2024. Orang tua/wali murid diharapkan hadir untuk mengambil raport dan konsultasi dengan wali kelas.',
            'category' => 'pengumuman_umum',
            'is_important' => false,
            'publish_date' => Carbon::now()->subDays(3),
            'created_by' => $adminId,
        ]);

        Announcement::create([
            'title' => 'Workshop Persiapan SBMPTN',
            'content' => 'Sekolah mengadakan workshop gratis persiapan SBMPTN untuk siswa kelas XII. Akan dibimbing oleh alumni yang telah diterima di PTN favorit. Pendaftaran dibuka mulai sekarang.',
            'category' => 'pengumuman_umum',
            'is_important' => false,
            'publish_date' => Carbon::now()->subDays(4),
            'created_by' => $adminId,
        ]);

        Announcement::create([
            'title' => 'Jadwal Bimbingan Belajar Tambahan',
            'content' => 'Bimbingan belajar tambahan untuk mata pelajaran Matematika, Fisika, dan Kimia akan dimulai minggu depan. Jadwal lengkap dapat dilihat di papan pengumuman atau website sekolah.',
            'category' => 'pengumuman_umum',
            'is_important' => false,
            'publish_date' => Carbon::now()->subDays(5),
            'created_by' => $adminId,
        ]);

        // Libur
        Announcement::create([
            'title' => 'Libur Nasional Hari Guru',
            'content' => 'Sehubungan dengan peringatan Hari Guru Nasional, sekolah diliburkan pada tanggal 25 November 2024. Kegiatan belajar mengajar akan kembali normal pada hari berikutnya.',
            'category' => 'libur',
            'is_important' => false,
            'publish_date' => Carbon::now()->subDays(1),
            'created_by' => $adminId,
        ]);

        // Ekstrakurikuler
        Announcement::create([
            'title' => 'Pendaftaran Ekstrakurikuler Semester Baru',
            'content' => 'Dibuka pendaftaran ekstrakurikuler untuk semester baru. Pilihan ekskul: Basket, Futsal, Pramuka, Musik, Teater, dan Fotografi. Daftar di ruang OSIS!',
            'category' => 'ekstrakurikuler',
            'is_important' => false,
            'publish_date' => Carbon::now()->subDays(6),
            'created_by' => $adminId,
        ]);

        Announcement::create([
            'title' => 'Pelatihan Kepemimpinan OSIS',
            'content' => 'OSIS mengadakan pelatihan kepemimpinan untuk seluruh anggota OSIS dan MPK. Acara akan dilaksanakan di Aula pada hari Sabtu, 20 November 2024.',
            'category' => 'ekstrakurikuler',
            'is_important' => false,
            'publish_date' => Carbon::now()->subDays(7),
            'created_by' => $adminId,
        ]);

        Announcement::create([
            'title' => 'Peminjaman Buku Perpustakaan',
            'content' => 'Perpustakaan sekolah telah menambah koleksi buku baru. Siswa dapat meminjam maksimal 3 buku untuk jangka waktu 2 minggu. Jangan lupa mengembalikan tepat waktu ya!',
            'category' => 'pengumuman_umum',
            'is_important' => false,
            'publish_date' => Carbon::now()->subDays(8),
            'created_by' => $adminId,
        ]);

        $this->command->info('✅ Events and Announcements seeded successfully!');
        $this->command->info('📊 Total Events: ' . Event::count());
        $this->command->info('📊 Total Announcements: ' . Announcement::count());
    }
}

