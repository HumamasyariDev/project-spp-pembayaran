# 🚀 Quick Start - Docker Desktop

## ✅ Persiapan:

1. **Docker Desktop sudah terinstall dan running** ✅
2. **Port tersedia:** 8000, 3307, 8080

---

## 📝 Langkah-Langkah:

### 1. Setup Environment File

```bash
cd /opt/lampp/htdocs/tugas_sekolah/spp-api

# Copy env file
cp .env.docker .env

# Generate APP_KEY
docker run --rm -v $(pwd):/app composer:latest bash -c "cd /app && php artisan key:generate"
```

### 2. Jalankan Dengan Script (MUDAH!)

```bash
./docker-start.sh
```

**Atau manual:**

```bash
# Build images
docker compose build

# Start containers
docker compose up -d

# Wait for MySQL (15-20 detik)
sleep 15

# Run migrations
docker compose exec app php artisan migrate:fresh --seed

# Create storage link
docker compose exec app php artisan storage:link
```

### 3. Test API

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"budi@siswa.com","password":"password"}'
```

---

## 📍 Endpoint & Ports:

| Service | URL | Port |
|---------|-----|------|
| **API** | http://localhost:8000/api | 8000 |
| **WebSocket** | ws://localhost:8080 | 8080 |
| **MySQL** | localhost:3307 | 3307 |

---

## 🛠️ Command Berguna:

### Lihat Status:
```bash
docker compose ps
```

### Lihat Logs:
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app
docker compose logs -f mysql
```

### Masuk ke Container:
```bash
# Laravel
docker compose exec app bash

# MySQL
docker compose exec mysql bash
docker compose exec mysql mysql -u root -proot spp_api
```

### Artisan Commands:
```bash
docker compose exec app php artisan migrate
docker compose exec app php artisan db:seed
docker compose exec app php artisan cache:clear
docker compose exec app php artisan route:list
```

### Stop/Start:
```bash
# Stop
docker compose stop

# Start
docker compose start

# Restart
docker compose restart

# Stop & Remove (data tetap ada)
docker compose down

# Stop & Remove + Delete data
docker compose down -v
```

---

## 📱 Update Flutter App:

Edit `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api';
  // Untuk Android Emulator gunakan: http://10.0.2.2:8000/api
  // Untuk Device Fisik gunakan: http://IP_KOMPUTER:8000/api
}
```

---

## 🔧 Troubleshooting:

### Port 8000 already in use
```bash
# Stop LAMPP
sudo /opt/lampp/lampp stop

# Atau cek process
sudo lsof -i :8000
```

### MySQL not ready
```bash
# Tunggu lebih lama, cek health:
docker compose ps

# Restart MySQL
docker compose restart mysql
```

### Permission Error
```bash
docker compose exec app chmod -R 775 storage bootstrap/cache
docker compose exec app chown -R www-data:www-data storage
```

### Start Fresh
```bash
# Remove everything
docker compose down -v

# Rebuild
docker compose build --no-cache

# Start again
./docker-start.sh
```

---

## 🎯 Test Endpoints:

### Login:
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"budi@siswa.com","password":"password"}'
```

### Get Profile:
```bash
TOKEN="your_token_here"
curl http://localhost:8000/api/auth/profile \
  -H "Authorization: Bearer $TOKEN"
```

### Get Bills:
```bash
curl http://localhost:8000/api/payments/my-bills \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🎉 Selesai!

API sudah running di Docker! 

**Keuntungan:**
- ✅ Tidak perlu LAMPP
- ✅ Environment konsisten
- ✅ Mudah di-share dengan tim
- ✅ Port tidak bentrok
- ✅ Bisa running parallel dengan project lain

**Update Flutter** untuk connect ke `http://localhost:8000/api`

Happy Coding! 🚀
