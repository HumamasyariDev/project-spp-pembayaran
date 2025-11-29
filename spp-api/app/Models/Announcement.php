<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'image',
        'category', // libur, ekstrakurikuler, pengumuman_umum
        'is_important',
        'publish_date',
        'created_by',
    ];

    protected $casts = [
        'is_important' => 'boolean',
        'publish_date' => 'date',
    ];

    /**
     * Get the user who created the announcement
     */
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}

