# 🎓 SPP Payment & Queue System API

Backend RESTful API untuk sistem **Antrian dan Pembayaran SPP Sekolah** menggunakan Laravel 12 dengan arsitektur bersih dan profesional.

## 🚀 Fitur Utama

### 1. **Autentikasi & Otorisasi**
- ✅ Token-based authentication menggunakan **Laravel Sanctum**
- ✅ Role-based access control dengan **Spatie Laravel Permission**
- ✅ 3 Role: Admin, Petugas, Siswa
- ✅ Endpoint: Login, Register, Logout, Profile

### 2. **Sistem Antrian**
- ✅ Siswa dapat mengambil nomor antrian pembayaran SPP
- ✅ Nomor antrian otomatis ter-generate per hari
- ✅ Petugas dapat memanggil antrian berikutnya
- ✅ Status antrian: waiting, called, served, completed, cancelled
- ✅ Realtime notification saat status antrian berubah

### 3. **Sistem Pembayaran SPP**
- ✅ Siswa dapat melihat tagihan SPP bulanan
- ✅ Upload bukti pembayaran (foto/gambar)
- ✅ Metode pembayaran: Cash, Transfer, E-Wallet
- ✅ Petugas dapat verifikasi/reject pembayaran
- ✅ Status pembayaran: unpaid, pending, paid
- ✅ Realtime notification saat pembayaran diverifikasi

### 4. **Notifikasi Realtime**
- ✅ Menggunakan **Laravel Reverb** (WebSocket server)
- ✅ Private channels untuk setiap user
- ✅ Event broadcasting otomatis untuk perubahan status
- ✅ Siap diintegrasikan dengan Flutter

## 📋 Tech Stack

- **Framework**: Laravel 12
- **Authentication**: Laravel Sanctum
- **Authorization**: Spatie Laravel Permission
- **Realtime**: Laravel Reverb (WebSockets)
- **Database**: SQLite (development) / MySQL (production)
- **Architecture**: Service Layer Pattern
- **API Resources**: Consistent JSON response format

## 🔧 Instalasi

### 1. Clone & Install Dependencies

```bash
cd /opt/lampp/htdocs/tugas_sekolah/spp-api
composer install
```

### 2. Setup Environment

```bash
cp .env.example .env
php artisan key:generate
```

### 3. Konfigurasi Database

Edit `.env`:
```env
DB_CONNECTION=sqlite
# Atau gunakan MySQL:
# DB_CONNECTION=mysql
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=spp_db
# DB_USERNAME=root
# DB_PASSWORD=
```

### 4. Jalankan Migrasi & Seeder

```bash
php artisan migrate
php artisan db:seed
```

### 5. Create Storage Link

```bash
php artisan storage:link
```

### 6. Jalankan Server

```bash
# Terminal 1: Web Server
php artisan serve

# Terminal 2: WebSocket Server (untuk realtime notifications)
php artisan reverb:start
```

API akan berjalan di: `http://localhost:8000`

## 👥 Default User Credentials

Setelah menjalankan seeder, gunakan credentials berikut:

### Admin
- Email: `admin@spp.com`
- Password: `password`

### Petugas
- Email: `petugas1@spp.com` atau `petugas2@spp.com`
- Password: `password`

### Siswa
- Email: `budi@siswa.com`, `siti@siswa.com`, `ahmad@siswa.com`, dll
- Password: `password`

## 📚 API Documentation

### Base URL
```
http://localhost:8000/api
```

### Response Format
Semua endpoint mengembalikan JSON dengan format konsisten:

**Success Response:**
```json
{
    "status": true,
    "message": "Success message",
    "data": {...}
}
```

**Error Response:**
```json
{
    "status": false,
    "message": "Error message",
    "errors": {...}
}
```

### Authentication Header
```
Authorization: Bearer {your_token_here}
```

---

## 🔐 Auth Endpoints

### 1. Register
```http
POST /api/auth/register
Content-Type: application/json

{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "siswa",
    "nis": "12345678",
    "nisn": "0012345678",
    "phone": "081234567890",
    "address": "Jl. Example No. 123",
    "class": "X IPA 1",
    "gender": "L"
}
```

### 2. Login
```http
POST /api/auth/login
Content-Type: application/json

{
    "email": "budi@siswa.com",
    "password": "password"
}
```

**Response:**
```json
{
    "status": true,
    "message": "Login berhasil",
    "data": {
        "user": {...},
        "token": "1|xxxxxxxxxxxxxxxxxxxxxx",
        "token_type": "Bearer"
    }
}
```

### 3. Get Profile
```http
GET /api/auth/profile
Authorization: Bearer {token}
```

### 4. Logout
```http
POST /api/auth/logout
Authorization: Bearer {token}
```

---

## 📋 Queue Endpoints

### Untuk Siswa:

#### 1. Ambil Nomor Antrian
```http
POST /api/queues
Authorization: Bearer {token}
```

#### 2. Lihat Riwayat Antrian
```http
GET /api/queues/my-queues
Authorization: Bearer {token}
```

#### 3. Batalkan Antrian
```http
POST /api/queues/{id}/cancel
Authorization: Bearer {token}
```

### Untuk Petugas/Admin:

#### 1. Lihat Antrian Aktif
```http
GET /api/queues/active
Authorization: Bearer {token}
```

#### 2. Panggil Antrian Berikutnya
```http
POST /api/queues/call-next
Authorization: Bearer {token}
```

#### 3. Tandai Sedang Dilayani
```http
POST /api/queues/{id}/serve
Authorization: Bearer {token}
```

#### 4. Tandai Selesai
```http
POST /api/queues/{id}/complete
Authorization: Bearer {token}
```

---

## 💰 Payment Endpoints

### Untuk Siswa:

#### 1. Lihat Tagihan SPP
```http
GET /api/payments/my-bills
Authorization: Bearer {token}
```

#### 2. Lihat Tagihan Belum Dibayar
```http
GET /api/payments/unpaid-bills
Authorization: Bearer {token}
```

#### 3. Bayar SPP (Upload Bukti)
```http
POST /api/payments/bills/{billId}/pay
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
    "amount": 500000,
    "payment_method": "transfer",
    "proof_image": (file),
    "notes": "Transfer via BCA"
}
```

#### 4. Lihat Riwayat Pembayaran
```http
GET /api/payments/my-payments
Authorization: Bearer {token}
```

### Untuk Petugas/Admin:

#### 1. Lihat Semua Pembayaran
```http
GET /api/payments?status=pending
Authorization: Bearer {token}
```

Query params:
- `status`: pending, verified, rejected (optional)

#### 2. Detail Pembayaran
```http
GET /api/payments/{id}
Authorization: Bearer {token}
```

#### 3. Verifikasi Pembayaran
```http
POST /api/payments/{id}/verify
Authorization: Bearer {token}
Content-Type: application/json

{
    "status": "verified",
    "notes": "Pembayaran telah diverifikasi"
}
```

---

## 🔔 Realtime Notifications

### WebSocket Configuration

Flutter app dapat connect ke WebSocket menggunakan:

```
Host: localhost
Port: 8080
App Key: spp-key
```

### Private Channels

#### 1. Queue Status Changed
```
Channel: private-queue.{user_id}
Event: queue.status.changed

Data:
{
    "queue": {...},
    "message": "Status antrian berubah menjadi: called"
}
```

#### 2. Payment Status Changed
```
Channel: private-payment.{user_id}
Event: payment.status.changed

Data:
{
    "payment": {...},
    "message": "Status pembayaran berubah menjadi: verified"
}
```

---

## 📂 Project Structure

```
spp-api/
├── app/
│   ├── Events/              # Broadcast Events
│   │   ├── QueueStatusChanged.php
│   │   └── PaymentStatusChanged.php
│   ├── Http/
│   │   ├── Controllers/Api/ # API Controllers
│   │   │   ├── AuthController.php
│   │   │   ├── QueueController.php
│   │   │   └── PaymentController.php
│   │   └── Resources/       # API Resources
│   │       ├── UserResource.php
│   │       ├── QueueResource.php
│   │       ├── SppBillResource.php
│   │       └── PaymentResource.php
│   ├── Models/              # Eloquent Models
│   │   ├── User.php
│   │   ├── Queue.php
│   │   ├── SppBill.php
│   │   └── Payment.php
│   └── Services/            # Business Logic
│       ├── AuthService.php
│       ├── QueueService.php
│       └── PaymentService.php
├── database/
│   ├── migrations/          # Database Migrations
│   └── seeders/             # Database Seeders
├── routes/
│   ├── api.php             # API Routes
│   └── channels.php        # Broadcast Channels
└── storage/
    └── app/public/         # Uploaded Files (payment proofs)
```

---

## 🧪 Testing

### Test dengan cURL

```bash
# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"budi@siswa.com","password":"password"}'

# Get Profile (dengan token)
curl -X GET http://localhost:8000/api/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Ambil Nomor Antrian
curl -X POST http://localhost:8000/api/queues \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Test dengan Postman

Import collection dari dokumentasi di atas atau gunakan Postman untuk test semua endpoint.

---

## 📝 Database Schema

### Users Table
- id, name, email, password
- nis, nisn, phone, address, class, gender
- roles (via Spatie Permission)

### Queues Table
- id, user_id, queue_number, status
- queue_date, called_by, called_at, served_at, completed_at

### SPP Bills Table
- id, user_id, bill_number, month, year
- amount, status, due_date

### Payments Table
- id, spp_bill_id, user_id, payment_number
- amount, payment_method, proof_image
- status, verified_by, verified_at, notes

---

## 🔒 Security Features

- ✅ Password hashing dengan bcrypt
- ✅ Token-based authentication (Sanctum)
- ✅ Role-based authorization
- ✅ CORS enabled untuk Flutter
- ✅ Protected private channels untuk broadcasting
- ✅ Input validation untuk semua endpoint

---

## 🚢 Deployment Tips

### Production Environment

1. **Set Database ke MySQL:**
   ```env
   DB_CONNECTION=mysql
   DB_HOST=your_host
   DB_DATABASE=spp_production
   ```

2. **Set Environment:**
   ```env
   APP_ENV=production
   APP_DEBUG=false
   ```

3. **Cache Config:**
   ```bash
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

4. **Setup WebSocket Server:**
   - Gunakan Supervisor untuk menjalankan `php artisan reverb:start`
   - Configure Nginx untuk WebSocket proxy

---

## 💡 Integration dengan Flutter

### 1. Setup HTTP Client

```dart
import 'package:http/http.dart' as http;

const String baseUrl = 'http://your-server-ip:8000/api';

Future<Response> login(String email, String password) async {
  return await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email, 'password': password}),
  );
}
```

### 2. Setup WebSocket (Laravel Echo)

```dart
import 'package:laravel_echo/laravel_echo.dart';

Echo echo = Echo({
  'broadcaster': 'reverb',
  'host': 'your-server-ip',
  'port': 8080,
  'key': 'spp-key',
  'authEndpoint': 'http://your-server-ip:8000/broadcasting/auth',
  'auth': {
    'headers': {
      'Authorization': 'Bearer $token',
    }
  },
});

// Listen to queue updates
echo.private('queue.$userId')
    .listen('queue.status.changed', (e) {
      print('Queue status changed: ${e.data}');
      // Show local notification
    });
```

---

## 📞 Support

Jika ada pertanyaan atau issue, silakan hubungi tim developer atau buat issue di repository.

---

## 📄 License

This project is open-sourced software licensed under the MIT license.
