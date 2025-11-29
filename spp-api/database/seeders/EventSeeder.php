<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Event;
use Carbon\Carbon;

class EventSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $events = [
            [
                'title' => 'Ujian Tengah Semester',
                'description' => 'Ujian Tengah Semester untuk semua kelas. Mohon datang tepat waktu dan membawa alat tulis lengkap.',
                'event_date' => Carbon::now()->addDays(7),
                'event_time' => '07:30',
                'location' => 'Ruang Kelas 12A, Gedung Utama',
                'image' => null, // Using local assets
                'category' => 'ujian',
                'participants_count' => 120,
                'is_featured' => true,
                'created_by' => 1, // Admin user
            ],
            [
                'title' => 'Pembayaran SPP Maret',
                'description' => 'Batas waktu pembayaran SPP untuk bulan Maret 2025. Silakan lakukan pembayaran di Kantor Tata Usaha.',
                'event_date' => Carbon::now()->addDays(13),
                'event_time' => '08:00',
                'location' => 'Kantor Tata Usaha',
                'image' => null, // Using local assets
                'category' => 'lainnya',
                'participants_count' => 85,
                'is_featured' => false,
                'created_by' => 1,
            ],
            [
                'title' => 'Lomba Olahraga Antar Kelas',
                'description' => 'Kompetisi olahraga antar kelas. Futsal, basket, dan voli. Daftarkan tim kelasmu segera!',
                'event_date' => Carbon::now()->addDays(20),
                'event_time' => '13:00',
                'location' => 'Lapangan Olahraga',
                'image' => null, // Using local assets
                'category' => 'olahraga',
                'participants_count' => 250,
                'is_featured' => true,
                'created_by' => 1,
            ],
            [
                'title' => 'Workshop Teknologi',
                'description' => 'Workshop tentang pengembangan web dan mobile app untuk siswa yang berminat.',
                'event_date' => Carbon::now()->addDays(15),
                'event_time' => '14:00',
                'location' => 'Lab Komputer Lantai 2',
                'image' => null, // Using local assets
                'category' => 'ekskul',
                'participants_count' => 40,
                'is_featured' => false,
                'created_by' => 1,
            ],
        ];

        foreach ($events as $event) {
            Event::create($event);
        }
    }
}

