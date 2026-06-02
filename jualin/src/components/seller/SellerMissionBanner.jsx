"use client";

import { useEffect, useState } from "react";
import { sellerService } from "@/services/seller/sellerService";

const TARGET = 3;

/**
 * SellerMissionBanner
 *
 * Permanent banner shown at the top of the seller dashboard
 * while `is_verified` is still false.
 * Disappears entirely once the seller is verified.
 */
export default function SellerMissionBanner() {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    sellerService
      .getVerificationStatus()
      .then((data) => {
        if (mounted) setStatus(data);
      })
      .catch(() => {
        // silently ignore — bukan seller atau token expired
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });

    return () => {
      mounted = false;
    };
  }, []);

  // Don't render anything while loading, on error, or when verified
  if (loading || !status || status.is_verified) return null;

  const totalSales = status.total_sales ?? 0;
  const target = status.target ?? TARGET;
  const progressPct = Math.min((totalSales / target) * 100, 100);

  return (
    <div
      id="seller-mission-banner"
      className="relative overflow-hidden rounded-xl sm:rounded-2xl mx-auto w-full border border-red-100"
      style={{
        background:
          "linear-gradient(135deg, #FFF5F5 0%, #FEE2E2 40%, #FECACA 100%)",
      }}
    >
      {/* Decorative background circles */}
      <div
        className="absolute -top-10 -right-10 w-40 h-40 rounded-full opacity-10"
        style={{ background: "#E83030" }}
      />
      <div
        className="absolute -bottom-8 -left-8 w-32 h-32 rounded-full opacity-[0.07]"
        style={{ background: "#E83030" }}
      />

      <div className="relative z-10 px-4 py-4 sm:px-8 sm:py-6">
        {/* Title row */}
        <h2 className="text-base sm:text-xl font-bold text-gray-900 mb-3 sm:mb-4 tracking-tight">
          🎯 Misi Seller — Raih Badge Terverifikasi!
        </h2>

        {/* Progress nodes */}
        <div className="flex items-center gap-0 mb-3 sm:mb-4">
          {Array.from({ length: target }, (_, i) => {
            const reached = i < totalSales;
            const isLast = i === target - 1;

            return (
              <div key={i} className="flex items-center">
                {/* Node */}
                <div
                  className={[
                    "w-9 h-9 sm:w-11 sm:h-11 rounded-full flex items-center justify-center",
                    "text-sm font-bold border-2 transition-all duration-500",
                    "shadow-sm",
                    reached
                      ? "bg-[#E83030] border-[#E83030] text-white shadow-red-200"
                      : "bg-white border-gray-300 text-gray-400",
                  ].join(" ")}
                  title={`Penjualan ke-${i + 1}`}
                >
                  {reached ? (
                    <svg
                      className="w-5 h-5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth={3}
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                  ) : (
                    i + 1
                  )}
                </div>

                {/* Connector line between nodes */}
                {!isLast && (
                  <div className="w-6 sm:w-12 h-1 mx-0.5 rounded-full overflow-hidden bg-gray-200">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        width: i < totalSales - 1 ? "100%" : i < totalSales ? "50%" : "0%",
                        background: "#E83030",
                      }}
                    />
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Bottom row: text + progress bar */}
        <div className="flex flex-col sm:flex-row sm:items-center gap-3">
          {/* Sales count text */}
          <p className="text-xs sm:text-sm text-gray-600 font-medium whitespace-normal sm:whitespace-nowrap">
            Kamu sudah menyelesaikan{" "}
            <span className="text-[#E83030] font-bold">{totalSales}</span> dari{" "}
            <span className="font-bold">{target}</span> penjualan
          </p>

          {/* Progress bar */}
          <div className="flex-1 min-w-0">
            <div className="w-full bg-white/70 rounded-full h-2 sm:h-2.5 shadow-inner">
              <div
                className="h-2 sm:h-2.5 rounded-full transition-all duration-700 ease-out"
                style={{
                  width: `${progressPct}%`,
                  background: "linear-gradient(90deg, #E83030, #EF4444)",
                }}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
