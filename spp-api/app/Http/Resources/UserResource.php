<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
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
            'name' => $this->name,
            'email' => $this->email,
            'nis' => $this->nis,
            'nisn' => $this->nisn,
            'telepon' => $this->telepon,
            'alamat' => $this->alamat,
            'kelas' => $this->kelas,
            'jurusan' => $this->jurusan,
            'jenis_kelamin' => $this->jenis_kelamin,
            'roles' => $this->whenLoaded('roles', function () {
                return $this->roles->pluck('name');
            }),
            'created_at' => $this->created_at?->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss'),
            'updated_at' => $this->updated_at?->locale('id')->isoFormat('DD MMMM YYYY, HH:mm:ss'),
        ];
    }
}
