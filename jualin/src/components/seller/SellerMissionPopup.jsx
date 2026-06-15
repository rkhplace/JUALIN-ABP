"use client";

import { useEffect, useState } from "react";
import { CircleCheck, ShieldCheck } from "lucide-react";
import { sellerService } from "@/services/seller/sellerService";

const TARGET = 3;
const VERIFIED_SHOWN_KEY = "verified_popup_shown";

/**
 * SellerMissionPopup
 *
 * Fetches /api/v1/seller/verification-status on mount and shows:
 *  - "Mission" popup  → setiap kali dashboard dibuka selama is_verified masih false
 *  - "Congrats" popup → sekali setiap sesi login seller terverifikasi
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
          // Tampil sekali setelah login, lalu disembunyikan sampai login berikutnya.
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
  const profileComplete = status?.profile_complete === true;
  const missingFields = status?.missing_profile_fields ?? [];

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
    >
      <div
        className={`w-full overflow-hidden bg-white shadow-2xl animate-in fade-in zoom-in duration-300 ${
          mode === "congrats"
            ? "max-w-[360px] rounded-[28px] sm:max-w-lg"
            : "max-w-[340px] rounded-2xl sm:max-w-md"
        }`}
      >

        {/* ── MISSION POPUP ─────────────────────────────── */}
        {mode === "mission" && (
          <div className="p-5 sm:p-8">
            {/* Header */}
            <div className="text-center mb-5 sm:mb-6">
              <h2 className="text-xl sm:text-2xl font-bold text-gray-900 mb-2">
                🎯 Misi Seller — Raih Badge Terverifikasi!
              </h2>
              <p className="text-xs sm:text-sm text-gray-500 leading-relaxed">
                Selesaikan {target} penjualan, lengkapi semua data diri, dan
                pasang foto profil untuk mendapat badge verified.
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

            <div className="mb-6 rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-left text-xs sm:text-sm text-gray-700">
              <p className="font-semibold text-gray-900">
                Kelengkapan profil:{" "}
                <span className={profileComplete ? "text-green-700" : "text-red-600"}>
                  {profileComplete ? "Lengkap" : "Belum lengkap"}
                </span>
              </p>
              {!profileComplete && missingFields.length > 0 && (
                <p className="mt-1 leading-relaxed">
                  Masih perlu diisi: {missingFields.map((item) => item.label).join(", ")}.
                </p>
              )}
            </div>

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
          <VerifiedBenefitsPopup onDismiss={handleDismissCongrats} />
        )}

      </div>
    </div>
  );
}

function VerifiedBenefitsPopup({ onDismiss }) {
  const benefits = [
    "Badge terverifikasi tampil di profil dan produk.",
    "Pembeli lebih mudah percaya saat melihat toko.",
    "Produk terlihat lebih kredibel saat dibandingkan.",
  ];

  return (
    <div className="px-6 pb-7 pt-8 text-center sm:px-10 sm:pb-10 sm:pt-10">
      <div className="mx-auto mb-6 flex h-24 w-24 items-center justify-center rounded-full bg-blue-50">
        <ShieldCheck
          className="h-14 w-14 fill-blue-500 text-white"
          strokeWidth={2.25}
        />
      </div>

      <h2 className="mx-auto max-w-sm text-2xl font-bold leading-tight text-gray-900 sm:text-[28px]">
        Keuntungan Penjual
        <br />
        Terverifikasi
      </h2>

      <p className="mx-auto mt-5 max-w-md text-sm leading-6 text-gray-500 sm:text-base sm:leading-7">
        Ayo tingkatkan kepercayaan pembeli dengan menjadi penjual
        terverifikasi. Selesaikan target verifikasi agar badge biru tampil di
        tokomu.
      </p>

      <ul className="mt-6 space-y-4 text-left">
        {benefits.map((benefit) => (
          <li
            key={benefit}
            className="flex items-start gap-3 text-sm leading-6 text-gray-800 sm:text-base"
          >
            <CircleCheck className="mt-0.5 h-6 w-6 shrink-0 fill-blue-500 text-white" />
            <span>{benefit}</span>
          </li>
        ))}
      </ul>

      <button
        id="congrats-popup-dismiss-btn"
        type="button"
        onClick={onDismiss}
        className="mt-8 w-full rounded-2xl bg-[#EF2F35] px-6 py-3.5 text-base font-semibold text-white shadow-lg shadow-red-200 transition-colors hover:bg-[#D9252B] focus:outline-none focus:ring-4 focus:ring-red-100"
      >
        Mengerti
      </button>
    </div>
  );
}
