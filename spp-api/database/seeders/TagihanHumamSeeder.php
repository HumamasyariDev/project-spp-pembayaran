<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class TagihanHumamSeeder extends Seeder
{
    /**
     * Seed tagihan untuk humampro208@gmail.com
     * - Januari - Oktober 2025: LUNAS
     * - November 2025: BELUM BAYAR (Tunggakan)
     */
    public function run(): void
    {
        $user = User::where('email', 'humampro208@gmail.com')->first();

        // Create user if not exists
        if (!$user) {
            $this->command->warn('User humampro208@gmail.com tidak ditemukan! Creating user...');
            
                $user = User::create([
                    'name' => 'Humam',
                    'email' => 'humampro208@gmail.com',
                    'password' => bcrypt('humam123'),
                    'nis' => '2025' . rand(1000, 9999),
                    'nisn' => '0025' . rand(100000, 999999),
                    'kelas' => 'XII',
                    'jurusan' => 'RPL', // Rekayasa Perangkat Lunak
                    'telepon' => '081234567890',
                    'alamat' => 'Jakarta',
                    'jenis_kelamin' => 'L',
                ]);
            
            // Assign role siswa
            $user->assignRole('siswa');
            
            $this->command->info("✅ User created: {$user->name} (ID: {$user->id})");
        }

        $this->command->info("Creating tagihan for {$user->name} (ID: {$user->id})");

        // Data bulan dan status
        $tagihan = [
            // LUNAS (Januari - Oktober 2025)
            [
                'user_id' => $user->id,
                'bulan' => 'Januari',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-01-10',
                'tanggal_bayar' => '2025-01-08 10:30:00',
                'metode_bayar' => 'BCA Virtual Account',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'Februari',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-02-10',
                'tanggal_bayar' => '2025-02-09 14:15:00',
                'metode_bayar' => 'Gopay',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'Maret',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-03-10',
                'tanggal_bayar' => '2025-03-07 09:45:00',
                'metode_bayar' => 'BNI Virtual Account',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'April',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-04-10',
                'tanggal_bayar' => '2025-04-05 16:20:00',
                'metode_bayar' => 'Mandiri Virtual Account',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'Mei',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-05-10',
                'tanggal_bayar' => '2025-05-06 11:00:00',
                'metode_bayar' => 'ShopeePay',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'Juni',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-06-10',
                'tanggal_bayar' => '2025-06-08 13:30:00',
                'metode_bayar' => 'BCA Virtual Account',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'Juli',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-07-10',
                'tanggal_bayar' => '2025-07-09 15:45:00',
                'metode_bayar' => 'Gopay',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'Agustus',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-08-10',
                'tanggal_bayar' => '2025-08-07 08:20:00',
                'metode_bayar' => 'BNI Virtual Account',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'September',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-09-10',
                'tanggal_bayar' => '2025-09-08 12:10:00',
                'metode_bayar' => 'Mandiri Virtual Account',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            [
                'user_id' => $user->id,
                'bulan' => 'Oktober',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'paid',
                'jatuh_tempo' => '2025-10-10',
                'tanggal_bayar' => '2025-10-09 17:00:00',
                'metode_bayar' => 'Gopay',
                'denda' => 0,
                'catatan' => 'Pembayaran tepat waktu',
            ],
            // BELUM BAYAR (November 2025 - TUNGGAKAN)
            [
                'user_id' => $user->id,
                'bulan' => 'November',
                'tahun' => 2025,
                'jumlah' => 500000,
                'status' => 'unpaid',
                'jatuh_tempo' => '2025-11-10',
                'tanggal_bayar' => null,
                'metode_bayar' => null,
                'denda' => 0, // Belum kena denda karena masih dalam masa tenggang
                'catatan' => 'Belum dibayar',
            ],
        ];

        // Insert ke database
        foreach ($tagihan as $item) {
            DB::table('tagihan')->insert([
                'user_id' => $item['user_id'],
                'bulan' => $item['bulan'],
                'tahun' => $item['tahun'],
                'jumlah' => $item['jumlah'],
                'status' => $item['status'],
                'jatuh_tempo' => $item['jatuh_tempo'],
                'tanggal_bayar' => $item['tanggal_bayar'],
                'metode_bayar' => $item['metode_bayar'],
                'denda' => $item['denda'],
                'catatan' => $item['catatan'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            if ($item['status'] === 'paid') {
                $this->command->info("✅ {$item['bulan']}: LUNAS (Rp " . number_format($item['jumlah'], 0, ',', '.') . ")");
            } else {
                $this->command->error("❌ {$item['bulan']}: BELUM BAYAR (Rp " . number_format($item['jumlah'], 0, ',', '.') . ")");
            }
        }

        $this->command->info('');
        $this->command->info('📊 RINGKASAN:');
        $this->command->info('✅ Lunas: 10 bulan (Januari - Oktober 2025) = Rp 5.000.000');
        $this->command->error('❌ Tunggakan: 1 bulan (November 2025) = Rp 500.000');
        $this->command->info('');
        $this->command->info('✅ Seeder berhasil dijalankan!');
    }
}

