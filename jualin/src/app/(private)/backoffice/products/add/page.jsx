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
    <div className="flex min-h-[calc(100vh-160px)] items-center justify-center bg-[#F5F6FA] px-4 py-8">
      <div className="w-full max-w-xs sm:max-w-sm text-center p-5 sm:p-8 bg-white rounded-xl sm:rounded-2xl shadow-md border border-gray-100">
        <div className="w-12 h-12 sm:w-14 sm:h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg
            className="w-6 h-6 sm:w-7 sm:h-7 text-[#E83030]"
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
        <h2 className="text-base sm:text-lg font-bold text-gray-800 mb-1">Akses Ditolak</h2>
        <p className="text-sm text-gray-500">
          Admin tidak memiliki izin untuk menambah produk baru.
        </p>
        <p className="text-xs text-gray-400 mt-2">Mengalihkan halaman...</p>
      </div>
    </div>
  );
}

