# Folder: lib

Folder `lib` digunakan untuk menyimpan **konfigurasi inti dan helper global** yang dibutuhkan oleh banyak fitur di aplikasi.

Tujuan utama folder ini adalah:
- Menghindari duplikasi konfigurasi.
- Menyediakan satu sumber kebenaran (single source of truth) untuk setup penting.
- Memudahkan pemeliharaan dan scaling aplikasi.

---

## Apa yang Disimpan di Folder Ini?

| Jenis | Contoh | Penjelasan |
|------|--------|-----------|
| Konfigurasi HTTP Client | `fetcher.js` | Untuk melakukan request ke backend Laravel secara konsisten. |
| Konfigurasi Firebase (jika dipakai) | `firebase.js` | Setup Firebase Auth, Firestore, atau Realtime Database. |
| Helper global | `formatDate.js`, `formatCurrency.js` | Fungsi pemrosesan data yang tidak terkait fitur tertentu. |

---

## Hal yang Tidak Boleh Disimpan di Folder Ini
- UI components (harus disimpan di `/components`)
- Business logic per fitur (harus disimpan di `/modules`)
- State management khusus fitur (harus di `/modules/.../store.js`)

---

## Contoh Implementasi Singkat

```js
// src/lib/axios.js
import axios from "axios";

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
});

export default api;
