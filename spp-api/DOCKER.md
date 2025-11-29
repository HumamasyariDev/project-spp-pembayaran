# 🐳 Docker Setup - SPP Payment API

## ✅ Keuntungan Menggunakan Docker:

1. **Portabel** - Bisa running dimana saja (Linux, Mac, Windows)
2. **Konsisten** - Environment yang sama di semua tempat
3. **Mudah Setup** - Tidak perlu install PHP, MySQL, Nginx manual
4. **Isolated** - Tidak bentrok dengan LAMPP atau service lain
5. **Production-Ready** - Siap deploy ke cloud

---

## 📦 Struktur Docker:

```
spp-api/
├── Dockerfile                    # Image untuk Laravel
├── docker-compose.yml            # Orchestration services
├── .dockerignore                 # File yang diabaikan
├── .env.docker                   # Environment untuk Docker
└── docker/
    ├── nginx/
    │   ├── nginx.conf           # Nginx config
    │   └── default.conf         # Laravel vhost config
    └── supervisor/
        └── supervisord.conf     # Process manager
```

---

## 🚀 Cara Menjalankan:

### 1. **Persiapan**

Pastikan Docker dan Docker Compose terinstall:
```bash
docker --version
docker-compose --version
```

Jika belum, install:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose

# Atau gunakan Docker Desktop (Linux/Mac/Windows)
# Download dari: https://www.docker.com/products/docker-desktop
```

### 2. **Setup Environment**

Copy environment file untuk Docker:
```bash
cd /opt/lampp/htdocs/tugas_sekolah/spp-api
cp .env.docker .env
```

Generate application key:
```bash
docker run --rm -v $(pwd):/app composer:latest bash -c "cd /app && php artisan key:generate"
```

Atau generate manual dan update `.env`:
```bash
php artisan key:generate --show
```

### 3. **Build & Start Containers**

```bash
# Build images
docker-compose build

# Start semua services (detached mode)
docker-compose up -d
```

Ini akan start 3 containers:
- **spp_mysql** - MySQL Database (port 3307)
- **spp_app** - Laravel API (port 8000)
- **spp_reverb** - WebSocket Server (port 8080)

### 4. **Setup Database**

Jalankan migration dan seeding:
```bash
# Masuk ke container
docker-compose exec app bash

# Di dalam container:
php artisan migrate:fresh --seed

# Keluar dari container
exit
```

Atau langsung:
```bash
docker-compose exec app php artisan migrate:fresh --seed
docker-compose exec app php artisan storage:link
```

---

## 🎯 Akses API:

### API Endpoint:
```
http://localhost:8000/api
```

### Test API:
```bash
curl http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"budi@siswa.com","password":"password"}'
```

### WebSocket:
```
ws://localhost:8080
```

---

## 📱 Update Flutter App:

Karena API sekarang running di Docker, update `lib/config/api_config.dart`:

**Untuk Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

**Untuk iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**Untuk Device Fisik:**
```dart
static const String baseUrl = 'http://IP_KOMPUTER:8000/api';
```

---

## 🛠️ Docker Commands:

### Lihat Status Containers:
```bash
docker-compose ps
```

### Lihat Logs:
```bash
# Semua services
docker-compose logs -f

# Service tertentu
docker-compose logs -f app
docker-compose logs -f mysql
docker-compose logs -f reverb
```

### Stop Containers:
```bash
docker-compose stop
```

### Start Containers:
```bash
docker-compose start
```

### Restart Containers:
```bash
docker-compose restart
```

### Stop & Remove Containers:
```bash
docker-compose down
```

### Stop & Remove Containers + Volumes (hapus data):
```bash
docker-compose down -v
```

### Rebuild Containers:
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Masuk ke Container:
```bash
# Laravel app
docker-compose exec app bash

# MySQL
docker-compose exec mysql bash
```

### Jalankan Artisan Commands:
```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:list
docker-compose exec app php artisan queue:work
```

### Akses MySQL:
```bash
# Dari host
mysql -h 127.0.0.1 -P 3307 -u root -p
# Password: root

# Dari container
docker-compose exec mysql mysql -u root -p spp_api
```

---

## 📊 Ports yang Digunakan:

| Service | Port Internal | Port External | Deskripsi |
|---------|---------------|---------------|-----------|
| MySQL | 3306 | 3307 | Database |
| Laravel | 80 | 8000 | API Server |
| Reverb | 8080 | 8080 | WebSocket |

---

## 🔧 Troubleshooting:

### Port Already in Use
```bash
# Check port yang digunakan
sudo lsof -i :8000
sudo lsof -i :3307
sudo lsof -i :8080

# Stop LAMPP jika running
sudo /opt/lampp/lampp stop

# Atau ubah port di docker-compose.yml
```

### Permission Denied
```bash
# Fix storage permissions
docker-compose exec app chmod -R 775 storage bootstrap/cache
docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
```

### Database Connection Error
```bash
# Restart MySQL container
docker-compose restart mysql

# Check MySQL logs
docker-compose logs mysql

# Wait for MySQL healthy
docker-compose ps
```

### Clear Everything & Start Fresh
```bash
# Stop & remove all
docker-compose down -v

# Remove images
docker rmi spp-api_app spp-api_reverb

# Rebuild
docker-compose build --no-cache
docker-compose up -d

# Setup database
docker-compose exec app php artisan migrate:fresh --seed
```

---

## 🚀 Deploy ke Production:

### 1. Update Environment:
```env
APP_ENV=production
APP_DEBUG=false
```

### 2. Optimize Laravel:
```bash
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
docker-compose exec app php artisan optimize
```

### 3. Setup HTTPS (dengan nginx-proxy + Let's Encrypt)

### 4. Enable Queue Worker:
Tambahkan ke `supervisord.conf`:
```ini
[program:laravel-queue]
command=php /var/www/html/artisan queue:work
```

---

## 📝 Backup Database:

### Backup:
```bash
docker-compose exec mysql mysqldump -u root -proot spp_api > backup.sql
```

### Restore:
```bash
docker-compose exec -T mysql mysql -u root -proot spp_api < backup.sql
```

---

## 🎉 Keuntungan Docker untuk Project Ini:

✅ **Tidak perlu LAMPP** - Docker handle semuanya  
✅ **Konsisten** - Development = Production environment  
✅ **Mudah share** - Tim lain tinggal `docker-compose up`  
✅ **Auto-restart** - Container restart otomatis jika crash  
✅ **Scalable** - Mudah add service baru (Redis, etc)  
✅ **Clean** - Hapus semua dengan `docker-compose down -v`

---

## 📚 Resources:

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Laravel Docker](https://laravel.com/docs/sail)

---

**🐳 Happy Dockerizing! 🚀**
