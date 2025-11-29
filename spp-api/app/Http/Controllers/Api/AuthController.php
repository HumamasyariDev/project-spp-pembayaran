<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    protected $authService;

    public function __construct(AuthService $authService)
    {
        $this->authService = $authService;
    }

    /**
     * Register a new user
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:users,name',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'role' => 'required|in:admin,petugas,siswa',
            'nis' => 'nullable|string|unique:users',
            'nisn' => 'nullable|string|unique:users',
            'telepon' => 'nullable|string',
            'alamat' => 'nullable|string',
            'kelas' => 'nullable|string',
            'jenis_kelamin' => 'nullable|in:L,P',
        ], [
            'name.unique' => 'Nama sudah digunakan oleh pengguna lain',
            'email.unique' => 'Email sudah terdaftar',
            'nis.unique' => 'NIS sudah digunakan',
            'nisn.unique' => 'NISN sudah digunakan',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = $this->authService->register($request->all());
            
            // Create token untuk auto-login setelah register
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'status' => true,
                'message' => 'User berhasil didaftarkan',
                'data' => [
                    'user' => new UserResource($user->load('roles')),
                    'token' => $token,
                    'token_type' => 'Bearer',
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat registrasi',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Login user
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $result = $this->authService->login($request->only('email', 'password'));

            if (!$result) {
                return response()->json([
                    'status' => false,
                    'message' => 'Email atau password salah',
                ], 401);
            }

            return response()->json([
                'status' => true,
                'message' => 'Login berhasil',
                'data' => [
                    'user' => new UserResource($result['user']->load('roles')),
                    'token' => $result['token'],
                    'token_type' => 'Bearer',
                ],
            ], 200);
        } catch (\Exception $e) {
            // ✅ FIXED: Catch exception dari validasi status kelulusan
            return response()->json([
                'status' => false,
                'message' => 'Login gagal',
                'error' => $e->getMessage(),
            ], 401);
        }
    }

    /**
     * Get authenticated user profile
     */
    public function profile(Request $request)
    {
        $user = $this->authService->profile($request->user());

        return response()->json([
            'status' => true,
            'message' => 'Data profil berhasil diambil',
            'data' => new UserResource($user),
        ], 200);
    }

    /**
     * Logout user
     */
    public function logout(Request $request)
    {
        $this->authService->logout($request->user());

        return response()->json([
            'status' => true,
            'message' => 'Logout berhasil',
        ], 200);
    }

    /**
     * Update FCM token for push notifications
     */
    public function updateFCMToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        $user->fcm_token = $request->fcm_token;
        $user->save();

        return response()->json([
            'status' => true,
            'message' => 'FCM token updated successfully',
        ]);
    }

    /**
     * Update user profile (kelas & jurusan)
     */
    public function updateProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nisn' => 'required|string|min:10|unique:users,nisn,' . $request->user()->id,
            'telepon' => 'required|string|min:10',
            'alamat' => 'required|string',
            'kelas' => 'required|string|in:X,XI,XII',
            'jurusan' => 'required|string|in:RPL,TKJ,TKR,TPM,LAS,LISTRIK',
        ], [
            'nisn.required' => 'NISN tidak boleh kosong',
            'nisn.min' => 'NISN minimal 10 digit',
            'nisn.unique' => 'NISN sudah digunakan oleh pengguna lain',
            'telepon.required' => 'Nomor telepon tidak boleh kosong',
            'telepon.min' => 'Nomor telepon minimal 10 digit',
            'alamat.required' => 'Alamat tidak boleh kosong',
            'kelas.required' => 'Kelas wajib dipilih',
            'jurusan.required' => 'Jurusan wajib dipilih',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = $request->user();
            $user->nisn = $request->nisn;
            $user->telepon = $request->telepon;
            $user->alamat = $request->alamat;
            $user->kelas = $request->kelas;
            $user->jurusan = $request->jurusan;
            $user->save();

            logger()->info('✓ Profile updated successfully', [
                'user_id' => $user->id,
                'nisn' => $user->nisn,
                'telepon' => $user->telepon,
                'kelas' => $user->kelas,
                'jurusan' => $user->jurusan,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Profil berhasil diperbarui',
                'data' => [
                    'user' => new UserResource($user->load('roles')),
                ],
            ], 200);
        } catch (\Exception $e) {
            logger()->error('❌ Profile update failed', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => false,
                'message' => 'Gagal memperbarui profil',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Validate NISN before registration
     */
    public function validateNisn(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nisn' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'NISN wajib diisi',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $nisn = $request->nisn;
            
            // Cek NISN di database valid_students
            $validStudent = \App\Models\ValidStudent::where('nisn', $nisn)->first();
            
            if (!$validStudent) {
                return response()->json([
                    'status' => false,
                    'message' => 'NISN tidak terdaftar dalam database sekolah',
                    'error' => 'NISN tidak terdaftar dalam database sekolah. Silakan hubungi admin.',
                ], 404);
            }
            
            // Cek apakah siswa sudah lulus
            if ($validStudent->status_kelulusan === 'lulus') {
                return response()->json([
                    'status' => false,
                    'message' => 'Siswa sudah lulus',
                    'error' => "Siswa dengan NISN ini sudah lulus pada tahun {$validStudent->tahun_lulus}. Tidak dapat melakukan registrasi.",
                ], 403);
            }
            
            // Cek apakah siswa pindah/keluar
            if ($validStudent->status_kelulusan === 'pindah') {
                return response()->json([
                    'status' => false,
                    'message' => 'Siswa sudah pindah',
                    'error' => 'Siswa dengan NISN ini sudah pindah sekolah. Tidak dapat melakukan registrasi.',
                ], 403);
            }
            
            if ($validStudent->status_kelulusan === 'keluar') {
                return response()->json([
                    'status' => false,
                    'message' => 'Siswa sudah keluar',
                    'error' => 'Siswa dengan NISN ini sudah keluar dari sekolah. Tidak dapat melakukan registrasi.',
                ], 403);
            }
            
            // Cek apakah NISN sudah pernah dipakai registrasi
            if ($validStudent->is_registered) {
                return response()->json([
                    'status' => false,
                    'message' => 'NISN sudah digunakan',
                    'error' => 'NISN ini sudah pernah digunakan untuk registrasi. Silakan gunakan fitur login.',
                ], 409);
            }
            
            // ✅ NISN VALID dan AKTIF
            return response()->json([
                'status' => true,
                'message' => 'NISN valid',
                'data' => [
                    'nisn' => $validStudent->nisn,
                    'nama' => $validStudent->nama,
                    'kelas' => $validStudent->kelas,
                    'jurusan' => $validStudent->jurusan,
                    'status' => $validStudent->status_kelulusan,
                ],
            ], 200);
            
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Terjadi kesalahan saat validasi NISN',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Check if email exists (for Google Sign In validation)
     */
    public function checkEmail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Email tidak valid',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = \App\Models\User::where('email', $request->email)->first();

        if ($user) {
            // Email sudah terdaftar - bisa langsung login
            return response()->json([
                'status' => true,
                'exists' => true,
                'message' => 'Email sudah terdaftar',
                'data' => [
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'registered_via_google' => !empty($user->google_id) || $user->password === null,
                ],
            ], 200);
        } else {
            // Email belum terdaftar - perlu registrasi
            return response()->json([
                'status' => true,
                'exists' => false,
                'message' => 'Email belum terdaftar',
            ], 200);
        }
    }

    /**
     * Login with Google (auto-login for existing users)
     */
    public function loginWithGoogle(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'google_id' => 'nullable|string',
            'display_name' => 'nullable|string',
            'photo_url' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = \App\Models\User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'Akun belum terdaftar. Silakan daftar terlebih dahulu.',
            ], 404);
        }

        // Update google_id jika belum ada
        if ($request->google_id && !$user->google_id) {
            $user->google_id = $request->google_id;
            $user->save();
        }

        // Generate token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Login berhasil',
            'data' => [
                'user' => new UserResource($user->load('roles')),
                'token' => $token,
            ],
        ], 200);
    }
}
