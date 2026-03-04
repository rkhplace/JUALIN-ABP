# Folder: Exceptions

Folder ini berisi class yang mengatur bagaimana aplikasi menangani error atau exception.

Secara default, Laravel sudah menyediakan `Handler.php` sebagai pusat pengelolaan error. Pada project ini, `Handler.php` telah dimodifikasi untuk memastikan **semua response error dalam route API dikembalikan dalam format JSON**, bukan HTML (halaman error bawaan Laravel).

## Fungsi Utama Handler

- Mengubah error menjadi format JSON yang konsisten.
- Menangani error validasi (`ValidationException`) agar pesan error mudah dipahami di sisi frontend.
- Menyembunyikan detail error (trace) saat `APP_DEBUG=false` sehingga lebih aman di production.
- Mempermudah debugging ketika `APP_DEBUG=true` karena trace error tetap ditampilkan.

## Struktur Response Error

Ketika terjadi error dalam request API, response akan berbentuk seperti ini:

```json
{
  "success": false,
  "message": "Pesan error yang terjadi",
  "type": "NamaException",
  "errors": {
    "field": ["Detail kesalahan jika ada."]
  }
}
