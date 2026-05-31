"use client";
import React, { useContext, useEffect, useState, useRef, useCallback, Suspense } from "react";
import { usePathname } from "next/navigation";
import {
  BadgeCheck,
  LayoutDashboard,
  Menu,
  MessageSquareWarning,
  Users,
  X,
} from "lucide-react";
import Logo from "./Logo.jsx";
import { AuthContext } from "../../context/AuthProvider.jsx";
import SearchBar from "./SearchBar.jsx";
import { getProfilePictureUrl } from "@/utils/imageHelper";
import { sellerService } from "@/services/seller/sellerService";

const Navbar = () => {
  const { user, loading } = useContext(AuthContext);
  const pathname = usePathname() || "";
  const showSearch =
    pathname.startsWith("/dashboard") ||
    pathname.startsWith("/product") ||
    pathname.startsWith("/products");

  const [isVerified, setIsVerified] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const drawerRef = useRef(null);
  const hamburgerRef = useRef(null);
  const adminMobileNavItems = [
    {
      href: "/backoffice",
      label: "Management User",
      Icon: LayoutDashboard,
    },
    {
      href: "/backoffice/super-admin",
      label: "Super Admin",
      Icon: Users,
    },
    {
      href: "/backoffice/reports",
      label: "Laporan",
      Icon: MessageSquareWarning,
    },
  ];

  useEffect(() => {
    if (user?.role !== "seller") {
      setIsVerified(false);
      return;
    }

    sellerService
      .getVerificationStatus()
      .then((data) => {
        setIsVerified(data?.is_verified ?? false);
      })
      .catch(() => {
        setIsVerified(false);
      });
  }, [user?.id, user?.role]);

  // Close drawer when clicking outside
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (
        isMenuOpen &&
        drawerRef.current &&
        !drawerRef.current.contains(e.target) &&
        hamburgerRef.current &&
        !hamburgerRef.current.contains(e.target)
      ) {
        setIsMenuOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("touchstart", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("touchstart", handleClickOutside);
    };
  }, [isMenuOpen]);

  // Close drawer on route change
  useEffect(() => {
    setIsMenuOpen(false);
  }, [pathname]);

  const toggleMenu = useCallback(() => {
    setIsMenuOpen((prev) => !prev);
  }, []);

  return (
    <header className="bg-white relative">
      {/* === Row 1: Main bar === */}
      <div className="w-full px-2 sm:px-4 py-3 flex items-center gap-4 transition-shadow duration-200">
        <div className="flex items-center gap-4 sm:gap-6 min-w-0">
          <Logo
            className="-mt-1.5"
            href={user?.role === "admin" ? "/backoffice" : "/dashboard"}
          />
        </div>

        {/* Navigation Items — Desktop only */}
        {user?.role !== "admin" && (
          <div className="hidden md:flex items-center gap-8 mx-4">
            <a
              href="/dashboard"
              className="relative group text-gray-600 font-medium hover:text-[#E83030] transition-colors duration-300"
            >
              Beranda
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-[#E83030] transition-all duration-300 group-hover:w-full"></span>
            </a>
            {user?.role !== "seller" && (
              <a
                href="/products"
                className="relative group text-gray-600 font-medium hover:text-[#E83030] transition-colors duration-300"
              >
                Produk
                <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-[#E83030] transition-all duration-300 group-hover:w-full"></span>
              </a>
            )}
            <a
              href="/chat"
              className="relative group text-gray-600 font-medium hover:text-[#E83030] transition-colors duration-300"
            >
              Pesan
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-[#E83030] transition-all duration-300 group-hover:w-full"></span>
            </a>
          </div>
        )}

        {/* Search bar — Desktop (inline) */}
        {showSearch && (
          <div className="hidden md:block flex-1">
            <Suspense
              fallback={
                <div className="w-full px-4 py-2.5 bg-gray-100 rounded-2xl animate-pulse"></div>
              }
            >
              <SearchBar inline />
            </Suspense>
          </div>
        )}

        {/* Right side actions — Desktop only */}
        <div className="hidden md:flex items-center gap-3 sm:gap-4 ml-auto">
          {loading ? (
            <div className="flex items-center gap-3 animate-pulse">
              <div className="w-8 h-8 rounded-full bg-gray-200"></div>
              <div className="hidden sm:block w-24 h-5 rounded bg-gray-200"></div>
              <div className="w-16 h-9 rounded-2xl bg-gray-200"></div>
            </div>
          ) : user ? (
            <>
              <a
                href={`/profile/edit?id=${
                  user?.id || user?._id || user?.userId || ""
                }`}
                className="flex items-center gap-2"
              >
                <img
                  src={getProfilePictureUrl(user?.profile_picture)}
                  alt="avatar"
                  className="w-8 h-8 rounded-full transition-transform duration-200 hover:scale-105"
                />
                <span className="font-semibold text-gray-800 flex items-center gap-1">
                  Hi, {user.name || user.username || "User"}
                  {isVerified && (
                    <BadgeCheck
                      className="w-4 h-4 text-blue-500 flex-shrink-0"
                      aria-label="Seller Terverifikasi"
                    />
                  )}
                </span>
              </a>
              {user?.role === "seller" && (
                <a
                  href="/seller/products/new"
                  className="px-4 py-2.5 rounded-2xl bg-[#E83030] text-white font-semibold text-center shadow transition-all duration-200 hover:shadow-lg active:scale-95"
                >
                  Upload Produk
                </a>
              )}
            </>
          ) : (
            <>
              <a
                href="/auth/login"
                className="px-4 py-2.5 rounded-2xl bg-[#E83030] text-white font-semibold text-center shadow transition-all duration-200 hover:shadow-lg active:scale-95"
              >
                Masuk
              </a>
              <a
                href="/auth/register"
                className="px-4 py-2.5 rounded-2xl bg-[#E83030] text-white font-semibold text-center shadow transition-all duration-200 hover:shadow-lg active:scale-95"
              >
                Daftar
              </a>
            </>
          )}
        </div>

        {/* Hamburger button — Mobile only */}
        <button
          ref={hamburgerRef}
          onClick={toggleMenu}
          className="md:hidden ml-auto p-2 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors duration-200 focus:outline-none"
          aria-label={isMenuOpen ? "Tutup menu" : "Buka menu"}
          aria-expanded={isMenuOpen}
        >
          {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
      </div>

      {/* === Row 2: Search bar — Mobile only === */}
      {showSearch && (
        <div className="md:hidden px-3 pb-3">
          <Suspense
            fallback={
              <div className="w-full px-4 py-2.5 bg-gray-100 rounded-2xl animate-pulse"></div>
            }
          >
            <SearchBar inline />
          </Suspense>
        </div>
      )}

      {/* === Mobile Drawer (slide down) === */}
      <div
        ref={drawerRef}
        className={`md:hidden absolute left-0 right-0 bg-white shadow-lg border-t border-gray-100 z-50 overflow-hidden transition-all duration-300 ease-in-out ${
          isMenuOpen
            ? "max-h-[500px] opacity-100"
            : "max-h-0 opacity-0 pointer-events-none"
        }`}
      >
        <nav className="flex flex-col px-4 py-3 gap-1">
          {/* Nav links */}
          {user?.role === "admin" ? (
            <div className="flex flex-col gap-1">
              {adminMobileNavItems.map(({ href, label, Icon }) => {
                const active = pathname === href;

                return (
                  <a
                    key={href}
                    href={href}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-lg font-medium transition-colors duration-200 ${
                      active
                        ? "bg-red-50 text-[#E83030]"
                        : "text-gray-700 hover:bg-red-50 hover:text-[#E83030]"
                    }`}
                  >
                    <Icon className="h-5 w-5" />
                    {label}
                  </a>
                );
              })}
            </div>
          ) : (
            <>
              <a
                href="/dashboard"
                className="px-3 py-2.5 rounded-lg text-gray-700 font-medium hover:bg-red-50 hover:text-[#E83030] transition-colors duration-200"
              >
                Beranda
              </a>
              {user?.role !== "seller" && (
                <a
                  href="/products"
                  className="px-3 py-2.5 rounded-lg text-gray-700 font-medium hover:bg-red-50 hover:text-[#E83030] transition-colors duration-200"
                >
                  Produk
                </a>
              )}
              <a
                href="/chat"
                className="px-3 py-2.5 rounded-lg text-gray-700 font-medium hover:bg-red-50 hover:text-[#E83030] transition-colors duration-200"
              >
                Pesan
              </a>
            </>
          )}

          {/* Divider */}
          <div className="my-1 border-t border-gray-100"></div>

          {/* User / Auth actions */}
          {loading ? (
            <div className="flex items-center gap-3 px-3 py-2 animate-pulse">
              <div className="w-8 h-8 rounded-full bg-gray-200"></div>
              <div className="w-24 h-5 rounded bg-gray-200"></div>
            </div>
          ) : user ? (
            <>
              <a
                href={`/profile/edit?id=${
                  user?.id || user?._id || user?.userId || ""
                }`}
                className="flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-gray-50 transition-colors duration-200"
              >
                <img
                  src={getProfilePictureUrl(user?.profile_picture)}
                  alt="avatar"
                  className="w-8 h-8 rounded-full"
                />
                <span className="font-semibold text-gray-800 flex items-center gap-1">
                  Hi, {user.name || user.username || "User"}
                  {isVerified && (
                    <BadgeCheck
                      className="w-4 h-4 text-blue-500 flex-shrink-0"
                      aria-label="Seller Terverifikasi"
                    />
                  )}
                </span>
              </a>
              {user?.role === "seller" && (
                <a
                  href="/seller/products/new"
                  className="mx-3 mt-1 px-4 py-2.5 rounded-2xl bg-[#E83030] text-white font-semibold text-center shadow transition-all duration-200 hover:shadow-lg active:scale-95"
                >
                  Upload Produk
                </a>
              )}
            </>
          ) : (
            <div className="flex flex-col gap-2 px-3 py-1">
              <a
                href="/auth/login"
                className="px-4 py-2.5 rounded-2xl bg-[#E83030] text-white font-semibold text-center shadow transition-all duration-200 hover:shadow-lg active:scale-95"
              >
                Masuk
              </a>
              <a
                href="/auth/register"
                className="px-4 py-2.5 rounded-2xl border-2 border-[#E83030] text-[#E83030] font-semibold text-center transition-all duration-200 hover:bg-red-50 active:scale-95"
              >
                Daftar
              </a>
            </div>
          )}
        </nav>
      </div>

      {/* Backdrop overlay — Mobile only */}
      {isMenuOpen && (
        <div
          className="md:hidden fixed inset-0 bg-black/20 z-40"
          style={{ top: drawerRef.current?.getBoundingClientRect?.()?.bottom || 0 }}
          onClick={() => setIsMenuOpen(false)}
          aria-hidden="true"
        />
      )}
    </header>
  );
};

export default Navbar;

