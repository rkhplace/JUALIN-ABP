# Folder: Middleware

Middleware digunakan untuk memproses *request sebelum atau sesudah* melewati Controller.

## Kapan Middleware Digunakan?

- Proteksi route (auth)
- Pembatasan role (admin, seller, customer)
- Memaksa response JSON (`ForceJsonResponse`)
- Logging request

## Contoh Penggunaan

```php
Route::middleware('auth:api')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
});
