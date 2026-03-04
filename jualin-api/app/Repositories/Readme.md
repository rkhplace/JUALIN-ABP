```md
# Folder: Repositories

Repository bertugas mengatur **akses data ke database** melalui Model.

## Tujuan Repository

- Memisahkan query database dari logika bisnis.
- Memudahkan perubahan sumber data (misal pindah MySQL → Mongo).
- Membuat Service tetap bersih dan mudah di-test.

## Aturan

- Repository hanya melakukan operasi data:
  - find
  - create
  - update
  - delete

- Tidak boleh ada logic bisnis di sini.

## Contoh

```php
public function findByEmail(string $email)
{
    return User::where('email', $email)->first();
}
