<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SppBill extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'nomor_tagihan',
        'bulan',
        'tahun',
        'jumlah',
        'status',
        'tanggal_jatuh_tempo',
    ];

    protected $casts = [
        'jumlah' => 'decimal:2',
        'tanggal_jatuh_tempo' => 'date',
    ];

    /**
     * Get the user that owns the bill.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the payments for this bill.
     */
    public function payments()
    {
        return $this->hasMany(Payment::class);
    }
}
