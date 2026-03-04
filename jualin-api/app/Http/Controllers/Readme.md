# Folder: Controllers

Folder ini berisi class **Controller**, yaitu titik masuk (entrypoint) dari setiap request yang datang ke API.

## Peran Controller

- Menerima request dari client (frontend / mobile).
- Memanggil **Service** untuk menjalankan logika bisnis.
- Mengembalikan response (biasanya menggunakan `ApiResponse`).
- Tidak boleh berisi logika bisnis yang kompleks.

## Aturan Penulisan

- Simpan controller per fitur, contoh:
  - `AuthController.php`
  - `UserController.php`
  - `ProductController.php`

- **Controller harus tetap tipis**.  
  Maksimal hanya:
  1. Terima input (lewat Request Form)
  2. Panggil Service
  3. Return response

## Contoh Alur
Request → Controller → Service → Repository → Database

Controller tidak pernah langsung berinteraksi dengan database.

