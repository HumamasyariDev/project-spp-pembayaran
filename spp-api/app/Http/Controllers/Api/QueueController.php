<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\QueueResource;
use App\Services\QueueService;
use Illuminate\Http\Request;

class QueueController extends Controller
{
    protected $queueService;

    public function __construct(QueueService $queueService)
    {
        $this->queueService = $queueService;
    }

    /**
     * Create new queue (untuk siswa)
     */
    public function create(Request $request)
    {
        try {
            $request->validate([
                'service_id' => 'required|integer|min:1|max:3'
            ]);
            
            $result = $this->queueService->createQueue(
                $request->user()->id,
                $request->service_id
            );

            return response()->json([
                'status' => $result['success'],
                'message' => $result['message'],
                'data' => new QueueResource($result['queue']),
            ], $result['success'] ? 201 : 400);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat membuat antrian',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get active queues (untuk petugas)
     */
    public function activeQueues()
    {
        try {
            $queues = $this->queueService->getActiveQueues();

            return response()->json([
                'status' => true,
                'message' => 'Data antrian aktif berhasil diambil',
                'data' => QueueResource::collection($queues),
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat mengambil data antrian',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get user's queue history (untuk siswa)
     */
    public function myQueues(Request $request)
    {
        try {
            $queues = $this->queueService->getUserQueues($request->user()->id);

            return response()->json([
                'status' => true,
                'message' => 'Data antrian berhasil diambil',
                'data' => QueueResource::collection($queues),
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat mengambil data antrian',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get user's active queue with real-time estimation
     */
    public function myActiveQueue(Request $request)
    {
        try {
            $userId = $request->user()->id;
            
            // Get ALL user's active queues today
            $activeQueues = \App\Models\Queue::where('user_id', $userId)
                ->whereDate('tanggal_antrian', now()->toDateString())
                ->whereIn('status', ['menunggu', 'dipanggil', 'dilayani'])
                ->with('user')
                ->orderBy('service_id', 'asc')
                ->get();

            if ($activeQueues->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'message' => 'Tidak ada antrian aktif',
                    'data' => [],
                ], 200);
            }

            // Service mapping
            $services = [
                1 => ['name' => 'Pembayaran SPP', 'color' => '#16A085', 'location' => 'Loket 1'],
                2 => ['name' => 'Pengambilan Dokumen', 'color' => '#3498DB', 'location' => 'Loket 2'],
                3 => ['name' => 'Konsultasi Akademik', 'color' => '#E67E22', 'location' => 'Ruang BK'],
            ];

            $queueData = [];
            
            foreach ($activeQueues as $activeQueue) {
                // Calculate actual queue position (excluding cancelled queues)
                // Count only active queues (menunggu, dipanggil, dilayani) created before this queue
                $myQueueNumber = \App\Models\Queue::where('service_id', $activeQueue->service_id)
                    ->whereDate('tanggal_antrian', now()->toDateString())
                    ->whereIn('status', ['menunggu', 'dipanggil', 'dilayani'])
                    ->where('id', '<=', $activeQueue->id)
                    ->count();

                // Get current serving queue for this service
                $currentServingQueue = \App\Models\Queue::where('service_id', $activeQueue->service_id)
                    ->whereDate('tanggal_antrian', now()->toDateString())
                    ->where('status', 'dilayani')
                    ->first();

                $currentNumber = 0;
                if ($currentServingQueue) {
                    // Calculate current serving number (excluding cancelled)
                    $currentNumber = \App\Models\Queue::where('service_id', $currentServingQueue->service_id)
                        ->whereDate('tanggal_antrian', now()->toDateString())
                        ->whereIn('status', ['menunggu', 'dipanggil', 'dilayani', 'selesai'])
                        ->where('id', '<=', $currentServingQueue->id)
                        ->count();
                }

                // Count queues ahead for this service (excluding cancelled)
                $queuesAhead = \App\Models\Queue::where('service_id', $activeQueue->service_id)
                    ->whereDate('tanggal_antrian', now()->toDateString())
                    ->whereIn('status', ['menunggu', 'dipanggil'])
                    ->where('id', '<', $activeQueue->id)
                    ->count();

                // Calculate estimated time
                $estimatedMinutes = $queuesAhead * 3;
                $estimatedTime = $this->formatEstimatedTime($estimatedMinutes);

                // Get statistics for this service
                $stats = \App\Models\Queue::where('service_id', $activeQueue->service_id)
                    ->whereDate('tanggal_antrian', now()->toDateString())
                    ->selectRaw('
                        COUNT(*) as total,
                        SUM(CASE WHEN status = "selesai" THEN 1 ELSE 0 END) as completed,
                        SUM(CASE WHEN status = "menunggu" THEN 1 ELSE 0 END) as waiting,
                        SUM(CASE WHEN status = "dilayani" THEN 1 ELSE 0 END) as serving
                    ')
                    ->first();

                $service = $services[$activeQueue->service_id] ?? $services[1];

                $queueData[] = [
                    'id' => $activeQueue->id,
                    'serviceId' => $activeQueue->service_id,
                    'queueNumber' => $activeQueue->nomor_antrian,
                    'queueNumberShort' => $myQueueNumber,
                    'qrCode' => $activeQueue->qr_code, // ✅ Added unique QR code
                    'status' => $activeQueue->status,
                    'serviceName' => $service['name'],
                    'serviceColor' => $service['color'],
                    'serviceLocation' => $service['location'],
                    'queueDate' => $activeQueue->tanggal_antrian,
                    'currentNumber' => $currentNumber,
                    'queuesAhead' => $queuesAhead,
                    'estimatedTime' => $estimatedTime,
                    'estimatedMinutes' => $estimatedMinutes,
                    'statistics' => [
                        'total' => $stats->total ?? 0,
                        'completed' => $stats->completed ?? 0,
                        'waiting' => $stats->waiting ?? 0,
                        'serving' => $stats->serving ?? 0,
                    ],
                    'user' => [
                        'id' => $activeQueue->user->id,
                        'name' => $activeQueue->user->name,
                        'nis' => $activeQueue->user->nis ?? '-',
                        'nisn' => $activeQueue->user->nisn ?? '-', // ✅ Add NISN field
                        'class' => $activeQueue->user->kelas ?? '-',
                    ],
                    'createdAt' => $activeQueue->created_at->format('H:i'),
                ];
            }

            return response()->json([
                'success' => true,
                'message' => 'Data antrian aktif berhasil diambil',
                'data' => $queueData,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan saat mengambil data antrian',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Format estimated time
     */
    private function formatEstimatedTime($minutes)
    {
        if ($minutes == 0) {
            return 'Siap dilayani';
        } elseif ($minutes < 60) {
            return $minutes . ' menit';
        } else {
            $hours = floor($minutes / 60);
            $remainingMinutes = $minutes % 60;
            if ($remainingMinutes == 0) {
                return $hours . ' jam';
            } else {
                return $hours . ' jam ' . $remainingMinutes . ' menit';
            }
        }
    }

    /**
     * Scan QR Code to find queue
     */
    public function scanQr(Request $request)
    {
        try {
            $request->validate([
                'qr_code' => 'required|string',
            ]);

            $queue = \App\Models\Queue::where('qr_code', $request->qr_code)
                ->whereDate('tanggal_antrian', now()->toDateString()) // Only today's queues
                ->with('user')
                ->first();

            if (!$queue) {
                return response()->json([
                    'status' => false,
                    'message' => 'Antrian tidak ditemukan atau sudah kadaluarsa',
                ], 404);
            }

            // Get unpaid/pending/partial bills for this user
            $bills = \Illuminate\Support\Facades\DB::table('tagihan')
                ->where('user_id', $queue->user_id)
                ->whereIn('status', ['unpaid', 'pending', 'failed', 'partial'])
                ->select('id', 'bulan', 'tahun', 'jumlah', 'status', 'terbayar')
                ->orderBy('tahun', 'asc')
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Antrian ditemukan',
                'data' => new QueueResource($queue),
                'bills' => $bills
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat scan QR',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Call next queue (untuk petugas)
     */
    public function callNext(Request $request)
    {
        try {
            $result = $this->queueService->callNextQueue($request->user()->id);

            return response()->json([
                'status' => $result['success'],
                'message' => $result['message'],
                'data' => isset($result['queue']) ? new QueueResource($result['queue']) : null,
            ], $result['success'] ? 200 : 404);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat memanggil antrian',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mark queue as served (untuk petugas)
     */
    public function serve($id)
    {
        try {
            $result = $this->queueService->serveQueue($id);

            return response()->json([
                'status' => $result['success'],
                'message' => $result['message'],
                'data' => new QueueResource($result['queue']),
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Complete queue (untuk petugas)
     */
    public function complete($id)
    {
        try {
            $result = $this->queueService->completeQueue($id);

            return response()->json([
                'status' => $result['success'],
                'message' => $result['message'],
                'data' => new QueueResource($result['queue']),
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Cancel queue (untuk siswa atau petugas)
     */
    public function cancel($id)
    {
        try {
            $result = $this->queueService->cancelQueue($id);

            return response()->json([
                'success' => $result['success'],
                'message' => $result['message'],
            ], 200);
        } catch (\Exception $e) {
            \Log::error('Cancel Queue Error: ' . $e->getMessage(), [
                'queue_id' => $id,
                'trace' => $e->getTraceAsString(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get available services with queue statistics
     */
    public function services()
    {
        try {
            $services = [
                [
                    'id' => 1,
                    'name' => 'Pembayaran SPP',
                    'description' => 'Bayar SPP bulanan & tahunan',
                    'icon' => 'account_balance_wallet_outlined',
                    'color' => '#16A085',
                    'location' => 'Loket 1',
                ],
                [
                    'id' => 2,
                    'name' => 'Pengambilan Dokumen',
                    'description' => 'Ijazah, transkrip, surat keterangan',
                    'icon' => 'description_outlined',
                    'color' => '#3498DB',
                    'location' => 'Loket 2',
                ],
                [
                    'id' => 3,
                    'name' => 'Konsultasi Akademik',
                    'description' => 'Konsultasi dengan staff akademik',
                    'icon' => 'school_outlined',
                    'color' => '#E67E22',
                    'location' => 'Ruang BK',
                ],
            ];

            // Get queue statistics for today
            $stats = $this->queueService->getTodayStatistics();

            // Merge services with statistics
            $servicesWithStats = array_map(function ($service) use ($stats) {
                $serviceStats = $stats[$service['id']] ?? [
                    'current' => 0,
                    'waiting' => 0,
                    'served' => 0,
                    'total' => 0,
                ];

                return array_merge($service, [
                    'current' => $serviceStats['current'],
                    'waiting' => $serviceStats['waiting'],
                    'served' => $serviceStats['served'],
                    'total' => $serviceStats['total'],
                    'estimatedTime' => $this->calculateEstimatedTime($serviceStats['waiting']),
                ]);
            }, $services);

            return response()->json([
                'status' => true,
                'message' => 'Data layanan berhasil diambil',
                'data' => $servicesWithStats,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat mengambil data layanan',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Calculate estimated waiting time based on queue count
     */
    private function calculateEstimatedTime($waitingCount)
    {
        if ($waitingCount == 0) return '0 menit';
        
        // Assume 3 minutes per person
        $minutes = $waitingCount * 3;
        
        if ($minutes < 60) {
            return $minutes . ' menit';
        } else {
            $hours = floor($minutes / 60);
            $remainingMinutes = $minutes % 60;
            return $hours . ' jam ' . $remainingMinutes . ' menit';
        }
    }
}
