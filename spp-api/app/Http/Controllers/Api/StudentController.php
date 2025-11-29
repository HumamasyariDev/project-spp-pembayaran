<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StudentController extends Controller
{
    /**
     * Get all students (users with role 'siswa')
     */
    public function index(Request $request)
    {
        try {
            $query = User::role('siswa');

            // Search by name, nis, or nisn
            if ($request->has('search') && $request->search) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('nis', 'like', "%{$search}%")
                      ->orWhere('nisn', 'like', "%{$search}%");
                });
            }

            // Filter by kelas
            if ($request->has('kelas') && $request->kelas) {
                $query->where('kelas', $request->kelas);
            }

            // Filter by jurusan
            if ($request->has('jurusan') && $request->jurusan) {
                $query->where('jurusan', $request->jurusan);
            }

            // Filter by status
            if ($request->has('status') && $request->status) {
                $query->where('status_kelulusan', $request->status);
            }

            $students = $query->orderBy('name', 'asc')->get();

            // 🛠️ SELF-HEALING: Cek dan lengkapi data siswa yang kosong dari tabel valid_students
            foreach ($students as $student) {
                if (empty($student->nisn) || empty($student->kelas) || empty($student->jurusan)) {
                    // Cari data di valid_students berdasarkan nama
                    $validData = \App\Models\ValidStudent::where('nama', $student->name)->first();
                    
                    if ($validData) {
                        $updates = [];
                        if (empty($student->nisn)) $updates['nisn'] = $validData->nisn;
                        if (empty($student->kelas)) $updates['kelas'] = $validData->kelas;
                        if (empty($student->jurusan)) $updates['jurusan'] = $validData->jurusan;
                        
                        if (!empty($updates)) {
                            $student->update($updates);
                            // Refresh data student di object collection
                            $student->refresh();
                        }
                    }
                }
            }

            return response()->json([
                'status' => true,
                'message' => 'Students retrieved successfully',
                'data' => $students,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve students',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get a single student
     */
    public function show($id)
    {
        try {
            $student = User::role('siswa')->findOrFail($id);

            return response()->json([
                'status' => true,
                'message' => 'Student retrieved successfully',
                'data' => $student,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Student not found',
                'error' => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * Create a new student
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'email' => 'required|email|unique:users,email',
                'password' => 'required|string|min:6',
                'nis' => 'required|string|unique:users,nis',
                'nisn' => 'required|string|unique:users,nisn',
                'kelas' => 'required|string',
                'jurusan' => 'required|string',
                'jenis_kelamin' => 'required|in:L,P',
                'telepon' => 'nullable|string',
                'alamat' => 'nullable|string',
            ]);

            $student = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'nis' => $validated['nis'],
                'nisn' => $validated['nisn'],
                'kelas' => $validated['kelas'],
                'jurusan' => $validated['jurusan'],
                'jenis_kelamin' => $validated['jenis_kelamin'],
                'telepon' => $validated['telepon'] ?? null,
                'alamat' => $validated['alamat'] ?? null,
                'status_kelulusan' => 'aktif',
            ]);

            $student->assignRole('siswa');

            return response()->json([
                'status' => true,
                'message' => 'Student created successfully',
                'data' => $student,
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to create student',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update a student
     */
    public function update(Request $request, $id)
    {
        try {
            $student = User::role('siswa')->findOrFail($id);

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'email' => ['required', 'email', Rule::unique('users')->ignore($id)],
                'nis' => ['required', 'string', Rule::unique('users')->ignore($id)],
                'nisn' => ['required', 'string', Rule::unique('users')->ignore($id)],
                'kelas' => 'required|string',
                'jurusan' => 'required|string',
                'jenis_kelamin' => 'required|in:L,P',
                'telepon' => 'nullable|string',
                'alamat' => 'nullable|string',
                'status_kelulusan' => 'nullable|string',
            ]);

            $student->update($validated);

            // Update password if provided
            if ($request->has('password') && $request->password) {
                $student->update(['password' => Hash::make($request->password)]);
            }

            return response()->json([
                'status' => true,
                'message' => 'Student updated successfully',
                'data' => $student,
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to update student',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete a student
     */
    public function destroy($id)
    {
        try {
            $student = User::role('siswa')->findOrFail($id);
            $student->delete();

            return response()->json([
                'status' => true,
                'message' => 'Student deleted successfully',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to delete student',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get student statistics
     */
    public function stats()
    {
        try {
            $total = User::role('siswa')->count();
            $aktif = User::role('siswa')->where('status_kelulusan', 'aktif')->count();
            $lulus = User::role('siswa')->where('status_kelulusan', 'lulus')->count();
            
            $byKelas = User::role('siswa')
                ->selectRaw('kelas, COUNT(*) as total')
                ->groupBy('kelas')
                ->orderBy('kelas')
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Student stats retrieved successfully',
                'data' => [
                    'total' => $total,
                    'aktif' => $aktif,
                    'lulus' => $lulus,
                    'by_kelas' => $byKelas,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve stats',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
