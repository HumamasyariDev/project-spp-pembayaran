<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QueueResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'service_id' => $this->service_id,
            'nomor_antrian' => $this->nomor_antrian,
            'qr_code' => $this->qr_code, // ✅ Added qr_code for unique QR generation
            'status' => $this->status,
            'tanggal_antrian' => $this->tanggal_antrian ? $this->tanggal_antrian->locale('id')->isoFormat('DD MMMM YYYY') : null,
            'user' => new UserResource($this->whenLoaded('user')),
            'dipanggil_oleh' => new UserResource($this->whenLoaded('calledBy')),
            'waktu_dipanggil' => $this->waktu_dipanggil ? $this->waktu_dipanggil->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss') : null,
            'waktu_dilayani' => $this->waktu_dilayani ? $this->waktu_dilayani->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss') : null,
            'waktu_selesai' => $this->waktu_selesai ? $this->waktu_selesai->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss') : null,
            'created_at' => $this->created_at ? $this->created_at->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss') : null,
            'updated_at' => $this->updated_at ? $this->updated_at->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss') : null,
        ];
    }
}
