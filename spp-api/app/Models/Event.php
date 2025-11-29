<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'event_date',
        'event_time',
        'location',
        'image',
        'category', // ujian, olahraga, ekskul, lainnya
        'participants_count',
        'is_featured',
        'created_by',
    ];

    protected $casts = [
        'event_date' => 'date',
        'is_featured' => 'boolean',
        'participants_count' => 'integer',
    ];

    /**
     * Get the user who created the event
     */
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}

