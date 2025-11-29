<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\QueueController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\BannerController;
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\KelasJurusanController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\StudentController;

/*
|--------------------------------------------------------------------------
| API Routes - SPP Payment & Queue System
|--------------------------------------------------------------------------
| 
| Backend API untuk sistem Antrian dan Pembayaran SPP Sekolah
| Menggunakan Laravel Sanctum untuk autentikasi
| 
*/

// ==================== PUBLIC ROUTES ====================
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/check-email', [AuthController::class, 'checkEmail']); // Check if email exists (Google Sign In)
    Route::post('/validate-nisn', [AuthController::class, 'validateNisn']); // ✅ Validate NISN before registration
    Route::post('/login-google', [AuthController::class, 'loginWithGoogle']); // Auto-login with Google
});

// Public: Get Kelas & Jurusan (untuk form registrasi)
Route::get('/kelas', [KelasJurusanController::class, 'getKelas']);
Route::get('/jurusan', [KelasJurusanController::class, 'getJurusan']);

// Public: Get available queue services with statistics
Route::get('/queues/services', [QueueController::class, 'services']);

// ==================== PROTECTED ROUTES ====================
Route::middleware('auth:sanctum')->group(function () {
    
    // Auth Routes
    Route::prefix('auth')->group(function () {
        Route::get('/profile', [AuthController::class, 'profile']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/fcm-token', [AuthController::class, 'updateFCMToken']);
    });

    // ==================== QUEUE ROUTES ====================
    Route::prefix('queues')->group(function () {
        
        // Siswa Routes
        Route::middleware('role:siswa')->group(function () {
            Route::post('/', [QueueController::class, 'create']); // Ambil nomor antrian
            Route::get('/my-queues', [QueueController::class, 'myQueues']); // Riwayat antrian siswa
            Route::get('/my-active-queue', [QueueController::class, 'myActiveQueue']); // Antrian aktif dengan estimasi real-time
            Route::post('/{id}/cancel', [QueueController::class, 'cancel']); // Batalkan antrian
        });

        // Petugas Routes
        Route::middleware('role:petugas|admin')->group(function () {
            Route::get('/active', [QueueController::class, 'activeQueues']); // Antrian aktif hari ini
            Route::post('/scan', [QueueController::class, 'scanQr']); // ✅ Scan QR Antrian
            Route::post('/call-next', [QueueController::class, 'callNext']); // Panggil antrian berikutnya
            Route::post('/{id}/serve', [QueueController::class, 'serve']); // Tandai sedang dilayani
            Route::post('/{id}/complete', [QueueController::class, 'complete']); // Tandai selesai
        });
    });

    // ==================== PAYMENT ROUTES ====================
    Route::prefix('payments')->group(function () {
        
        // User Routes (Siswa)
        Route::middleware('role:siswa')->group(function () {
            Route::get('/my-bills', [PaymentController::class, 'myBills']); // Tagihan SPP siswa
            Route::get('/unpaid-bills', [PaymentController::class, 'unpaidBills']); // Tagihan belum dibayar
            Route::post('/bills/{billId}/pay', [PaymentController::class, 'createPayment']); // Bayar SPP
            Route::get('/my-payments', [PaymentController::class, 'myPayments']); // Riwayat pembayaran
            Route::get('/history', [PaymentController::class, 'paymentHistory']); // Riwayat pembayaran lengkap
            
            // Mobile payment routes for students
            Route::post('/mobile/pay', [PaymentController::class, 'mobilePayment']); // Cicilan manual dari mobile
            Route::post('/mobile/pay-midtrans', [PaymentController::class, 'createInstallmentPayment']); // Cicilan via Midtrans
            Route::get('/mobile/bill/{id}', [PaymentController::class, 'getBillDetail']); // Detail tagihan untuk mobile
            
            // Installment history routes
            Route::get('/installments', [PaymentController::class, 'getAllInstallmentHistory']); // Semua riwayat cicilan
            Route::get('/installments/{tagihanId}', [PaymentController::class, 'getInstallmentHistory']); // Riwayat cicilan per tagihan
        });

        // Petugas & Admin Routes
        Route::middleware('role:petugas|admin')->group(function () {
            Route::get('/', [PaymentController::class, 'allPayments']); // Semua pembayaran (filter by status)
            Route::get('/{id}', [PaymentController::class, 'paymentDetail']); // Detail pembayaran
            Route::post('/{id}/verify', [PaymentController::class, 'verifyPayment']); // Verifikasi pembayaran
            Route::post('/{id}/pay', [PaymentController::class, 'manualPayment']); // Pembayaran Manual / Cicilan
        });
    });

    // ==================== NOTIFICATION ROUTES ====================
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']); // List semua notifikasi
        Route::get('/unread-count', [NotificationController::class, 'unreadCount']); // Jumlah notifikasi belum dibaca
        Route::get('/unread', [NotificationController::class, 'unread']); // List notifikasi belum dibaca
        Route::post('/{id}/mark-read', [NotificationController::class, 'markAsRead']); // Tandai satu notifikasi sudah dibaca
        Route::post('/mark-all-read', [NotificationController::class, 'markAllAsRead']); // Tandai semua sudah dibaca
        Route::delete('/{id}', [NotificationController::class, 'destroy']); // Hapus notifikasi
    });

    // ==================== DASHBOARD ROUTES ====================
    Route::prefix('dashboard')->group(function () {
        // Siswa dashboard stats
        Route::get('/stats', [DashboardController::class, 'stats']);
        
        // Admin/Petugas dashboard stats
        Route::middleware('role:petugas|admin')->group(function () {
            Route::get('/admin-stats', [DashboardController::class, 'adminStats']);
        });
    });

    // ==================== EVENT ROUTES ====================
    Route::prefix('events')->group(function () {
        // Public access (for all authenticated users)
        Route::get('/upcoming', [EventController::class, 'upcoming']); // Event mendatang
        Route::get('/', [EventController::class, 'index']); // All events with filters
        Route::get('/{id}', [EventController::class, 'show']); // Event detail
        Route::get('/{id}/similar', [EventController::class, 'similar']); // Similar events
        Route::post('/{id}/remind', [EventController::class, 'remind']); // Remind Me
        
        // Admin/Petugas only (CRUD operations)
        Route::middleware('role:petugas|admin')->group(function () {
            Route::post('/', [EventController::class, 'store']); // Create event
            Route::put('/{id}', [EventController::class, 'update']); // Update event
            Route::delete('/{id}', [EventController::class, 'destroy']); // Delete event
        });
    });

    // ==================== ANNOUNCEMENT ROUTES ====================
    Route::prefix('announcements')->group(function () {
        // Public access (for all authenticated users)
        Route::get('/latest', [AnnouncementController::class, 'latest']); // Pengumuman terbaru
        Route::get('/', [AnnouncementController::class, 'index']); // All announcements with filters
        Route::get('/{id}', [AnnouncementController::class, 'show']); // Announcement detail
        Route::get('/{id}/other', [AnnouncementController::class, 'other']); // List of other recent announcements
        
        // Admin/Petugas only (CRUD operations)
        Route::middleware('role:petugas|admin')->group(function () {
            Route::post('/', [AnnouncementController::class, 'store']); // Create announcement
            Route::put('/{id}', [AnnouncementController::class, 'update']); // Update announcement
            Route::delete('/{id}', [AnnouncementController::class, 'destroy']); // Delete announcement
        });
    });

    // ==================== BANNER ROUTES ====================
    Route::prefix('banners')->group(function () {
        // Public access (for all authenticated users)
        Route::get('/active', [BannerController::class, 'active']); // Active banners
        
        // Admin/Petugas only (CRUD operations)
        Route::middleware('role:petugas|admin')->group(function () {
            Route::get('/', [BannerController::class, 'index']); // All banners
            Route::get('/{id}', [BannerController::class, 'show']); // Banner detail
            Route::post('/', [BannerController::class, 'store']); // Create banner
            Route::put('/{id}', [BannerController::class, 'update']); // Update banner
            Route::delete('/{id}', [BannerController::class, 'destroy']); // Delete banner
        });
    });

    // ==================== UPLOAD ROUTES ====================
    Route::prefix('upload')->middleware('role:petugas|admin')->group(function () {
        Route::post('/image', [UploadController::class, 'uploadImage']); // Upload image
        Route::delete('/image', [UploadController::class, 'deleteImage']); // Delete image
    });

    // ==================== SEARCH ROUTE ====================
    Route::get('/search', [SearchController::class, 'search']);
    Route::get('/search/recent', [SearchController::class, 'recent']);

    // ==================== STUDENT ROUTES ====================
    Route::prefix('students')->middleware('role:petugas|admin')->group(function () {
        Route::get('/', [StudentController::class, 'index']); // List all students
        Route::get('/stats', [StudentController::class, 'stats']); // Student statistics
        Route::get('/{id}', [StudentController::class, 'show']); // Get single student
        Route::post('/', [StudentController::class, 'store']); // Create student
        Route::put('/{id}', [StudentController::class, 'update']); // Update student
        Route::delete('/{id}', [StudentController::class, 'destroy']); // Delete student
    });

    // ==================== KELAS & JURUSAN MANAGEMENT ROUTES ====================
    Route::middleware('role:petugas|admin')->group(function () {
        // Kelas CRUD
        Route::post('/kelas', [KelasJurusanController::class, 'storeKelas']);
        Route::put('/kelas/{id}', [KelasJurusanController::class, 'updateKelas']);
        Route::delete('/kelas/{id}', [KelasJurusanController::class, 'destroyKelas']);

        // Jurusan CRUD
        Route::post('/jurusan', [KelasJurusanController::class, 'storeJurusan']);
        Route::put('/jurusan/{id}', [KelasJurusanController::class, 'updateJurusan']);
        Route::delete('/jurusan/{id}', [KelasJurusanController::class, 'destroyJurusan']);
    });

    // ==================== MIDTRANS PAYMENT ROUTES ====================
    Route::prefix('midtrans')->group(function () {
        Route::post('/update-payment-status', [PaymentController::class, 'updatePaymentStatus']); // Update payment status
    });
});

// ==================== MIDTRANS WEBHOOK (NO AUTH) ====================
Route::post('/midtrans/notification', [\App\Http\Controllers\Api\PaymentController::class, 'midtransNotification']);

/*
|--------------------------------------------------------------------------
| API Endpoint Documentation
|--------------------------------------------------------------------------
|
| PUBLIC ENDPOINTS:
| - POST   /api/auth/register          - Register user baru
| - POST   /api/auth/login             - Login user
|
| AUTHENTICATED ENDPOINTS:
| - GET    /api/auth/profile           - Get profil user yang login
| - POST   /api/auth/logout            - Logout user
|
| QUEUE ENDPOINTS (Siswa):
| - POST   /api/queues                 - Ambil nomor antrian baru
| - GET    /api/queues/my-queues       - Lihat riwayat antrian
| - POST   /api/queues/{id}/cancel     - Batalkan antrian
|
| QUEUE ENDPOINTS (Petugas/Admin):
| - GET    /api/queues/active          - Lihat antrian aktif hari ini
| - POST   /api/queues/call-next       - Panggil antrian berikutnya
| - POST   /api/queues/{id}/serve      - Tandai antrian sedang dilayani
| - POST   /api/queues/{id}/complete   - Tandai antrian selesai
|
| PAYMENT ENDPOINTS (Siswa):
| - GET    /api/payments/my-bills           - Lihat semua tagihan SPP
| - GET    /api/payments/unpaid-bills       - Lihat tagihan belum dibayar
| - POST   /api/payments/bills/{id}/pay     - Bayar tagihan SPP
| - GET    /api/payments/my-payments        - Lihat riwayat pembayaran
|
| PAYMENT ENDPOINTS (Petugas/Admin):
| - GET    /api/payments                    - Lihat semua pembayaran (query: ?status=pending|verified|rejected)
| - GET    /api/payments/{id}               - Detail pembayaran
| - POST   /api/payments/{id}/verify        - Verifikasi/tolak pembayaran
|
| RESPONSE FORMAT:
| Success: { "status": true, "message": "...", "data": {...} }
| Error:   { "status": false, "message": "...", "errors": {...} }
|
| AUTHENTICATION:
| Header: Authorization: Bearer {token}
|
| REALTIME NOTIFICATIONS:
| Channel: private-queue.{user_id}     - Notifikasi perubahan status antrian
| Channel: private-payment.{user_id}   - Notifikasi perubahan status pembayaran
|
*/
