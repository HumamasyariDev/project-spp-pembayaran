<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
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
            'nomor_pembayaran' => $this->nomor_pembayaran,
            'jumlah' => (float) $this->jumlah,
            'metode_pembayaran' => $this->metode_pembayaran,
            'bukti_pembayaran' => $this->bukti_pembayaran ? url('storage/' . $this->bukti_pembayaran) : null,
            'status' => $this->status,
            'catatan' => $this->catatan,
            'waktu_verifikasi' => $this->waktu_verifikasi?->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss'),
            'spp_bill' => new SppBillResource($this->whenLoaded('sppBill')),
            'user' => new UserResource($this->whenLoaded('user')),
            'diverifikasi_oleh' => new UserResource($this->whenLoaded('verifiedBy')),
            'created_at' => $this->created_at?->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss'),
            'updated_at' => $this->updated_at?->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss'),
        ];
    }
}
