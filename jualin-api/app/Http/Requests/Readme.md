```md
# Folder: Requests (FormRequest)

Folder ini berisi class **Form Request**, yaitu validator input dari user.

## Peran Request

- Menentukan aturan validasi (rules).
- Menentukan pesan error jika input salah.
- Mencegah data kotor masuk ke Service.

## Keuntungan

- Controller tidak penuh dengan kode validasi.
- Kode lebih bersih dan mudah dirawat.
- Tingkat keamanan data lebih baik.

## Contoh

```php
public function rules(): array
{
    return [
        'email' => 'required|email',
        'password' => 'required|min:8'
    ];
}
