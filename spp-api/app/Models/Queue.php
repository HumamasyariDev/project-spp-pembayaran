<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Queue extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'service_id',
        'nomor_antrian',
        'qr_code', // ✅ Added qr_code to fillable
        'status',
        'tanggal_antrian',
        'dipanggil_oleh',
        'waktu_dipanggil',
        'waktu_dilayani',
        'waktu_selesai',
    ];

    protected $casts = [
        'tanggal_antrian' => 'date',
        'waktu_dipanggil' => 'datetime',
        'waktu_dilayani' => 'datetime',
        'waktu_selesai' => 'datetime',
    ];

    /**
     * Get the user that owns the queue.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the officer who called this queue.
     */
    public function calledBy()
    {
        return $this->belongsTo(User::class, 'dipanggil_oleh');
    }
}
