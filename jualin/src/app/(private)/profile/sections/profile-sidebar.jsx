"use client";

import { ChevronRight, ChevronLeft, ShoppingBag, Store } from "lucide-react";

/**
 * ProfileSidebarSection
 * Navigation sidebar for profile pages with tab switching and logout
 * Used in profile/edit/page.jsx
 */
export function ProfileSidebarSection({
  activeTab,
  onTabChange,
  onLogout,
  onBecomeSeller,
  onSwitchToBuyer,
  onSwitchToSeller,
  isBecomingSeller = false,
  role,
  activeRole,
  user,
  isSidebarOpen = false,
  onToggle,
}) {
  return (
    <div
      className={`
        md:relative md:translate-x-0
        fixed left-0 top-0 h-full z-40
        transition-transform duration-300 ease-in-out
        ${isSidebarOpen ? "translate-x-0" : "-translate-x-full"}
      `}
    >
      {/* Handle button — Mobile only */}
      <button
        onClick={onToggle}
        className="md:hidden absolute right-0 translate-x-full top-1/2 -translate-y-1/2 bg-[#E83030] text-white rounded-r-xl px-1.5 py-2.5 shadow-lg z-50 focus:outline-none"
        aria-label={isSidebarOpen ? "Tutup sidebar" : "Buka sidebar"}
      >
        {isSidebarOpen ? (
          <ChevronLeft className="w-4 h-4" />
        ) : (
          <ChevronRight className="w-4 h-4" />
        )}
      </button>

      {/* Sidebar content */}
      <div className="w-56 md:w-64 bg-[#E83030] min-h-full flex flex-col rounded-r-3xl">
        <div className="p-4 md:p-6 flex-1 overflow-y-auto">
          <div className="space-y-6 md:space-y-8">
            {/* WALLET Section */}
            {role !== "admin" && (
              <div className="bg-white/10 rounded-2xl p-3 md:p-4 shadow-inner border border-white/20">
                <h3 className="text-xs font-bold text-white/90 uppercase tracking-wider mb-2">
                  SALDO DOMPET
                </h3>
                <div className="flex items-end gap-2 text-white">
                  <span className="text-sm font-medium opacity-80 mb-1">Rp</span>
                  <span className="text-xl md:text-2xl font-black tracking-tight">
                    {Number(user?.wallet_balance || 0).toLocaleString("id-ID")}
                  </span>
                </div>
              </div>
            )}

            {/* PROFILE Section */}
            <div>
              <h3 className="text-xs font-bold text-white/90 uppercase tracking-wider mb-4 px-1">
                PROFIL
              </h3>
              <nav className="space-y-3">
                <button
                  onClick={() => onTabChange("edit")}
                  className={`w-full flex items-center px-4 py-2.5 md:py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] ${activeTab === "edit"
                    ? "bg-white text-[#E83030] font-bold ring-2 ring-white/20"
                    : "bg-white text-gray-700 hover:bg-gray-50"
                    }`}
                >
                  <svg
                    className={`mr-3 h-5 w-5 ${activeTab === "edit" ? "text-[#E83030]" : "text-gray-500"
                      }`}
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"
                      clipRule="evenodd"
                    />
                  </svg>
                  Ubah Profil
                </button>
                {role === "customer" && (
                  <>
                    <button
                      onClick={onBecomeSeller}
                      disabled={isBecomingSeller}
                      className="w-full flex items-center px-4 py-2.5 md:py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] bg-white text-gray-700 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-70"
                    >
                      <svg
                        className="mr-3 h-5 w-5 text-gray-500"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M3 9l1.5-4.5h15L21 9M5 9v10h14V9M9 19v-6h6v6"
                        />
                      </svg>
                      {isBecomingSeller ? "Mendaftarkan..." : "Daftar Penjual"}
                    </button>
                    <button
                      onClick={() => onTabChange("purchases")}
                      className={`w-full flex items-center px-4 py-2.5 md:py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] ${activeTab === "purchases"
                        ? "bg-white text-[#E83030] font-bold ring-2 ring-white/20"
                        : "bg-white text-gray-700 hover:bg-gray-50"
                        }`}
                    >
                      <svg
                        className={`mr-3 h-5 w-5 ${activeTab === "purchases"
                          ? "text-[#E83030]"
                          : "text-gray-500"
                          }`}
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                        />
                      </svg>
                      Riwayat Pembelian
                    </button>
                  </>
                )}
                {role === "seller" && (
                  activeRole === "seller" ? (
                    <button
                      onClick={onSwitchToBuyer}
                      className="w-full flex items-center px-4 py-2.5 md:py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] bg-white text-gray-700 hover:bg-gray-50"
                    >
                      <ShoppingBag className="mr-3 h-5 w-5 text-gray-500" />
                      Mode Pembeli
                    </button>
                  ) : (
                    <button
                      onClick={onSwitchToSeller}
                      className="w-full flex items-center px-4 py-2.5 md:py-3 text-sm font-medium rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:scale-[1.02] bg-white text-gray-700 hover:bg-gray-50"
                    >
                      <Store className="mr-3 h-5 w-5 text-gray-500" />
                      Mode Penjual
                    </button>
                  )
                )}
              </nav>
            </div>
          </div>
        </div>

        {/* Logout Button */}
        <div className="px-4 py-4 md:px-6 mt-4">
          <button
            onClick={onLogout}
            className="w-full flex items-center justify-center px-4 py-2.5 md:py-3 bg-white hover:bg-gray-50 text-[#E83030] rounded-xl transition-all duration-200 shadow-sm hover:shadow-md hover:-translate-y-0.5 text-sm font-bold"
          >
            <svg
              className="mr-2 h-5 w-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
              />
            </svg>
            Keluar
          </button>
        </div>
      </div>
    </div>
  );
}

