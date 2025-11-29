<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ValidStudent extends Model
{
    use HasFactory;

    protected $primaryKey = 'nisn';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'nisn',
        'nama',
        'kelas',
        'jurusan',
        'status_kelulusan',
        'is_registered',
        'tahun_lulus',
        'data_pembayaran',
    ];

    protected $casts = [
        'is_registered' => 'boolean',
        'tahun_lulus' => 'integer',
        'data_pembayaran' => 'array', // ✅ Auto cast JSON to array
    ];

    /**
     * Check if student is eligible for registration
     */
    public function isEligibleForRegistration(): bool
    {
        return $this->status_kelulusan === 'aktif' && !$this->is_registered;
    }

    /**
     * Mark as registered
     */
    public function markAsRegistered(): void
    {
        $this->update(['is_registered' => true]);
    }
}
