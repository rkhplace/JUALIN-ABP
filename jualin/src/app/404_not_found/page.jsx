"use client";

import Link from "next/link";
import TextButton from "@/components/ui/TextButton.jsx";

export default function NotFound() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-[#E0E4EC]">
      <section className="w-full max-w-5xl bg-white rounded-[32px] px-10 py-10 flex items-center justify-between shadow-2xl">
        {/* Kiri: ilustrasi 404 */}
        <div className="relative w-1/2 min-w-[260px]">
          {/* Angka 404 */}
          <div className="text-[120px] font-black text-[#1F1F1F] tracking-[4px] leading-none">
            404
          </div>
          {/* Papan UNDER CONSTRUCTION */}
          <div className="absolute top-10 left-16 px-3 py-2 bg-[#FFCC00] border-[4px] border-[#1F1F1F] rounded-md rotate-[-5deg] text-center uppercase font-bold text-[12px]">
            <div className="text-[10px]">Under</div>
            <div className="text-[12px]">Construction</div>
          </div>
          {/* Rambu larangan */}
          <div className="absolute bottom-2 right-10 w-[60px] h-[60px] rounded-2xl bg-[#E03131] flex items-center justify-center text-white text-[32px] font-bold">
            ⛔
          </div>
          {/* Cone lalu lintas */}
          <div className="absolute bottom-0 left-10 w-10 h-10 flex items-end justify-center text-[32px]">
            🚧
          </div>
        </div>
        {/* Kanan: teks + tombol */}
        <div className="w-[45%] text-left">
          <h1 className="text-[28px] font-bold mb-3 text-white [text-shadow:_0_2px_4px_rgba(0,0,0,0.5)]">
            Halaman Tidak Ditemukan
          </h1>
          <p className="text-sm text-[#4B4B4B] mb-6 max-w-xs">
            Maaf, halaman yang Anda cari tidak tersedia atau masih dalam tahap
            pengembangan.
          </p>
          <Link href="/dashboard">
            <TextButton
              href="/dashboard"
              className="px-4 py-2 rounded-2xl bg-[#E83030] text-white font-semibold shadow transition-transform duration-200 hover:-translate-y-0.5 active:scale-95"
            >
              Kembali ke beranda
            </TextButton>
          </Link>
        </div>
      </section>
    </main>
  );
}

