<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\SppBill;
use Carbon\Carbon;

class SppBillSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get all students
        $students = User::role('siswa')->get();

        $months = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];

        $currentYear = date('Y');
        $amount = 500000; // Rp 500.000 per bulan

        foreach ($students as $student) {
            foreach ($months as $index => $month) {
                $monthNumber = $index + 1;
                $billNumber = 'SPP' . $currentYear . str_pad($monthNumber, 2, '0', STR_PAD_LEFT) . $student->nis;
                
                // Tentukan status (beberapa sudah dibayar, beberapa belum)
                $status = 'belum_dibayar';
                if ($monthNumber <= 8) {
                    $status = 'lunas'; // Januari - Agustus sudah dibayar
                } elseif ($monthNumber == 9) {
                    $status = 'menunggu_verifikasi'; // September pending
                }

                // Tanggal jatuh tempo adalah tanggal 10 setiap bulan
                $dueDate = Carbon::create($currentYear, $monthNumber, 10);

                SppBill::create([
                    'user_id' => $student->id,
                    'nomor_tagihan' => $billNumber,
                    'bulan' => $month,
                    'tahun' => $currentYear,
                    'jumlah' => $amount,
                    'status' => $status,
                    'tanggal_jatuh_tempo' => $dueDate,
                ]);
            }
        }

        echo "SPP Bills created successfully!\n";
        echo "Created 12 months of SPP bills for each student\n";
        echo "Amount: Rp 500.000 per month\n";
    }
}
