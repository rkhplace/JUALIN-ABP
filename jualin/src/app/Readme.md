# Folder: app/

Berisi routing dan struktur halaman menggunakan Next.js App Router.

## Subfolder:
- (public) → Halaman yang boleh dibuka tanpa login
- (private) → Halaman yang butuh login
- layout.jsx → Layout global (header/footer/provider)

## Contoh:
- app/(public)/auth/login/page.jsx → Halaman Login
- app/(private)/dashboard/page.jsx → Halaman setelah login (protected route)
