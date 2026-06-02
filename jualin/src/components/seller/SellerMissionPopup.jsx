"use client";

import { useEffect, useState } from "react";
import { sellerService } from "@/services/seller/sellerService";

const TARGET = 3;
const VERIFIED_SHOWN_KEY = "verified_popup_shown";

/**
 * SellerMissionPopup
 *
 * Fetches /api/v1/seller/verification-status on mount and shows:
 *  - "Mission" popup  → setiap kali dashboard dibuka selama is_verified masih false
 *  - "Congrats" popup → hanya sekali saat seller baru saja verified (disimpan di localStorage)
 */
export default function SellerMissionPopup() {
  const [status, setStatus] = useState(null); // { total_sales, is_verified, target }
  const [mode, setMode] = useState(null);     // "mission" | "congrats" | null

  useEffect(() => {
    let mounted = true;

    sellerService
      .getVerificationStatus()
      .then((data) => {
        if (!mounted) return;
        setStatus(data);

        if (data?.is_verified) {
          // Tampil popup selamat hanya sekali seumur hidup
          const alreadyShown = localStorage.getItem(VERIFIED_SHOWN_KEY) === "true";
          if (!alreadyShown) {
            setMode("congrats");
          }
        } else {
          // Selalu tampil popup misi selama belum verified
          setMode("mission");
        }
      })
      .catch(() => {
        // silently ignore — bukan seller atau token expired
      });

    return () => {
      mounted = false;
    };
  }, []);

  const handleDismissMission = () => {
    setMode(null);
  };

  const handleDismissCongrats = () => {
    localStorage.setItem(VERIFIED_SHOWN_KEY, "true");
    setMode(null);
  };

  if (!mode || !status) return null;

  const totalSales = status?.total_sales ?? 0;
  const target = status?.target ?? TARGET;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
    >
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-[340px] sm:max-w-md overflow-hidden animate-in fade-in zoom-in duration-300">

        {/* ── MISSION POPUP ─────────────────────────────── */}
        {mode === "mission" && (
          <div className="p-5 sm:p-8">
            {/* Header */}
            <div className="text-center mb-5 sm:mb-6">
              <h2 className="text-xl sm:text-2xl font-bold text-gray-900 mb-2">
                🎯 Misi Seller — Raih Badge Terverifikasi!
              </h2>
              <p className="text-xs sm:text-sm text-gray-500 leading-relaxed">
                Selesaikan {target} penjualan untuk mendapat badge verified dan
                tingkatkan kepercayaan pembelimu.
              </p>
            </div>

            {/* Progress nodes */}
            <div className="flex items-center justify-center gap-2 mb-4 flex-wrap">
              {Array.from({ length: target }, (_, i) => {
                const reached = i < totalSales;
                return (
                  <div
                    key={i}
                    title={`Penjualan ke-${i + 1}`}
                    className={[
                      "w-10 h-10 sm:w-12 sm:h-12 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all",
                      reached
                        ? "bg-red-500 border-red-500 text-white shadow-md"
                        : "bg-gray-100 border-gray-300 text-gray-400",
                    ].join(" ")}
                  >
                    {i + 1}
                  </div>
                );
              })}
            </div>

            {/* Progress bar */}
            <div className="w-full bg-gray-200 rounded-full h-2 mb-4">
              <div
                className="bg-red-500 h-2 rounded-full transition-all duration-700"
                style={{ width: `${Math.min((totalSales / target) * 100, 100)}%` }}
              />
            </div>

            {/* Count text */}
            <p className="text-center text-xs sm:text-sm text-gray-600 mb-6 sm:mb-8 font-medium">
              Kamu sudah menyelesaikan{" "}
              <span className="text-red-600 font-bold">{totalSales}</span>{" "}
              dari {target} penjualan
            </p>

            {/* CTA button */}
            <button
              id="mission-popup-dismiss-btn"
              onClick={handleDismissMission}
              className="w-full py-2.5 sm:py-3 px-6 rounded-xl bg-red-500 hover:bg-red-600 text-white font-semibold text-sm sm:text-base transition-colors shadow-md hover:shadow-lg"
            >
              Oke!
            </button>
          </div>
        )}

        {/* ── CONGRATS POPUP ────────────────────────────── */}
        {mode === "congrats" && (
          <div className="p-5 sm:p-8 text-center">
            {/* Celebration icon */}
            <div className="w-16 h-16 sm:w-20 sm:h-20 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-5 sm:mb-6 border-4 border-red-100">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                className="w-8 h-8 sm:w-10 sm:h-10 text-red-500"
                stroke="currentColor"
                strokeWidth={2.5}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>

            <h2 className="text-xl sm:text-2xl font-bold text-gray-900 mb-2">
              🎉 Selamat! Kamu Sekarang Seller Terverifikasi!
            </h2>
            <p className="text-xs sm:text-sm text-gray-500 leading-relaxed mb-6 sm:mb-8">
              Badge verified kamu sudah aktif. Pembeli bisa melihat tanda ini
              di setiap produkmu.
            </p>

            <button
              id="congrats-popup-dismiss-btn"
              onClick={handleDismissCongrats}
              className="w-full py-2.5 sm:py-3 px-6 rounded-xl bg-red-500 hover:bg-red-600 text-white font-semibold text-sm sm:text-base transition-colors shadow-md hover:shadow-lg"
            >
              Lihat Dashboard
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
