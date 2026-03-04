```md
# Folder: Models

Model mewakili tabel dalam database dan berfungsi sebagai representasi data dalam aplikasi.

## Peran Model

- Mapping kolom database → attribute object
- Mendefinisikan relasi antar tabel (hasMany, belongsTo, dll)
- Casting atribut ke tipe yang benar

## Aturan

- Jangan letakkan **logika bisnis** di Model.
- Simpan logic di Service, Model hanya menyimpan definisi data.

## Contoh

```php
class User extends Model
{
    protected $fillable = ['username', 'email', 'password'];
}
