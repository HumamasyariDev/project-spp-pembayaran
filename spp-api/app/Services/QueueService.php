<?php

namespace App\Services;

use App\Models\Queue;
use App\Events\QueueStatusChanged;
use Carbon\Carbon;
use Illuminate\Support\Str;

class QueueService
{
    /**
     * Generate queue number
     */
    private function generateQueueNumber($serviceId = 1)
    {
        $date = Carbon::today()->format('Ymd');
        $lastQueue = Queue::where('service_id', $serviceId)
            ->whereDate('tanggal_antrian', Carbon::today())
            ->orderBy('id', 'desc')
            ->first();

        $number = $lastQueue ? intval(substr($lastQueue->nomor_antrian, -3)) + 1 : 1;
        return 'Q' . $date . str_pad($number, 3, '0', STR_PAD_LEFT);
    }

    /**
     * Generate unique QR code
     * Format: SHA256(uuid + timestamp + service_id + user_id)
     */
    private function generateUniqueQrCode($userId, $serviceId)
    {
        do {
            // Generate unique hash using UUID, timestamp, service, and user
            $uuid = Str::uuid()->toString();
            $timestamp = microtime(true);
            $randomString = Str::random(16);
            
            $qrCode = hash('sha256', $uuid . $timestamp . $serviceId . $userId . $randomString);
            
            // Check if QR code already exists in database
            $exists = Queue::where('qr_code', $qrCode)->exists();
        } while ($exists); // Loop until we get a unique code (extremely rare to loop)
        
        return $qrCode;
    }

    /**
     * Create new queue
     */
    public function createQueue($userId, $serviceId = 1)
    {
        // Check if user already has active queue for this service today
        $existingQueue = Queue::where('user_id', $userId)
            ->where('service_id', $serviceId)
            ->whereDate('tanggal_antrian', Carbon::today())
            ->whereIn('status', ['menunggu', 'dipanggil'])
            ->first();

        if ($existingQueue) {
            return [
                'success' => false,
                'message' => 'Anda sudah memiliki antrian aktif untuk layanan ini',
                'queue' => $existingQueue,
            ];
        }

        $queue = Queue::create([
            'user_id' => $userId,
            'service_id' => $serviceId,
            'nomor_antrian' => $this->generateQueueNumber($serviceId),
            'qr_code' => $this->generateUniqueQrCode($userId, $serviceId), // ✅ Generate unique QR code
            'tanggal_antrian' => Carbon::today(),
            'status' => 'menunggu',
        ]);

        return [
            'success' => true,
            'message' => 'Antrian berhasil dibuat',
            'queue' => $queue->load('user'),
        ];
    }

    /**
     * Get active queues
     */
    public function getActiveQueues()
    {
        return Queue::whereDate('tanggal_antrian', Carbon::today())
            ->whereIn('status', ['menunggu', 'dipanggil', 'dilayani'])
            ->with('user')
            ->orderBy('id', 'asc')
            ->get();
    }

    /**
     * Get user's queue history
     */
    public function getUserQueues($userId)
    {
        return Queue::where('user_id', $userId)
            ->with('user', 'calledBy')
            ->orderBy('queue_date', 'desc')
            ->get();
    }

    /**
     * Call next queue
     */
    public function callNextQueue($officerId)
    {
        $queue = Queue::whereDate('tanggal_antrian', Carbon::today())
            ->where('status', 'menunggu')
            ->orderBy('id', 'asc')
            ->first();

        if (!$queue) {
            return [
                'success' => false,
                'message' => 'Tidak ada antrian yang menunggu',
            ];
        }

        $queue->update([
            'status' => 'dipanggil',
            'dipanggil_oleh' => $officerId,
            'waktu_dipanggil' => now(),
        ]);

        // Broadcast event untuk notifikasi realtime
        // event(new QueueStatusChanged($queue->load('user'))); // Disabled for now

        return [
            'success' => true,
            'message' => 'Antrian berhasil dipanggil',
            'queue' => $queue,
        ];
    }

    /**
     * Mark queue as served
     */
    public function serveQueue($queueId)
    {
        $queue = Queue::findOrFail($queueId);
        
        $queue->update([
            'status' => 'dilayani',
            'waktu_dilayani' => now(),
        ]);

        // event(new QueueStatusChanged($queue->load('user'))); // Disabled for now

        return [
            'success' => true,
            'message' => 'Antrian sedang dilayani',
            'queue' => $queue,
        ];
    }

    /**
     * Complete queue
     */
    public function completeQueue($queueId)
    {
        $queue = Queue::findOrFail($queueId);
        
        $queue->update([
            'status' => 'selesai',
            'waktu_selesai' => now(),
        ]);

        // event(new QueueStatusChanged($queue->load('user'))); // Disabled for now

        return [
            'success' => true,
            'message' => 'Antrian selesai',
            'queue' => $queue,
        ];
    }

    /**
     * Cancel queue
     */
    public function cancelQueue($queueId)
    {
        $queue = Queue::findOrFail($queueId);
        
        $queue->update([
            'status' => 'dibatalkan',
        ]);

        // event(new QueueStatusChanged($queue->load('user'))); // Disabled for now

        return [
            'success' => true,
            'message' => 'Antrian dibatalkan',
            'queue' => $queue,
        ];
    }

    /**
     * Get today's queue statistics (for all services)
     * Returns array with service_id as key
     */
    public function getTodayStatistics()
    {
        $stats = [];
        
        // Get statistics for each service (1, 2, 3)
        for ($serviceId = 1; $serviceId <= 3; $serviceId++) {
            $totalQueues = Queue::where('service_id', $serviceId)
                ->whereDate('tanggal_antrian', Carbon::today())
                ->count();
                
            $servedQueues = Queue::where('service_id', $serviceId)
                ->whereDate('tanggal_antrian', Carbon::today())
                ->whereIn('status', ['dilayani', 'selesai'])
                ->count();
                
            $waitingQueues = Queue::where('service_id', $serviceId)
                ->whereDate('tanggal_antrian', Carbon::today())
                ->where('status', 'menunggu')
                ->count();
                
            $currentQueue = Queue::where('service_id', $serviceId)
                ->whereDate('tanggal_antrian', Carbon::today())
                ->where('status', 'dipanggil')
                ->value('nomor_antrian');
            
            // Extract number from nomor_antrian (e.g., Q20250107001 -> 1)
            $currentNumber = $currentQueue ? intval(substr($currentQueue, -3)) : 0;

            $stats[$serviceId] = [
                'current' => $currentNumber,
                'waiting' => $waitingQueues,
                'served' => $servedQueues,
                'total' => $totalQueues,
            ];
        }
        
        return $stats;
    }
}
