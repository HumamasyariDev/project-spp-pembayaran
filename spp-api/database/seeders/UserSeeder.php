<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create Admin
        $admin = User::create([
            'name' => 'Administrator',
            'email' => 'admin@spp.com',
            'password' => Hash::make('password'),
        ]);
        $admin->assignRole('admin');

        // Create Petugas
        $petugas1 = User::create([
            'name' => 'Petugas SPP 1',
            'email' => 'petugas1@spp.com',
            'password' => Hash::make('password'),
        ]);
        $petugas1->assignRole('petugas');

        $petugas2 = User::create([
            'name' => 'Petugas SPP 2',
            'email' => 'petugas2@spp.com',
            'password' => Hash::make('password'),
        ]);
        $petugas2->assignRole('petugas');

        // Create Siswa dengan kelas dan jurusan terpisah
        $students = [
            // Kelas XII (Tingkat 12) - SMK
            [
                'name' => 'Budi Santoso',
                'email' => 'budi@siswa.com',
                'nis' => '12345001',
                'nisn' => '0012345001',
                'telepon' => '081234567001',
                'alamat' => 'Jl. Merdeka No. 1, Jakarta',
                'kelas' => 'XII',
                'jurusan' => 'RPL', // Rekayasa Perangkat Lunak
                'jenis_kelamin' => 'L',
            ],
            [
                'name' => 'Siti Nurhaliza',
                'email' => 'siti@siswa.com',
                'nis' => '12345002',
                'nisn' => '0012345002',
                'telepon' => '081234567002',
                'alamat' => 'Jl. Merdeka No. 2, Jakarta',
                'kelas' => 'XII',
                'jurusan' => 'RPL', // Rekayasa Perangkat Lunak
                'jenis_kelamin' => 'P',
            ],
            [
                'name' => 'Ahmad Fauzi',
                'email' => 'ahmad@siswa.com',
                'nis' => '12345003',
                'nisn' => '0012345003',
                'telepon' => '081234567003',
                'alamat' => 'Jl. Sudirman No. 3, Jakarta',
                'kelas' => 'XII',
                'jurusan' => 'TKJ', // Teknik Komputer Jaringan
                'jenis_kelamin' => 'L',
            ],
            [
                'name' => 'Dewi Lestari',
                'email' => 'dewi@siswa.com',
                'nis' => '12345004',
                'nisn' => '0012345004',
                'telepon' => '081234567004',
                'alamat' => 'Jl. Thamrin No. 4, Jakarta',
                'kelas' => 'XII',
                'jurusan' => 'TKJ', // Teknik Komputer Jaringan
                'jenis_kelamin' => 'P',
            ],
            [
                'name' => 'Rizky Pratama',
                'email' => 'rizky@siswa.com',
                'nis' => '12345005',
                'nisn' => '0012345005',
                'telepon' => '081234567005',
                'alamat' => 'Jl. Gatot Subroto No. 5, Jakarta',
                'kelas' => 'XII',
                'jurusan' => 'TKR', // Teknik Kendaraan Ringan
                'jenis_kelamin' => 'L',
            ],
            // Kelas XI (Tingkat 11) - SMK
            [
                'name' => 'Andi Wijaya',
                'email' => 'andi@siswa.com',
                'nis' => '12345006',
                'nisn' => '0012345006',
                'telepon' => '081234567006',
                'alamat' => 'Jl. Asia Afrika No. 6, Jakarta',
                'kelas' => 'XI',
                'jurusan' => 'TPM', // Teknik Pemesinan
                'jenis_kelamin' => 'L',
            ],
            [
                'name' => 'Rina Kusuma',
                'email' => 'rina@siswa.com',
                'nis' => '12345007',
                'nisn' => '0012345007',
                'telepon' => '081234567007',
                'alamat' => 'Jl. Pahlawan No. 7, Jakarta',
                'kelas' => 'XI',
                'jurusan' => 'LAS', // Teknik Pengelasan
                'jenis_kelamin' => 'P',
            ],
            [
                'name' => 'Fahmi Ramadhan',
                'email' => 'fahmi@siswa.com',
                'nis' => '12345008',
                'nisn' => '0012345008',
                'telepon' => '081234567008',
                'alamat' => 'Jl. Diponegoro No. 8, Jakarta',
                'kelas' => 'XI',
                'jurusan' => 'LISTRIK', // Teknik Instalasi Tenaga Listrik
                'jenis_kelamin' => 'L',
            ],
            // Kelas X (Tingkat 10) - SMK
            [
                'name' => 'Maya Sari',
                'email' => 'maya@siswa.com',
                'nis' => '12345009',
                'nisn' => '0012345009',
                'telepon' => '081234567009',
                'alamat' => 'Jl. Imam Bonjol No. 9, Jakarta',
                'kelas' => 'X',
                'jurusan' => 'RPL', // Rekayasa Perangkat Lunak
                'jenis_kelamin' => 'P',
            ],
            [
                'name' => 'Dimas Aditya',
                'email' => 'dimas@siswa.com',
                'nis' => '12345010',
                'nisn' => '0012345010',
                'telepon' => '081234567010',
                'alamat' => 'Jl. Veteran No. 10, Jakarta',
                'kelas' => 'X',
                'jurusan' => 'TKJ', // Teknik Komputer Jaringan
                'jenis_kelamin' => 'L',
            ],
        ];

        foreach ($students as $studentData) {
            $student = User::create([
                'name' => $studentData['name'],
                'email' => $studentData['email'],
                'password' => Hash::make('password'),
                'nis' => $studentData['nis'],
                'nisn' => $studentData['nisn'],
                'telepon' => $studentData['telepon'],
                'alamat' => $studentData['alamat'],
                'kelas' => $studentData['kelas'],
                'jurusan' => $studentData['jurusan'],
                'jenis_kelamin' => $studentData['jenis_kelamin'],
            ]);
            $student->assignRole('siswa');
        }

        echo "Users created successfully!\n";
        echo "Admin: admin@spp.com / password\n";
        echo "Petugas: petugas1@spp.com / password\n";
        echo "Siswa: budi@siswa.com / password (dan siswa lainnya)\n";
    }
}
