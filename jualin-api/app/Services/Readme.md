```md
# Folder: Services

Service berisi **logika bisnis utama** aplikasi.

## Peran Service

- Mengatur alur proses (use case).
- Memanggil Repository untuk mengakses data.
- Mengelola transaksi dan aturan domain.

## Controller vs Service

| Controller | Service |
|-----------|---------|
| Mengatur request/response | Mengatur bisnis proses |
| Tidak boleh ada logic berat | Logic utama ada di sini |

## Contoh

```php
public function login(array $credentials)
{
    // validasi dan proses login ada di sini
}
