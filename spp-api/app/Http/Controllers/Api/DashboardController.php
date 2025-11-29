<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Queue;
use App\Models\SppBill;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * Get dashboard statistics for authenticated user (Siswa)
     */
    public function stats(Request $request)
    {
        $user = Auth::user();

        try {
            // Get all bills (paid and unpaid) for home screen
            $allBills = DB::table('tagihan')
                ->where('user_id', $user->id)
                ->orderBy('tahun', 'asc')
                ->orderBy(DB::raw("FIELD(bulan, 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember')"))
                ->get();

            // Filter unpaid bills
            $unpaidBills = $allBills->where('status', 'unpaid');
            $totalUnpaid = $unpaidBills->sum('jumlah');
            $unpaidCount = $unpaidBills->count();

            // Get active queue today
            $activeQueue = null; // Queue feature not yet implemented
            
            // Get recent payments from tagihan
            $paidBills = $allBills->where('status', 'paid')
                ->sortByDesc('tanggal_bayar')
                ->take(3);

            // Payment stats
            $totalPaid = $allBills->where('status', 'paid')->sum('jumlah');
            $pendingPayments = 0; // No pending payments yet

            return response()->json([
                'status' => true,
                'message' => 'Dashboard stats retrieved successfully',
                'data' => [
                    'unpaid_bills' => [
                        'count' => $unpaidCount,
                        'total' => $totalUnpaid,
                        'bills' => $allBills->map(function ($bill) {
                            $terbayar = (float) ($bill->terbayar ?? 0);
                            $total = (float) $bill->jumlah;
                            
                            // Calculate remaining amount
                            if (in_array($bill->status, ['paid', 'lunas', 'verified'])) {
                                $remaining = 0;
                                $terbayar = $total; // Ensure terbayar equals total for paid bills
                            } else {
                                $remaining = $total - $terbayar;
                            }
                            
                            return [
                                'id' => $bill->id,
                                'bulan' => $bill->bulan,
                                'tahun' => $bill->tahun,
                                'jumlah' => (int) $bill->jumlah,
                                'terbayar' => (int) $terbayar,
                                'remaining' => (int) $remaining,
                                'status' => $bill->status === 'paid' || $bill->status === 'lunas' ? 'paid' : 
                                           ($bill->status === 'partial' ? 'partial' : $bill->status),
                                'jatuh_tempo' => $bill->jatuh_tempo,
                                'tanggal_bayar' => $bill->tanggal_bayar,
                                'metode_bayar' => $bill->metode_bayar,
                                'denda' => (int) ($bill->denda ?? 0),
                                'checked' => false, // For checkbox in mobile app
                            ];
                        })->values(), // Return ALL bills for display (both paid and unpaid)
                    ],
                    'active_queue' => $activeQueue,
                    'recent_payments' => $paidBills->map(function ($payment) {
                        $terbayar = (float) ($payment->terbayar ?? $payment->jumlah); // For paid bills, terbayar = jumlah
                        $total = (float) $payment->jumlah;
                        
                        return [
                            'id' => $payment->id,
                            'bulan' => $payment->bulan,
                            'jumlah' => (int) $payment->jumlah,
                            'terbayar' => (int) $terbayar,
                            'remaining' => 0, // Always 0 for paid bills
                            'status' => 'paid',
                            'metode_bayar' => $payment->metode_bayar,
                            'tanggal_bayar' => $payment->tanggal_bayar,
                        ];
                    })->values(),
                    'summary' => [
                        'total_paid' => $totalPaid,
                        'pending_payments' => $pendingPayments,
                        'unpaid_count' => $unpaidCount,
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve dashboard stats',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get dashboard statistics for Petugas/Admin
     */
    public function adminStats(Request $request)
    {
        try {
            // Today's queue stats - use try-catch for each to handle missing tables
            $todayQueues = 0;
            $activeQueues = 0;
            $completedToday = 0;
            
            try {
                $todayQueues = Queue::whereDate('created_at', today())->count();
                $activeQueues = Queue::whereIn('status', ['waiting', 'called', 'serving'])->count();
                $completedToday = Queue::whereDate('created_at', today())
                    ->where('status', 'completed')
                    ->count();
            } catch (\Exception $e) {
                // Queue table might not exist, use defaults
            }

            // Payment stats - use DB query for flexibility
            $pendingPayments = 0;
            $verifiedToday = 0;
            $totalCollectedToday = 0;
            
            try {
                $pendingPayments = DB::table('payments')->where('status', 'pending')->count();
                $verifiedToday = DB::table('payments')
                    ->whereDate('updated_at', today())
                    ->where('status', 'verified')
                    ->count();
                $totalCollectedToday = DB::table('payments')
                    ->whereDate('updated_at', today())
                    ->where('status', 'verified')
                    ->sum('amount') ?? 0;
            } catch (\Exception $e) {
                // Payments table might have different structure
            }

            // Unpaid bills stats - use tagihan table directly
            $totalUnpaidBills = 0;
            $overdueCount = 0;
            
            try {
                $totalUnpaidBills = DB::table('tagihan')->where('status', 'unpaid')->count();
                $overdueCount = DB::table('tagihan')
                    ->where('status', 'unpaid')
                    ->where('jatuh_tempo', '<', now())
                    ->count();
            } catch (\Exception $e) {
                // Use defaults if tagihan table doesn't exist
            }

            return response()->json([
                'status' => true,
                'message' => 'Admin dashboard stats retrieved successfully',
                'data' => [
                    'queues' => [
                        'today_total' => $todayQueues,
                        'active' => $activeQueues,
                        'completed_today' => $completedToday,
                    ],
                    'payments' => [
                        'pending' => $pendingPayments,
                        'verified_today' => $verifiedToday,
                        'collected_today' => $totalCollectedToday,
                    ],
                    'bills' => [
                        'unpaid_total' => $totalUnpaidBills,
                        'overdue' => $overdueCount,
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve admin dashboard stats',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

