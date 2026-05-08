"use client";
import React, { useContext, Suspense } from "react";
import { usePathname } from "next/navigation";
import Logo from "./Logo.jsx";
import { AuthContext } from "../../context/AuthProvider.jsx";
import SearchBar from "./SearchBar.jsx";
import { getProfilePictureUrl } from "@/utils/imageHelper";

const Navbar = () => {
  const { user, loading } = useContext(AuthContext);
  const pathname = usePathname() || "";
  const showSearch =
    pathname.startsWith("/dashboard") ||
    pathname.startsWith("/product") ||
    pathname.startsWith("/products");

  return (
    <header className="bg-white">
      <div className="w-full px-2 sm:px-4 py-3 flex items-center gap-4 transition-shadow duration-200">
        <div className="flex items-center gap-4 sm:gap-6 min-w-0">
          <Logo
            className="-mt-1.5"
            href={user?.role === "admin" ? "/backoffice" : "/dashboard"}
          />
        </div>

        {/* Navigation Items */}
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

        {showSearch && (
          <div className="flex-1">
            <Suspense
              fallback={
                <div className="w-full px-4 py-2.5 bg-gray-100 rounded-2xl animate-pulse"></div>
              }
            >
              <SearchBar inline />
            </Suspense>
          </div>
        )}

        <div className="flex items-center gap-3 sm:gap-4 ml-auto">
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
                <span className="font-semibold text-gray-800">
                  Hi, {user.name || user.username || "User"}
                </span>
              </a>
              {user?.role === "seller" && (
                <a
                  href="/seller/products/new"
                  className="px-4 py-2 rounded-2xl bg-[#E83030] text-white font-semibold shadow transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 active:scale-95"
                >
                  Upload Produk
                </a>
              )}
            </>
          ) : (
            <>
              <a
                href="/auth/login"
                className="px-4 py-2 rounded-2xl bg-[#E83030] text-white font-semibold shadow transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 active:scale-95"
              >
                Masuk
              </a>
              <a
                href="/auth/register"
                className="px-4 py-2 rounded-2xl bg-[#E83030] text-white font-semibold shadow transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 active:scale-95"
              >
                Daftar
              </a>
            </>
          )}
        </div>
      </div>
    </header>
  );
};

export default Navbar;
