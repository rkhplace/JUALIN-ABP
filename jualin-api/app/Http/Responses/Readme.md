```md
# Folder: Responses (ApiResponse)

Folder ini berisi helper untuk memastikan format response API **konsisten** di setiap endpoint.

## Tujuan

- Menghindari perbedaan format response antar controller.
- Membuat API mudah dipakai di frontend.

## Format Response Standar

```json
{
  "success": true,
  "message": "Pesan berhasil",
  "data": { ... }
}

Contoh Penggunaan

return ApiResponse::success('User registered', $user);
return ApiResponse::error('Invalid credentials', null, 401);

