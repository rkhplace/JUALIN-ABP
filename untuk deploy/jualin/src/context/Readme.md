```md
# Folder: context

Folder `context` menyimpan **React Context Provider** yang digunakan untuk **state global** aplikasi, terutama yang diperlukan lintas halaman dan mempengaruhi alur navigasi.

---

## Kapan Context Digunakan?

Gunakan context ketika:
- Data harus tersedia di banyak halaman.
- Aplikasi perlu **menentukan akses halaman** (contoh: halaman private butuh login).
- Perubahan state harus membuat banyak halaman ter-update secara otomatis.

---

## Contoh Kegunaan dalam Fitur Auth

**AuthProvider.jsx** biasanya:
- Mengecek apakah user memiliki token login.
- Menyediakan data user ke halaman private.
- Mengarahkan (redirect) user ke login jika belum terautentikasi.

---

## Hal yang Tidak Boleh Dimasukkan ke Folder Ini

| Tidak Disimpan Di Sini | Alasannya |
|------------------------|----------|
| Request API (fetching data) | Harus disimpan di `modules/auth/services.js` atau fitur lainnya. |
| Logika spesifik fitur | Harus tetap mengikuti struktur `modules/<fitur>/...`. |
| UI Components | Harus berada di folder `components/`. |

---

## Contoh Struktur Penggunaan Context (Konseptual)

```jsx
// app/(private)/layout.jsx
import AuthProvider from "@/context/AuthProvider";

export default function PrivateLayout({ children }) {
  return (
    <AuthProvider>
      {children}
    </AuthProvider>
  );
}