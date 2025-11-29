<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            KelasJurusanSeeder::class, // Seed kelas & jurusan FIRST
            ValidStudentSeeder::class, // Seed valid students (NISN) BEFORE users
            UserSeeder::class,
            SppBillSeeder::class,
            TagihanHumamSeeder::class, // Tagihan khusus untuk humampro208@gmail.com
            EventSeeder::class,
            AnnouncementSeeder::class,
            BannerSeeder::class,
        ]);
    }
}
