<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'spp_bill_id',
        'user_id',
        'nomor_pembayaran',
        'jumlah',
        'metode_pembayaran',
        'bukti_pembayaran',
        'status',
        'diverifikasi_oleh',
        'waktu_verifikasi',
        'catatan',
    ];

    protected $casts = [
        'jumlah' => 'decimal:2',
        'waktu_verifikasi' => 'datetime',
    ];

    /**
     * Get the SPP bill for this payment.
     */
    public function sppBill()
    {
        return $this->belongsTo(SppBill::class);
    }

    /**
     * Get the user who made this payment.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the officer who verified this payment.
     */
    public function verifiedBy()
    {
        return $this->belongsTo(User::class, 'diverifikasi_oleh');
    }
}
