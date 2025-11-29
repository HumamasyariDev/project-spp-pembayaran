<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Queue;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class QueueSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get all siswa using Spatie roles
        $students = User::role('siswa')->get();

        if ($students->isEmpty()) {
            $this->command->warn('⚠️  Tidak ada siswa di database. Jalankan UserSeeder terlebih dahulu.');
            return;
        }

        // Clear existing queues for today
        DB::table('queues')->whereDate('tanggal_antrian', Carbon::today())->delete();

        $this->command->info('🎯 Generating queue data...');

        // Generate 20 queues for today with various statuses
        $createdQueues = 0;

        foreach ($students->take(20) as $index => $student) {
            $queueNumber = 'Q' . Carbon::today()->format('Ymd') . str_pad($index + 1, 3, '0', STR_PAD_LEFT);
            
            // Distribute statuses realistically
            // Status: 'menunggu','dipanggil','dilayani','selesai','dibatalkan'
            $status = match (true) {
                $index < 3 => 'selesai',    // First 3 are completed
                $index < 5 => 'dilayani',   // Next 2 are being served
                $index < 7 => 'dipanggil',  // Next 2 are called
                default => 'menunggu',      // Rest are waiting
            };

            DB::table('queues')->insert([
                'user_id' => $student->id,
                'nomor_antrian' => $queueNumber,
                'tanggal_antrian' => Carbon::today(),
                'status' => $status,
                'dipanggil_oleh' => in_array($status, ['dipanggil', 'dilayani', 'selesai']) ? 1 : null,
                'waktu_dipanggil' => in_array($status, ['dipanggil', 'dilayani', 'selesai']) 
                    ? Carbon::today()->addHours(8)->addMinutes($index * 5) 
                    : null,
                'waktu_dilayani' => in_array($status, ['dilayani', 'selesai']) 
                    ? Carbon::today()->addHours(8)->addMinutes($index * 5 + 2) 
                    : null,
                'waktu_selesai' => $status === 'selesai' 
                    ? Carbon::today()->addHours(8)->addMinutes($index * 5 + 10) 
                    : null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $createdQueues++;
        }

        $this->command->info("✅ Created {$createdQueues} queue entries for today");
        $this->command->info('📊 Queue Statistics:');
        $this->command->info('   - Selesai: ' . DB::table('queues')->where('status', 'selesai')->count());
        $this->command->info('   - Dilayani: ' . DB::table('queues')->where('status', 'dilayani')->count());
        $this->command->info('   - Dipanggil: ' . DB::table('queues')->where('status', 'dipanggil')->count());
        $this->command->info('   - Menunggu: ' . DB::table('queues')->where('status', 'menunggu')->count());
    }
}
