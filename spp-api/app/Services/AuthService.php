<?php

namespace App\Services;

use App\Models\User;
use App\Models\SppBill;
use App\Models\ValidStudent;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class AuthService
{
    /**
     * Register a new user
     */
    public function register(array $data)
    {
        $role = $data['role'] ?? 'siswa';
        
        // ✅ VALIDASI NISN untuk role SISWA
        if ($role === 'siswa') {
            $nisn = $data['nisn'] ?? null;
            
            if (!$nisn) {
                throw new \Exception('NISN wajib diisi untuk pendaftaran siswa');
            }
            
            // Cek NISN di database valid_students
            $validStudent = ValidStudent::where('nisn', $nisn)->first();
            
            if (!$validStudent) {
                throw new \Exception('NISN tidak terdaftar dalam database sekolah. Silakan hubungi admin.');
            }
            
            // Cek apakah siswa sudah lulus
            if ($validStudent->status_kelulusan === 'lulus') {
                throw new \Exception("Siswa dengan NISN ini sudah lulus pada tahun {$validStudent->tahun_lulus}. Tidak dapat melakukan registrasi.");
            }
            
            // Cek apakah siswa pindah/keluar
            if ($validStudent->status_kelulusan === 'pindah') {
                throw new \Exception('Siswa dengan NISN ini sudah pindah sekolah. Tidak dapat melakukan registrasi.');
            }
            
            if ($validStudent->status_kelulusan === 'keluar') {
                throw new \Exception('Siswa dengan NISN ini sudah keluar dari sekolah. Tidak dapat melakukan registrasi.');
            }
            
            // Cek apakah NISN sudah pernah dipakai registrasi
            if ($validStudent->is_registered) {
                throw new \Exception('NISN ini sudah pernah digunakan untuk registrasi. Silakan gunakan fitur login.');
            }
            
            // ✅ NISN VALID dan AKTIF - Auto-fill data dari database
            $data['name'] = $validStudent->nama;
            $data['kelas'] = $validStudent->kelas;
            $data['jurusan'] = $validStudent->jurusan; // Fix: Ambil jurusan dari valid_students
        }
        
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'nis' => $data['nis'] ?? null,
            'nisn' => $data['nisn'] ?? null,
            'telepon' => $data['telepon'] ?? null,
            'alamat' => $data['alamat'] ?? null,
            'kelas' => $data['kelas'] ?? null,
            'jurusan' => $data['jurusan'] ?? null, // Fix: Simpan jurusan ke tabel users
            'jenis_kelamin' => $data['jenis_kelamin'] ?? null,
            'status_kelulusan' => 'aktif', // Default aktif saat register
        ]);

        // Assign role
        $user->assignRole($role);

        // ✅ Mark NISN as registered
        if ($role === 'siswa' && isset($validStudent)) {
            $validStudent->markAsRegistered();
        }

        // 🎯 AUTO-GENERATE SPP BILLS untuk siswa baru (12 bulan)
        if ($role === 'siswa') {
            // ✅ Ambil data pembayaran dari valid_students (jika ada)
            $dataPembayaran = $validStudent->data_pembayaran ?? null;
            $this->generateSppBillsForNewStudent($user, $dataPembayaran);
        }

        return $user;
    }

    /**
     * Generate SPP bills untuk siswa baru (12 bulan - tahun ini)
     * 
     * @param User $user
     * @param array|null $dataPembayaran - Data pembayaran dari valid_students (optional)
     *   Format: [
     *     {'bulan': 1, 'status': 'lunas', 'tanggal_bayar': '2025-01-05', 'jumlah': 500000},
     *     {'bulan': 2, 'status': 'belum_dibayar', 'tanggal_bayar': null, 'jumlah': 500000},
     *     ...
     *   ]
     */
    private function generateSppBillsForNewStudent(User $user, ?array $dataPembayaran = null)
    {
        $currentYear = Carbon::now()->year;
        $months = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];

        foreach ($months as $index => $month) {
            $monthNumber = $index + 1;
            
            // 🔍 CEK: Apakah ada data pembayaran untuk bulan ini?
            $pembayaranBulanIni = $this->findPaymentData($dataPembayaran, $monthNumber);
            
            // Tentukan status, jumlah, dan tanggal bayar
            $status = $pembayaranBulanIni['status'] ?? 'belum_dibayar';
            $jumlah = $pembayaranBulanIni['jumlah'] ?? 500000; // Default Rp 500k
            $tanggalBayar = $pembayaranBulanIni['tanggal_bayar'] ?? null;
            
            // Tentukan jatuh tempo (tanggal 10 setiap bulan)
            $dueDate = Carbon::create($currentYear, $monthNumber, 10);
            
            // Generate nomor tagihan: SPP-USERID-TAHUN-BULAN (e.g., SPP-1-2025-01)
            $nomorTagihan = sprintf('SPP-%d-%d-%02d', $user->id, $currentYear, $monthNumber);
            
            SppBill::create([
                'user_id' => $user->id,
                'nomor_tagihan' => $nomorTagihan,
                'bulan' => $month,
                'tahun' => $currentYear,
                'jumlah' => $jumlah,
                'status' => $status, // ✅ Status REAL dari data sekolah (jika ada)
                'tanggal_jatuh_tempo' => $dueDate,
                // Note: tanggal_bayar tidak ada di migration saat ini
            ]);
        }
    }

    /**
     * Cari data pembayaran untuk bulan tertentu
     * 
     * @param array|null $dataPembayaran
     * @param int $bulan - 1-12
     * @return array
     */
    private function findPaymentData(?array $dataPembayaran, int $bulan): array
    {
        if (!$dataPembayaran) {
            return [];
        }

        foreach ($dataPembayaran as $payment) {
            if (isset($payment['bulan']) && $payment['bulan'] == $bulan) {
                return $payment;
            }
        }

        return [];
    }

    /**
     * Login user and create token
     */
    public function login(array $credentials)
    {
        if (!Auth::attempt($credentials)) {
            return null;
        }

        $user = Auth::user();
        
        // ✅ CEK STATUS KELULUSAN - Jika siswa sudah lulus, tidak boleh login
        if ($user->hasRole('siswa') && $user->status_kelulusan !== 'aktif') {
            Auth::logout(); // Logout paksa
            
            $statusMessages = [
                'lulus' => "Akun tidak aktif. Siswa sudah lulus" . ($user->tahun_lulus ? " pada tahun {$user->tahun_lulus}" : "") . ".",
                'pindah' => 'Akun tidak aktif. Siswa sudah pindah sekolah.',
                'keluar' => 'Akun tidak aktif. Siswa sudah keluar dari sekolah.',
            ];
            
            throw new \Exception($statusMessages[$user->status_kelulusan] ?? 'Akun tidak aktif.');
        }
        
        // 🎯 AUTO-GENERATE TAGIHAN TAHUN BARU (saat login pertama kali di tahun baru)
        if ($user->hasRole('siswa')) {
            $this->checkAndGenerateNewYearBills($user);
        }
        
        $token = $user->createToken('auth_token')->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
        ];
    }

    /**
     * Logout user
     */
    public function logout(User $user)
    {
        $user->currentAccessToken()->delete();
        return true;
    }

    /**
     * Get authenticated user profile
     */
    public function profile(User $user)
    {
        return $user->load('roles');
    }

    /**
     * 🎯 CEK & AUTO-GENERATE TAGIHAN TAHUN BARU
     * 
     * Method ini dipanggil saat siswa login.
     * Jika tahun sekarang belum ada tagihan, otomatis generate 12 bulan baru.
     * 
     * Contoh:
     * - 2025: Siswa register → Ada tagihan 2025
     * - 2026: Siswa login pertama kali → Auto-generate tagihan 2026
     * - 2027: Siswa login pertama kali → Auto-generate tagihan 2027
     * 
     * @param User $user
     * @return void
     */
    private function checkAndGenerateNewYearBills(User $user): void
    {
        $currentYear = Carbon::now()->year;
        
        // Cek: Apakah user sudah punya tagihan untuk tahun ini?
        $hasCurrentYearBills = SppBill::where('user_id', $user->id)
            ->where('tahun', $currentYear)
            ->exists();
        
        // Jika belum ada tagihan tahun ini → GENERATE!
        if (!$hasCurrentYearBills) {
            \Log::info("🎯 Auto-generating SPP bills for user {$user->id} - Year {$currentYear}");
            
            // Generate tagihan tahun baru (semua default BELUM BAYAR)
            // Note: data_pembayaran hanya dipakai saat register pertama kali
            $this->generateSppBillsForNewStudent($user, null);
            
            \Log::info("✅ Successfully generated 12 SPP bills for year {$currentYear}");
        }
    }
}
