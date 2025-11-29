<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\SppBill;
use App\Events\PaymentStatusChanged;
use Illuminate\Support\Facades\Storage;

class PaymentService
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Generate payment number
     */
    private function generatePaymentNumber()
    {
        $date = date('Ymd');
        $lastPayment = Payment::whereDate('created_at', today())->orderBy('id', 'desc')->first();
        $number = $lastPayment ? intval(substr($lastPayment->payment_number, -4)) + 1 : 1;
        return 'PAY' . $date . str_pad($number, 4, '0', STR_PAD_LEFT);
    }

    /**
     * Get user's SPP bills
     */
    public function getUserBills($userId)
    {
        return SppBill::where('user_id', $userId)
            ->with('payments')
            ->orderBy('year', 'desc')
            ->orderBy('month', 'desc')
            ->get();
    }

    /**
     * Get unpaid bills
     */
    public function getUnpaidBills($userId)
    {
        return SppBill::where('user_id', $userId)
            ->where('status', 'unpaid')
            ->orderBy('due_date', 'asc')
            ->get();
    }

    /**
     * Create payment
     */
    public function createPayment($billId, $userId, $data)
    {
        $bill = SppBill::findOrFail($billId);

        // Check if bill already paid
        if ($bill->status === 'paid') {
            return [
                'success' => false,
                'message' => 'Tagihan ini sudah dibayar',
            ];
        }

        // Handle proof image upload
        $proofImagePath = null;
        if (isset($data['proof_image'])) {
            $proofImagePath = $data['proof_image']->store('payment-proofs', 'public');
        }

        $payment = Payment::create([
            'spp_bill_id' => $billId,
            'user_id' => $userId,
            'payment_number' => $this->generatePaymentNumber(),
            'amount' => $data['amount'],
            'payment_method' => $data['payment_method'],
            'proof_image' => $proofImagePath,
            'status' => 'pending',
            'notes' => $data['notes'] ?? null,
        ]);

        // Update bill status to pending
        $bill->update(['status' => 'pending']);

        // Broadcast event
        event(new PaymentStatusChanged($payment->load('user', 'sppBill')));

        return [
            'success' => true,
            'message' => 'Pembayaran berhasil dibuat, menunggu verifikasi',
            'payment' => $payment,
        ];
    }

    /**
     * Get payment history
     */
    public function getPaymentHistory($userId)
    {
        return Payment::where('user_id', $userId)
            ->with('sppBill', 'verifiedBy')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * Get all payments (for admin/petugas)
     */
    public function getAllPayments($status = null)
    {
        $query = Payment::with('user', 'sppBill', 'verifiedBy');

        if ($status) {
            $query->where('status', $status);
        }

        return $query->orderBy('created_at', 'desc')->get();
    }

    /**
     * Verify payment
     */
    public function verifyPayment($paymentId, $officerId, $status, $notes = null)
    {
        $payment = Payment::findOrFail($paymentId);

        if ($payment->status !== 'pending') {
            return [
                'success' => false,
                'message' => 'Pembayaran ini sudah diverifikasi',
            ];
        }

        $payment->update([
            'status' => $status,
            'verified_by' => $officerId,
            'verified_at' => now(),
            'notes' => $notes,
        ]);

        // Update bill status
        if ($status === 'verified') {
            $payment->sppBill->update(['status' => 'paid']);
            
            // Send notification - Pembayaran diverifikasi
            $this->notificationService->notifyPayment(
                $payment->user,
                'Pembayaran Diverifikasi ✅',
                "Pembayaran SPP bulan {$payment->sppBill->month}/{$payment->sppBill->year} sebesar Rp " . number_format($payment->amount, 0, ',', '.') . " telah diverifikasi.",
                $payment->id,
                ['status' => 'verified']
            );
        } else {
            $payment->sppBill->update(['status' => 'unpaid']);
            
            // Send notification - Pembayaran ditolak
            $this->notificationService->notifyPayment(
                $payment->user,
                'Pembayaran Ditolak ❌',
                "Pembayaran SPP bulan {$payment->sppBill->month}/{$payment->sppBill->year} ditolak. Silakan upload ulang bukti pembayaran yang valid.",
                $payment->id,
                ['status' => 'rejected', 'notes' => $notes]
            );
        }

        // Broadcast event
        event(new PaymentStatusChanged($payment->load('user', 'sppBill')));

        return [
            'success' => true,
            'message' => $status === 'verified' ? 'Pembayaran berhasil diverifikasi' : 'Pembayaran ditolak',
            'payment' => $payment,
        ];
    }

    /**
     * Get payment detail
     */
    public function getPaymentDetail($paymentId)
    {
        return Payment::with('user', 'sppBill', 'verifiedBy')->findOrFail($paymentId);
    }
}
