# 🎓 SPP Ticket - Aplikasi Mobile Pembayaran SPP Sekolah

Aplikasi mobile Flutter untuk sistem pembayaran SPP (Sumbangan Pembinaan Pendidikan) dengan fitur tiket digital, QR Code, dan Barcode.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)
![Laravel](https://img.shields.io/badge/Laravel-11-FF2D20?logo=laravel)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📖 Deskripsi Project

Aplikasi SPP Ticket adalah solusi digital modern untuk sistem pembayaran SPP sekolah. Aplikasi ini memungkinkan siswa untuk:
- Melihat tagihan SPP bulanan
- Melakukan pembayaran secara digital (cash/transfer)
- Mendapatkan tiket digital dengan QR Code dan Barcode
- Menyimpan riwayat pembayaran
- Menampilkan bukti pembayaran yang dapat di-scan

**Desain Figma:** [Ticket Event Booking App](https://www.figma.com/design/XMSQcbY2vwXoo9jhUOxk2z/Ticket-event-Booking-App--Community-)

---

## ✨ Fitur Utama

### 🎨 UI/UX
- ✅ **Splash Screen** - Animasi logo dengan gradient background
- ✅ **Onboarding** - 3 halaman pengenalan fitur dengan smooth indicator
- ✅ **Autentikasi** - Sign In dengan validasi dan error handling
- ✅ **Material Design** - Mengikuti best practices Flutter

### 📱 Fitur Siswa
- ✅ **Dashboard** - Statistik tagihan (lunas vs belum bayar)
- ✅ **Daftar Tagihan** - Melihat semua tagihan SPP bulanan
- ✅ **Status Pembayaran** - Color-coded status (hijau: lunas, kuning: belum bayar)
- ✅ **Tiket Digital** - QR Code & Barcode untuk verifikasi
- ✅ **Riwayat Pembayaran** - Akses tiket pembayaran yang sudah lunas
- ✅ **Pull to Refresh** - Update data terbaru
- ✅ **Empty States** - Ilustrasi ketika tidak ada data

### 🎫 Fitur Tiket Digital
- ✅ **QR Code** - Kode unik untuk scanning cepat
- ✅ **Barcode** - Code 128 format untuk sistem alternatif
- ✅ **Detail Lengkap** - Nama, NIS, kelas, nominal, tanggal bayar
- ✅ **Ticket Design** - Divider dengan circle seperti tiket fisik
- ✅ **Screenshot-able** - Bisa di-screenshot untuk disimpan

### 🔐 Backend (Laravel API)
- ✅ **RESTful API** - Endpoints lengkap untuk auth, tagihan, pembayaran
- ✅ **Role-based Access** - Admin, Petugas, Siswa
- ✅ **Database Seeding** - Test data untuk development
- ✅ **Docker Support** - Easy deployment dengan Docker Compose
- ✅ **WebSocket** - Real-time notifications (Laravel Reverb)

---

## 🏗️ Struktur Project

```
tugas_sekolah/
│
├── lib/                          # Flutter App (Mobile)
│   ├── config/
│   │   └── api_config.dart       # Konfigurasi API endpoints
│   ├── constants/
│   │   ├── app_colors.dart       # Color palette (Teal, Yellow, Dark)
│   │   ├── app_typography.dart   # Typography system (Lato font)
│   │   └── app_theme.dart        # ThemeData lengkap
│   ├── models/
│   │   ├── user_model.dart       # Model User
│   │   ├── queue_model.dart      # Model Antrian
│   │   ├── spp_bill_model.dart   # Model Tagihan SPP
│   │   └── payment_model.dart    # Model Pembayaran
│   ├── services/
│   │   ├── auth_service.dart     # Authentication service
│   │   ├── payment_service.dart  # Payment & bills service
│   │   └── queue_service.dart    # Queue service
│   ├── screens/
│   │   ├── splash/               # Splash screen
│   │   ├── onboarding/           # Onboarding screens
│   │   ├── auth/                 # Sign in/up screens
│   │   ├── home/                 # Home dashboard
│   │   ├── payment/              # Payment screens
│   │   └── ticket/               # Ticket screens (QR, Barcode)
│   ├── widgets/
│   │   └── common/               # Reusable widgets
│   └── main.dart                 # Entry point
│
├── spp-api/                      # Laravel Backend
│   ├── app/
│   │   ├── Http/Controllers/     # API Controllers
│   │   ├── Models/               # Eloquent models
│   │   └── Services/             # Business logic
│   ├── database/
│   │   ├── migrations/           # Database schema
│   │   └── seeders/              # Test data
│   ├── routes/api.php            # API routes
│   └── docker-compose.yml        # Docker configuration
│
├── assets/
│   ├── fonts/                    # Lato font family
│   ├── images/                   # App images & logos
│   ├── icons/                    # Custom icons
│   └── illustrations/            # Empty state illustrations
│
└── docs/
    ├── API_DOCUMENTATION.md      # API docs lengkap
    ├── APP_SUMMARY.md            # Summary implementasi
    └── QUICK_START.md            # Quick start guide
```

---

## 🛠️ Tech Stack

### Frontend (Mobile)
| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | 3.9.2+ | Cross-platform framework |
| Dart | 3.9.2+ | Programming language |
| Provider | ^6.1.1 | State management |
| Go Router | ^12.1.3 | Navigation & routing |
| HTTP | ^1.1.0 | API calls |
| Shared Preferences | ^2.2.2 | Local storage |

### UI & Animation
| Package | Purpose |
|---------|---------|
| `qr_flutter` | QR Code generation |
| `barcode_widget` | Barcode generation |
| `mobile_scanner` | QR/Barcode scanner |
| `flutter_animate` | Smooth animations |
| `smooth_page_indicator` | Onboarding indicator |
| `shimmer` | Loading skeleton |
| `intl` | Number & date formatting |
| `flutter_svg` | SVG support |

### Backend (API)
| Technology | Purpose |
|-----------|---------|
| Laravel 11 | PHP framework |
| MySQL 8.0 | Database |
| Laravel Sanctum | API authentication |
| Laravel Reverb | WebSocket server |
| Docker & Docker Compose | Containerization |

---

## 🚀 Cara Menjalankan

### Prerequisites

Pastikan sudah terinstall:
- ✅ Flutter SDK 3.9.2 atau lebih baru
- ✅ Dart SDK
- ✅ Android Studio / VS Code
- ✅ Docker & Docker Compose (untuk backend)
- ✅ Git

### 1️⃣ Clone Repository

```bash
git clone <repository-url>
cd tugas_sekolah
```

### 2️⃣ Setup Backend (Laravel API)

```bash
# Masuk ke folder backend
cd spp-api

# Start Docker containers
docker-compose up -d

# Tunggu hingga semua container running
docker ps

# Database akan otomatis termigrasi dan di-seed dengan test data
```

**Backend Services:**
- API Server: http://localhost:8000
- phpMyAdmin: http://localhost:8081
- MySQL: Port 3307

**Test Accounts:**
- **Siswa**: `budi@siswa.com` / `password`
- **Petugas**: `petugas1@spp.com` / `password`
- **Admin**: `admin@spp.com` / `password`

### 3️⃣ Setup Flutter App

```bash
# Kembali ke root project
cd ..

# Install dependencies
flutter pub get

# Check connected devices
flutter devices
```

### 4️⃣ Konfigurasi API URL

Edit `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Ganti dengan IP komputer Anda jika testing di device fisik
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Untuk device fisik, gunakan IP komputer:
  // static const String baseUrl = 'http://192.168.0.132:8000/api';
}
```

**Note:** Untuk testing di device fisik, HP dan komputer harus terhubung ke WiFi yang sama.

### 5️⃣ Run Aplikasi

#### Opsi A: Android Emulator
```bash
# Start emulator
flutter emulators --launch <emulator_id>

# Run app
flutter run
```

#### Opsi B: Physical Device
```bash
# Enable USB Debugging di device
# Sambungkan via USB

# Check device
flutter devices

# Run app
flutter run
```

#### Opsi C: iOS Simulator (Mac only)
```bash
# Start simulator
open -a Simulator

# Run app
flutter run
```

---

## 🧪 Testing

### Run Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Manual Testing Flow

1. **Launch App** → Lihat splash screen (3 detik)
2. **Onboarding** → Swipe 3 halaman atau klik "Lewati"
3. **Login** → Gunakan `budi@siswa.com` / `password`
4. **Home Screen** → Lihat tagihan SPP (1 belum bayar, 2 lunas)
5. **My Tickets** → Klik tab "Tiket Saya", lihat 2 tiket
6. **Ticket Detail** → Klik "Lihat Tiket", lihat QR & Barcode
7. **Screenshot** → Screenshot tiket untuk disimpan

---

## 🎨 Design System

### Color Palette
```dart
// Primary Colors
primary04: #17907C (Teal)
primary05: #1CAD95 (Teal Light)

// Secondary Colors
secondary04: #FFCC71 (Yellow)

// Neutral Colors
dark: #282F2E
white: #FFFFFF
neutral01-10: Grayscale palette
```

### Typography
```dart
Font Family: Lato
Weights: Regular (400), Medium (500), Bold (700), Black (900)

Heading 1: 48px / Black
Heading 2: 40px / Black
Heading 3: 32px / Bold
Heading 4: 24px / Bold
Heading 5: 20px / Bold
Heading 6: 18px / Bold

Paragraph Large: 16px
Paragraph Medium: 14px
Paragraph Small: 12px
Paragraph XSmall: 10px
```

---

## 📱 Screenshots & Flow

```
Splash Screen
     ↓
Onboarding (3 pages)
     ↓
Sign In
     ↓
Home Dashboard
     ├─→ Tagihan List
     │       ↓
     │   (Detail Tagihan)
     │       ↓
     │   (Proses Pembayaran)
     │
     └─→ My Tickets
             ↓
         Ticket Detail
         (QR Code + Barcode)
```

---

## 🔧 Development

### Hot Reload & Restart
```bash
# Hot reload (di terminal yang running)
r

# Hot restart (restart app)
R

# Quit app
q
```

### Clean & Rebuild
```bash
flutter clean
flutter pub get
flutter run
```
### Format Code
```bash
flutter format lib/
```

### Analyze Code
```bash
flutter analyze
```

---

## 📦 Build untuk Production

### Android APK (Debug)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Android APK (Release)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Mac only)
```bash
flutter build ios --release
```

---

## 📡 API Endpoints

### Authentication
```
POST   /api/auth/login          # Login
POST   /api/auth/register       # Register (siswa)
POST   /api/auth/logout         # Logout
GET    /api/auth/profile        # Get profile
PUT    /api/auth/profile        # Update profile
```

### Payments & Bills
```
GET    /api/payments/my-bills              # List tagihan siswa
GET    /api/payments/unpaid-bills          # Tagihan belum bayar
GET    /api/payments/my-payments           # Riwayat pembayaran
POST   /api/payments/bills/{id}/pay        # Bayar tagihan
PUT    /api/payments/{id}/upload-proof     # Upload bukti transfer
```

### Queue System
```
GET    /api/queues/my-queues       # Riwayat antrian
POST   /api/queues/create          # Ambil antrian
GET    /api/queues/active          # Antrian aktif hari ini
POST   /api/queues/{id}/call       # Panggil antrian (petugas)
PUT    /api/queues/{id}/status     # Update status antrian
```

Dokumentasi lengkap: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

---

## 🐛 Troubleshooting

### Error: Gradle Build Failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: Cannot Connect to API
1. Pastikan Docker backend running: `docker ps`
2. Test API endpoint: `curl http://localhost:8000/api/auth/login`
3. Cek IP komputer: `hostname -I` (Linux) atau `ipconfig` (Windows)
4. Update `api_config.dart` dengan IP yang benar
5. Pastikan HP dan komputer di WiFi yang sama

### Error: Font Not Found
```bash
flutter clean
flutter pub get
# Font Lato sudah ada di assets/fonts/
```

### Error: QR Code Not Showing
- Pastikan package `qr_flutter` terinstall
- Restart app dengan `R`
- Check console untuk error messages

### Device Not Detected
```bash
# Check devices
flutter devices

# Pastikan:
# ✅ USB Debugging enabled (Android)
# ✅ Cable USB berfungsi
# ✅ Driver USB terinstall (Windows)
# ✅ "Trust This Computer" (iOS)
```

---

## 📚 Dokumentasi Lengkap

- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - Dokumentasi API Laravel lengkap
- **[APP_SUMMARY.md](APP_SUMMARY.md)** - Summary fitur & implementasi
- **[QUICK_START.md](QUICK_START.md)** - Quick start guide
- **[FLUTTER_APP_README.md](FLUTTER_APP_README.md)** - Flutter app details

---

## 🎯 Roadmap & Future Features

### ✅ Phase 1 (Completed)
- [x] Splash Screen dengan animasi
- [x] Onboarding 3 halaman
- [x] Sign In screen
- [x] Home dashboard dengan statistik
- [x] Daftar tagihan SPP
- [x] My Tickets screen
- [x] Ticket Detail dengan QR & Barcode
- [x] Backend API (Laravel + Docker)
- [x] Database seeding

### 🚧 Phase 2 (In Progress)
- [ ] Sign Up / Registrasi siswa
- [ ] Detail tagihan & proses pembayaran
- [ ] Upload bukti transfer
- [ ] Payment confirmation screen
- [ ] Push notifications untuk tagihan jatuh tempo

### 📋 Phase 3 (Planned)
- [ ] Profile & Settings screen
- [ ] Edit profile
- [ ] Riwayat lengkap (filter, search)
- [ ] Export/Download tiket sebagai PDF
- [ ] Share tiket via WhatsApp/Email
- [ ] Dark mode support
- [ ] Multi-language (ID/EN)
- [ ] QR Scanner untuk petugas
- [ ] Dashboard admin/petugas
- [ ] Real-time notifications (WebSocket)
- [ ] Fingerprint/Face ID authentication

---

## 🤝 Contributing

Contributions are welcome! Untuk berkontribusi:

1. Fork repository ini
2. Buat branch baru (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

---

## 📄 License

This project is licensed under the MIT License - lihat file [LICENSE](LICENSE) untuk detail.

---

## 👨‍💻 Developer

Dikembangkan dengan ❤️ menggunakan Flutter & Laravel

**Contact & Support:**
- Buka issue untuk bug reports
- Pull requests are welcome
- Star repository ini jika bermanfaat! ⭐

---

## 🙏 Acknowledgments

- **Design**: Based on [Ticket Event Booking App](https://www.figma.com/community) Figma template
- **Fonts**: [Google Fonts - Lato](https://fonts.google.com/specimen/Lato)
- **Icons**: [Material Icons](https://fonts.google.com/icons)
- **Framework**: [Flutter](https://flutter.dev) & [Laravel](https://laravel.com)

---

## 📊 Project Status

![Status](https://img.shields.io/badge/Status-Active_Development-success)
![Frontend](https://img.shields.io/badge/Frontend-80%25-blue)
![Backend](https://img.shields.io/badge/Backend-100%25-success)
![Tests](https://img.shields.io/badge/Tests-Passing-success)

**Last Updated:** October 2024

---

**Happy Coding! 🚀**

*Note: Aplikasi ini dibuat untuk keperluan pendidikan. Untuk production, pastikan sudah melakukan security audit, testing menyeluruh, dan konfigurasi yang sesuai.*

