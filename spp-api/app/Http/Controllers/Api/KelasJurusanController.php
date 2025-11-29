<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kelas;
use App\Models\Jurusan;
use Illuminate\Http\Request;

class KelasJurusanController extends Controller
{
    /**
     * Get list of active kelas
     */
    public function getKelas()
    {
        try {
            $kelas = Kelas::where('aktif', true)
                ->orderBy('nama')
                ->get(['id', 'nama', 'keterangan']);

            return response()->json([
                'status' => true,
                'message' => 'Data kelas berhasil diambil',
                'data' => $kelas,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil data kelas',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get list of active jurusan
     */
    public function getJurusan()
    {
        try {
            $jurusan = Jurusan::where('aktif', true)
                ->orderBy('kode')
                ->get(['id', 'kode', 'nama', 'deskripsi']);

            return response()->json([
                'status' => true,
                'message' => 'Data jurusan berhasil diambil',
                'data' => $jurusan,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil data jurusan',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Create new Kelas
     */
    public function storeKelas(Request $request)
    {
        $request->validate([
            'nama' => 'required|string|unique:kelas,nama',
            'keterangan' => 'nullable|string',
        ]);

        $kelas = Kelas::create([
            'nama' => $request->nama,
            'keterangan' => $request->keterangan,
            'aktif' => true
        ]);

        return response()->json(['status' => true, 'message' => 'Kelas berhasil ditambahkan', 'data' => $kelas]);
    }

    /**
     * Update Kelas
     */
    public function updateKelas(Request $request, $id)
    {
        $kelas = Kelas::findOrFail($id);
        
        $request->validate([
            'nama' => 'required|string|unique:kelas,nama,' . $id,
            'keterangan' => 'nullable|string',
            'aktif' => 'boolean'
        ]);

        $kelas->update($request->all());

        return response()->json(['status' => true, 'message' => 'Kelas berhasil diperbarui', 'data' => $kelas]);
    }

    /**
     * Delete Kelas
     */
    public function destroyKelas($id)
    {
        $kelas = Kelas::findOrFail($id);
        $kelas->delete();
        return response()->json(['status' => true, 'message' => 'Kelas berhasil dihapus']);
    }

    /**
     * Create new Jurusan
     */
    public function storeJurusan(Request $request)
    {
        $request->validate([
            'kode' => 'required|string|unique:jurusan,kode',
            'nama' => 'required|string',
            'deskripsi' => 'nullable|string',
        ]);

        $jurusan = Jurusan::create([
            'kode' => $request->kode,
            'nama' => $request->nama,
            'deskripsi' => $request->deskripsi,
            'aktif' => true
        ]);

        return response()->json(['status' => true, 'message' => 'Jurusan berhasil ditambahkan', 'data' => $jurusan]);
    }

    /**
     * Update Jurusan
     */
    public function updateJurusan(Request $request, $id)
    {
        $jurusan = Jurusan::findOrFail($id);
        
        $request->validate([
            'kode' => 'required|string|unique:jurusan,kode,' . $id,
            'nama' => 'required|string',
            'deskripsi' => 'nullable|string',
            'aktif' => 'boolean'
        ]);

        $jurusan->update($request->all());

        return response()->json(['status' => true, 'message' => 'Jurusan berhasil diperbarui', 'data' => $jurusan]);
    }

    /**
     * Delete Jurusan
     */
    public function destroyJurusan($id)
    {
        $jurusan = Jurusan::findOrFail($id);
        $jurusan->delete();
        return response()->json(['status' => true, 'message' => 'Jurusan berhasil dihapus']);
    }
}
