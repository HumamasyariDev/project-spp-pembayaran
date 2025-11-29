<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SppBillResource extends JsonResource
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
            'nomor_tagihan' => $this->nomor_tagihan,
            'bulan' => $this->bulan,
            'tahun' => $this->tahun,
            'jumlah' => (float) $this->jumlah,
            'status' => $this->status,
            'tanggal_jatuh_tempo' => $this->tanggal_jatuh_tempo?->locale('id')->isoFormat('DD MMMM YYYY'),
            'user' => new UserResource($this->whenLoaded('user')),
            'payments' => PaymentResource::collection($this->whenLoaded('payments')),
            'created_at' => $this->created_at?->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss'),
            'updated_at' => $this->updated_at?->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss'),
        ];
    }
}
