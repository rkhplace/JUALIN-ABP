"use client";
import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function BackofficeNewProductPage() {
  const router = useRouter();

  useEffect(() => {
    // Admin tidak diperbolehkan menambah produk — redirect ke daftar produk
    router.replace("/backoffice/products");
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen bg-[#F5F6FA]">
      <div className="text-center p-8 bg-white rounded-2xl shadow-md border border-gray-100 max-w-sm">
        <div className="w-14 h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg
            className="w-7 h-7 text-[#E83030]"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
            />
          </svg>
        </div>
        <h2 className="text-lg font-bold text-gray-800 mb-1">Akses Ditolak</h2>
        <p className="text-sm text-gray-500">
          Admin tidak memiliki izin untuk menambah produk baru.
        </p>
        <p className="text-xs text-gray-400 mt-2">Mengalihkan halaman...</p>
      </div>
    </div>
  );
}

