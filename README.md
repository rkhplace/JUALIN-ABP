# Jualin

Jualin adalah platform marketplace multi-peran yang menghubungkan pembeli dan
penjual melalui aplikasi web dan mobile. Sistem ini menyediakan pengelolaan
produk, transaksi, pembayaran, dompet, chat, laporan pengguna/produk, notifikasi,
serta backoffice admin dalam satu ekosistem.

Repository ini menggunakan struktur multi-application:

- `jualin-api` - REST API dan business logic.
- `jualin` - aplikasi web.
- `mobile_app` - aplikasi mobile.

## Daftar Isi

- [Arsitektur Singkat](#arsitektur-singkat)
- [Tech Stack](#tech-stack)
- [Prasyarat](#prasyarat)
- [Getting Started](#getting-started)
  - [1. Backend API](#1-backend-api-laravel)
  - [2. Frontend Web](#2-frontend-web-nextjs)
  - [3. Aplikasi Mobile](#3-aplikasi-mobile-flutter)
- [Testing](#testing)
- [Struktur Folder](#struktur-folder)
- [Perintah Berguna](#perintah-berguna)
- [Troubleshooting](#troubleshooting)

## Arsitektur Singkat

```text
Next.js Web ----\
                 +--> HTTP/JSON + JWT --> Laravel REST API --> Database
Flutter Mobile -/                              |
                                               +--> Midtrans
                                               +--> Firebase
                                               +--> Mail / Resend
```

Alur utamanya:

1. Web atau mobile mengirim request ke endpoint `/api/v1`.
2. Laravel memvalidasi request melalui Form Request dan middleware.
3. Controller meneruskan proses ke service/repository atau model terkait.
4. Endpoint terproteksi menggunakan JWT Bearer Token.
5. Hak akses dibatasi berdasarkan role `customer`, `seller`, dan `admin`.
6. Web menyimpan state autentikasi melalui `AuthProvider` dan data server melalui
   React Query.
7. Mobile menggunakan service layer dan `SharedPreferences` untuk sesi lokal.

Integrasi Firebase digunakan untuk fitur chat/auth pendukung dan push
notification. Midtrans digunakan untuk alur pembayaran.

## Tech Stack

### Backend - `jualin-api`

- PHP 8.2+
- Laravel 12
- Eloquent ORM
- JWT Auth (`tymon/jwt-auth`)
- Laravel Sanctum
- SQLite sebagai konfigurasi lokal paling sederhana
- Dukungan MySQL, MariaDB, PostgreSQL, dan SQL Server
- Midtrans PHP SDK
- Firebase Admin SDK (`kreait/firebase-php`)
- Resend/Symfony Mailer
- PHPUnit 11
- Vite dan Tailwind CSS untuk resource Laravel

### Frontend Web - `jualin`

- Next.js 16 dengan App Router
- React 19
- JavaScript/JSX
- Tailwind CSS 4
- Axios
- TanStack React Query
- Firebase Web SDK
- Recharts
- Jest dan React Testing Library

### Mobile - `mobile_app`

- Flutter
- Dart
- Material 3
- HTTP client
- Shared Preferences
- Firebase Core dan Firebase Cloud Messaging
- Flutter Local Notifications
- QR Flutter dan Mobile Scanner
- Image Picker
- Flutter Test dan Flutter Lints

## Prasyarat

Pastikan perangkat development memiliki:

- Git
- PHP `>= 8.2`
- Composer 2.x
- Node.js `>= 20.9` dan npm
- Flutter stable `>= 3.38.4`
- Dart `>= 3.10.3`
- Java/JDK 17 untuk build Android
- Android Studio dan Android SDK untuk Android
- Xcode dan CocoaPods untuk build iOS/macOS

Ekstensi PHP yang umum dibutuhkan:

- `ctype`
- `curl`
- `fileinfo`
- `mbstring`
- `openssl`
- `pdo`
- `pdo_sqlite` atau driver database lain yang digunakan
- `tokenizer`
- `xml`
- `gd` untuk test yang membuat gambar palsu

Periksa instalasi lokal:

```bash
php --version
composer --version
node --version
npm --version
flutter doctor
```

Integrasi berikut bersifat opsional untuk setup dasar, tetapi wajib jika
fiturnya ingin digunakan:

- Akun dan project Firebase
- Akun Midtrans beserta server/client key
- Konfigurasi SMTP atau Resend

## Getting Started

Clone repository lalu masuk ke direktori proyek:

```bash
git clone <repository-url>
cd JUALIN-ABP
```

> `composer.json` dan `package.json` di root bukan orchestrator utama
> repository. Jalankan instalasi dari masing-masing folder aplikasi.

### 1. Backend API (Laravel)

Masuk ke direktori backend:

```bash
cd jualin-api
```

Instal dependency PHP dan asset tooling Laravel:

```bash
composer install
npm install
```

#### Konfigurasi environment

Repository belum menyediakan `.env.example`, sehingga buat file
`jualin-api/.env` secara manual. Konfigurasi minimal untuk SQLite:

```dotenv
APP_NAME=Jualin
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000
FRONTEND_URL=http://localhost:3000

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=sqlite

CACHE_STORE=database
SESSION_DRIVER=database
QUEUE_CONNECTION=database

FILESYSTEM_DISK=public

MAIL_MAILER=log
MAIL_FROM_ADDRESS="no-reply@jualin.local"
MAIL_FROM_NAME="${APP_NAME}"

JWT_SECRET=
JWT_TTL=1440
JWT_REFRESH_TTL=20160

MIDTRANS_SERVER_KEY=
MIDTRANS_CLIENT_KEY=
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_IS_SANITIZED=true
MIDTRANS_IS_3DS=true
```

Jangan commit file `.env` atau credential layanan eksternal.

Buat database SQLite secara cross-platform:

```bash
php -r "file_exists('database/database.sqlite') || touch('database/database.sqlite');"
```

Generate application key dan JWT secret:

```bash
php artisan key:generate
php artisan jwt:secret
```

Jalankan migration:

```bash
php artisan migrate
```

Untuk mengisi data development:

```bash
php artisan db:seed
```

Atau reset database dan seed ulang:

```bash
php artisan migrate:fresh --seed
```

Buat symbolic link untuk file upload publik:

```bash
php artisan storage:link
```

Jalankan API pada port `8000`:

```bash
php artisan serve --host=127.0.0.1 --port=8000
```

API tersedia di:

```text
http://localhost:8000/api/v1
```

Health check Laravel tersedia di:

```text
http://localhost:8000/up
```

Jika membutuhkan queue worker, jalankan terminal tambahan:

```bash
php artisan queue:listen --tries=1
```

Sebagai alternatif, script berikut menjalankan server, queue, log viewer, dan
Vite Laravel secara bersamaan:

```bash
composer run dev
```

#### Konfigurasi database selain SQLite

Contoh MySQL:

```dotenv
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=jualin
DB_USERNAME=root
DB_PASSWORD=
```

Setelah mengubah database:

```bash
php artisan optimize:clear
php artisan migrate --seed
```

#### Firebase backend

Backend mencari Firebase service account melalui salah satu konfigurasi:

```dotenv
FIREBASE_CREDENTIALS_JSON={"type":"service_account","project_id":"..."}
```

atau:

```dotenv
FIREBASE_CREDENTIALS_BASE64=<base64-json-service-account>
```

Alternatif lainnya adalah menaruh file credential pada:

```text
jualin-api/storage/app/firebase-credentials.json
```

File tersebut sudah diabaikan oleh Git.

### 2. Frontend Web (Next.js)

Buka terminal baru:

```bash
cd jualin
npm install
```

Buat file `jualin/.env.local`:

```dotenv
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_MIDTRANS_CLIENT_KEY=

NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=
```

`NEXT_PUBLIC_API_URL` adalah origin backend tanpa akhiran `/api/v1`, karena
service web sudah menambahkan path tersebut.

Jalankan development server:

```bash
npm run dev
```

Buka:

```text
http://localhost:3000
```

Build dan jalankan mode production secara lokal:

```bash
npm run build
npm run start
```

Next.js juga memiliki rewrite `/api/v1/*` menuju backend yang ditentukan oleh
`NEXT_PUBLIC_API_URL`.

### 3. Aplikasi Mobile (Flutter)

Buka terminal baru:

```bash
cd mobile_app
flutter pub get
flutter doctor
flutter devices
```

Secara default mobile menggunakan API deployment yang didefinisikan di
`lib/services/api_config.dart`. Untuk development lokal, override URL melalui
`--dart-define`.

#### Android emulator

Android emulator menggunakan `10.0.2.2` untuk mengakses localhost komputer:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

#### iOS simulator, desktop, atau web

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

#### Perangkat fisik

Jalankan backend agar dapat diakses dari jaringan lokal:

```bash
cd jualin-api
php artisan serve --host=0.0.0.0 --port=8000
```

Gunakan alamat IP komputer:

```bash
cd mobile_app
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Pastikan perangkat dan komputer berada pada jaringan yang sama serta firewall
mengizinkan port `8000`.

#### Firebase dan push notification Android

Untuk konfigurasi native, letakkan file Firebase Android pada:

```text
mobile_app/android/app/google-services.json
```

Plugin Google Services hanya diaktifkan jika file tersebut tersedia.

Mobile juga mendukung Firebase options melalui compile-time variable:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=FIREBASE_ANDROID_API_KEY=<firebase-api-key> --dart-define=FIREBASE_ANDROID_APP_ID=<firebase-app-id> --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender-id> --dart-define=FIREBASE_PROJECT_ID=<project-id>
```

Implementasi push notification saat ini diaktifkan khusus untuk Android.

## Testing

### Backend

Jalankan seluruh test:

```bash
cd jualin-api
composer test
```

Atau:

```bash
php artisan test
```

Unit test:

```bash
php artisan test --testsuite=Unit
```

Feature test:

```bash
php artisan test --testsuite=Feature
```

Test atau method tertentu:

```bash
php artisan test --filter=AuthServiceTest
php artisan test --filter=testLoginInvalidCredentialsReturnsError
```

Test backend menggunakan SQLite in-memory berdasarkan `phpunit.xml`. Pastikan
ekstensi `pdo_sqlite` aktif. Test upload gambar juga membutuhkan ekstensi `gd`.

### Frontend Web

Jalankan seluruh Jest test:

```bash
cd jualin
npm test -- --runInBand
```

Watch mode:

```bash
npm run test:watch
```

Test file tertentu:

```bash
npx jest src/__tests__/features/auth.test.jsx --runInBand
```

Coverage:

```bash
npm test -- --coverage --runInBand
```

### Mobile

Static analysis:

```bash
cd mobile_app
flutter analyze
```

Jalankan seluruh test:

```bash
flutter test
```

Test file tertentu:

```bash
flutter test test/auth_service_remember_me_test.dart
```

## Struktur Folder

```text
JUALIN-ABP/
|-- jualin-api/                 # Laravel REST API
|   |-- app/
|   |   |-- Http/
|   |   |   |-- Controllers/   # Endpoint HTTP
|   |   |   |-- Middleware/    # Auth dan role authorization
|   |   |   `-- Requests/      # Request validation
|   |   |-- Models/            # Eloquent models
|   |   |-- Repositories/      # Data access
|   |   `-- Services/          # Business logic dan integrasi
|   |-- config/                # Konfigurasi Laravel dan integrasi
|   |-- database/
|   |   |-- migrations/
|   |   `-- seeders/
|   |-- routes/api.php         # Route REST API v1
|   `-- tests/                 # Unit dan feature test
|
|-- jualin/                     # Next.js web application
|   |-- src/
|   |   |-- app/               # App Router pages dan layouts
|   |   |-- components/        # UI dan feature components
|   |   |-- context/           # Global React context
|   |   |-- hooks/             # Custom hooks dan React Query
|   |   |-- lib/               # Axios/fetcher dan Firebase setup
|   |   |-- services/          # API service modules
|   |   `-- __tests__/         # Jest/RTL tests
|   |-- next.config.mjs
|   `-- package.json
|
|-- mobile_app/                 # Flutter application
|   |-- lib/
|   |   |-- models/            # Model aplikasi
|   |   |-- navigation/        # Navigation helpers
|   |   |-- screens/           # Halaman aplikasi
|   |   |-- services/          # API, auth, notification, dan domain services
|   |   |-- utils/             # Utility dan formatter
|   |   `-- widgets/           # Reusable widgets
|   |-- test/                  # Flutter tests
|   |-- android/
|   |-- ios/
|   `-- pubspec.yaml
|
`-- README.md
```

## Perintah Berguna

### Laravel

```bash
php artisan route:list
php artisan migrate:status
php artisan optimize:clear
php artisan storage:link
php artisan queue:listen
```

Format kode PHP:

```bash
vendor/bin/pint
```

Pada Windows PowerShell:

```powershell
php vendor\bin\pint
```

### Next.js

```bash
npm run dev
npm run build
npm run start
npm test
```

### Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk
flutter build appbundle
```

## Troubleshooting

### Web tidak dapat mengakses API

- Pastikan Laravel berjalan di `http://localhost:8000`.
- Pastikan `NEXT_PUBLIC_API_URL=http://localhost:8000`.
- Restart Next.js setelah mengubah `.env.local`.
- Origin development yang sudah diizinkan CORS adalah
  `http://localhost:3000`.

### Android emulator tidak dapat mengakses localhost

Gunakan:

```text
http://10.0.2.2:8000/api/v1
```

bukan `http://localhost:8000/api/v1`.

### File gambar tidak tampil

Jalankan:

```bash
cd jualin-api
php artisan storage:link
```

Pastikan `APP_URL` sesuai dengan URL backend.

### Perubahan `.env` Laravel tidak terbaca

```bash
php artisan optimize:clear
```

### JWT login gagal karena secret tidak tersedia

```bash
php artisan jwt:secret
php artisan optimize:clear
```

### Firebase tidak aktif

- Web: periksa seluruh variable `NEXT_PUBLIC_FIREBASE_*`.
- Backend: periksa Firebase service account.
- Android: periksa `google-services.json` atau nilai `--dart-define`.
- Jangan commit private key atau service-account JSON.

## Catatan Keamanan

- Jangan commit `.env`, Firebase service account, Midtrans server key, atau
  credential database.
- Gunakan credential sandbox untuk development.
- Ganti seluruh credential development sebelum deployment production.
- Simpan secret production pada secret manager milik platform deployment.
