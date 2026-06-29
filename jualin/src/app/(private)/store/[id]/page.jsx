"use client";

import React, { useContext, useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import {
  ArrowLeft,
  BadgeCheck,
  Boxes,
  Clock,
  Filter,
  MapPin,
  MessageCircle,
  PackageSearch,
  Search,
  ShieldCheck,
  Store,
  User,
} from "lucide-react";
import Spinner from "@/components/ui/Spinner";
import Toast from "@/components/ui/Toast";
import UserAvatar from "@/components/ui/UserAvatar";
import VerifiedBadge from "@/components/ui/VerifiedBadge";
import { ProductCardSkeleton } from "@/components/ui/skeleton";
import Pagination from "@/components/ui/Pagination";
import DashboardBackground from "@/components/ui/DashboardBackground.jsx";
import { AuthContext } from "@/context/AuthProvider";
import { ChatContext } from "@/context/ChatProvider";
import { sellerService } from "@/services/seller/sellerService";
import { userService } from "@/services/user/userService";
import { formatCurrency } from "@/utils/formatters/currency";
import { formatOfferedAgo } from "@/utils/formatters/date";
import { getProductImageUrl, getProfilePictureUrl } from "@/utils/imageHelper";

export default function StoreProfilePage() {
  const params = useParams();
  const router = useRouter();
  const sellerId = Number(params.id);
  const { user } = useContext(AuthContext);
  const { startChat } = useContext(ChatContext);
  const [seller, setSeller] = useState(null);
  const [products, setProducts] = useState([]);
  const [meta, setMeta] = useState({
    totalProducts: 0,
    totalPages: 1,
    currentPage: 1,
  });
  const [page, setPage] = useState(1);
  const [isLoading, setIsLoading] = useState(true);
  const [isStartingChat, setIsStartingChat] = useState(false);
  const [toast, setToast] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [activeCategory, setActiveCategory] = useState("all");
  const [isFilterOpen, setIsFilterOpen] = useState(false);

  useEffect(() => {
    let mounted = true;

    async function loadStoreProfile() {
      if (!sellerId) return;

      setIsLoading(true);
      try {
        const [sellerData, productData] = await Promise.all([
          userService.fetchById(sellerId),
          sellerService.fetchProducts(sellerId, 9, page),
        ]);

        if (!mounted) return;
        setSeller(sellerData);
        setProducts(productData.products || []);
        setMeta({
          totalProducts: productData.totalProducts || 0,
          totalPages: productData.totalPages || 1,
          currentPage: productData.currentPage || page,
        });
      } catch (error) {
        if (!mounted) return;
        setToast({
          message: error.message || "Gagal memuat profil toko",
          type: "error",
        });
      } finally {
        if (mounted) setIsLoading(false);
      }
    }

    loadStoreProfile();

    return () => {
      mounted = false;
    };
  }, [sellerId, page]);

  const locationLabel = useMemo(() => {
    return (
      seller?.city ||
      seller?.region ||
      seller?.address_city ||
      seller?.location ||
      "Lokasi belum ditentukan"
    );
  }, [seller]);

  const categories = useMemo(() => {
    return Array.from(
      new Set(
        products
          .map((product) => String(product.category || product.brand || "").trim())
          .filter(Boolean)
      )
    ).sort((a, b) => a.localeCompare(b));
  }, [products]);

  const filteredProducts = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();

    return products.filter((product) => {
      const category = String(product.category || product.brand || "").toLowerCase();
      const matchesCategory = activeCategory === "all" || category === activeCategory;
      if (!matchesCategory) return false;
      if (!query) return true;

      return (
        String(product.name || "").toLowerCase().includes(query) ||
        String(product.description || "").toLowerCase().includes(query) ||
        category.includes(query)
      );
    });
  }, [activeCategory, products, searchQuery]);

  const handleChatSeller = async () => {
    if (!user) {
      setToast({
        message: "Silakan login terlebih dahulu untuk chat penjual",
        type: "error",
      });
      return;
    }

    if (!seller?.id) {
      setToast({ message: "Data penjual belum tersedia", type: "error" });
      return;
    }

    if (String(user.id) === String(seller.id)) {
      setToast({
        message: "Ini adalah toko Anda sendiri.",
        type: "error",
      });
      return;
    }

    setIsStartingChat(true);
    try {
      await startChat(seller.id, {
        name: seller.username || seller.email || "Seller",
        avatar: getProfilePictureUrl(seller.profile_picture || seller.avatar),
        role: "seller",
      });
      router.push("/chat");
    } catch (error) {
      setToast({
        message: error.message || "Gagal membuka chat penjual",
        type: "error",
      });
    } finally {
      setIsStartingChat(false);
    }
  };

  if (isLoading) {
    return (
      <main className="jualin-dashboard-bg min-h-screen px-4 py-8">
        <DashboardBackground />
        <div className="jualin-content-layer mx-auto max-w-6xl space-y-6">
          <div className="h-52 animate-pulse rounded-[28px] bg-white" />
          <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
            {[...Array(9)].map((_, index) => (
              <ProductCardSkeleton key={index} />
            ))}
          </div>
        </div>
      </main>
    );
  }

  if (!seller) {
    return (
      <main className="jualin-dashboard-bg min-h-screen px-4 py-8">
        <DashboardBackground />
        <div className="jualin-content-layer mx-auto flex min-h-[55vh] max-w-xl flex-col items-center justify-center text-center">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-red-50 text-[#E83030]">
            <Store className="h-8 w-8" />
          </div>
          <h1 className="mt-5 text-2xl font-black text-gray-950">
            Toko tidak ditemukan
          </h1>
          <p className="mt-2 text-sm font-medium leading-6 text-gray-500">
            Profil penjual ini belum tersedia atau sudah tidak aktif.
          </p>
          <button
            type="button"
            onClick={() => router.back()}
            className="mt-6 rounded-full bg-[#E83030] px-5 py-2.5 text-sm font-bold text-white"
          >
            Kembali
          </button>
        </div>
      </main>
    );
  }

  return (
    <main className="jualin-dashboard-bg min-h-screen px-4 py-6 sm:py-8">
      <DashboardBackground />
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="jualin-content-layer mx-auto max-w-6xl space-y-6">
        <button
          type="button"
          onClick={() => router.back()}
          className="inline-flex items-center gap-2 rounded-full border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm transition hover:border-red-200 hover:text-[#E83030]"
        >
          <ArrowLeft className="h-4 w-4" />
          Kembali
        </button>

        <section className="overflow-hidden rounded-[34px] border border-white/75 bg-white/90 shadow-[0_28px_70px_rgba(15,23,42,0.10)] backdrop-blur">
          <div className="relative bg-gradient-to-br from-[#E83030] via-[#F43D46] to-[#FF6268] px-5 py-7 sm:px-8 sm:py-10">
            <div className="absolute right-10 top-[-52px] h-44 w-44 rounded-full border border-white/20" />
            <div className="absolute right-28 bottom-[-88px] h-44 w-44 rounded-full bg-white/10" />
            <div className="absolute -right-12 bottom-[-32px] h-32 w-32 rounded-full border border-white/15" />
            <div className="relative flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
              <div className="flex items-center gap-4">
                <div className="rounded-[28px] bg-white/15 p-2 ring-1 ring-white/25 backdrop-blur">
                  <UserAvatar
                    name={seller.username || seller.email || "Seller"}
                    src={seller.profile_picture || seller.avatar}
                    sizeClass="w-20 h-20"
                  />
                </div>
                <div className="min-w-0">
                  <div className="mb-2 inline-flex items-center gap-2 rounded-full bg-white/15 px-3 py-1 text-xs font-bold text-white ring-1 ring-white/15">
                    <Store className="h-3.5 w-3.5" />
                    Profil Toko
                  </div>
                  <h1 className="flex items-center gap-2 text-2xl font-black text-white sm:text-4xl">
                    <span className="truncate">
                      {seller.username || "Seller Jualin"}
                    </span>
                    {seller.is_verified && (
                      <BadgeCheck className="h-6 w-6 shrink-0 fill-white text-[#E83030]" />
                    )}
                  </h1>
                  <p className="mt-2 flex items-center gap-2 text-sm font-medium text-white/80">
                    <MapPin className="h-4 w-4" />
                    {locationLabel}
                  </p>
                </div>
              </div>

              <button
                type="button"
                onClick={handleChatSeller}
                disabled={isStartingChat || String(user?.id) === String(seller.id)}
                className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white/95 px-5 py-3 text-sm font-black text-[#E83030] shadow-[0_16px_34px_rgba(127,29,29,0.20)] ring-1 ring-white/70 transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
              >
                {isStartingChat ? (
                  <Spinner size="sm" color="red" />
                ) : (
                  <MessageCircle className="h-4 w-4" />
                )}
                {String(user?.id) === String(seller.id)
                  ? "Toko Anda"
                  : isStartingChat
                    ? "Membuka chat..."
                    : "Chat Penjual"}
              </button>
            </div>
          </div>

          <div className="px-5 py-5 sm:px-8">
            <div className="grid gap-3 rounded-[26px] border border-white/80 bg-white/70 p-3 shadow-inner shadow-white/60 backdrop-blur sm:grid-cols-3">
            <SellerMetric
              icon={Boxes}
              label="Produk Aktif"
              value={`${filteredProducts.length} produk`}
            />
            <SellerMetric
              icon={ShieldCheck}
              label="Status"
              value={seller.is_verified ? "Terverifikasi" : "Belum terverifikasi"}
              badge={seller.is_verified ? <VerifiedBadge size="sm" /> : null}
            />
            <SellerMetric
              icon={User}
              label="Penjual"
              value={seller.email || "Informasi email tidak ditampilkan"}
            />
            </div>
          </div>
        </section>

        <section className="rounded-[30px] border border-gray-100 bg-white p-5 shadow-sm sm:p-6">
          <div className="mb-5">
            <div className="relative flex items-center gap-3">
              <label className="relative flex-1">
                <Search className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#E83030]" />
                <input
                  type="search"
                  value={searchQuery}
                  onChange={(event) => setSearchQuery(event.target.value)}
                  placeholder="Cari produk di toko ini..."
                  className="h-12 w-full rounded-2xl border border-gray-100 bg-gray-50 pl-11 pr-4 text-sm font-semibold text-gray-800 outline-none transition placeholder:text-gray-400 focus:border-red-200 focus:bg-white focus:ring-4 focus:ring-red-50"
                />
              </label>
              <div className="relative shrink-0">
                <button
                  type="button"
                  onClick={() => setIsFilterOpen((current) => !current)}
                  className="relative flex h-12 w-12 items-center justify-center rounded-2xl bg-[#E83030] text-white shadow-[0_12px_22px_rgba(232,48,48,0.22)] transition hover:bg-red-600"
                  aria-label="Filter kategori"
                >
                  <Filter className="h-5 w-5" />
                  {activeCategory !== "all" && (
                    <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-white" />
                  )}
                </button>
                {isFilterOpen && (
                  <div className="absolute right-0 top-14 z-20 w-56 overflow-hidden rounded-2xl border border-gray-100 bg-white p-2 shadow-[0_18px_45px_rgba(15,23,42,0.15)]">
                    <StoreFilterOption
                      active={activeCategory === "all"}
                      label="Semua Produk"
                      onClick={() => {
                        setActiveCategory("all");
                        setIsFilterOpen(false);
                      }}
                    />
                    {categories.map((category) => (
                      <StoreFilterOption
                        key={category}
                        active={activeCategory === category.toLowerCase()}
                        label={category}
                        onClick={() => {
                          setActiveCategory(category.toLowerCase());
                          setIsFilterOpen(false);
                        }}
                      />
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>

          {products.length === 0 ? (
            <div className="flex flex-col items-center justify-center rounded-3xl border-2 border-dashed border-gray-200 px-6 py-14 text-center">
              <PackageSearch className="h-12 w-12 text-gray-300" />
              <h3 className="mt-4 text-lg font-black text-gray-900">
                Belum ada produk
              </h3>
              <p className="mt-1 max-w-md text-sm font-medium leading-6 text-gray-500">
                Seller ini belum memiliki produk aktif yang bisa ditampilkan.
              </p>
            </div>
          ) : filteredProducts.length === 0 ? (
            <div className="flex flex-col items-center justify-center rounded-3xl border-2 border-dashed border-red-100 bg-red-50/30 px-6 py-14 text-center">
              <PackageSearch className="h-12 w-12 text-[#E83030]" />
              <h3 className="mt-4 text-lg font-black text-gray-900">
                Produk tidak ditemukan
              </h3>
              <p className="mt-1 max-w-md text-sm font-medium leading-6 text-gray-500">
                Coba ubah kata kunci atau filter kategori.
              </p>
              <button
                type="button"
                onClick={() => {
                  setSearchQuery("");
                  setActiveCategory("all");
                }}
                className="mt-5 inline-flex items-center gap-2 rounded-full border border-[#E83030] bg-white px-4 py-2 text-sm font-bold text-[#E83030] transition hover:bg-red-50"
              >
                Reset Filter
              </button>
            </div>
          ) : (
            <>
              <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
                {filteredProducts.map((product) => (
                  <button
                    key={product.id}
                    type="button"
                    onClick={() => router.push(`/product/${product.id}`)}
                    className="group flex h-full flex-col items-start rounded-2xl bg-white p-3 text-left shadow transition-all duration-200 ease-out hover:-translate-y-1 hover:shadow-xl active:scale-95 focus:outline-none sm:p-5 md:p-6"
                  >
                    <img
                      src={getProductImageUrl(product.img || product.image)}
                      alt={product.name || "Produk"}
                      loading="lazy"
                      className="mb-3 h-32 w-full rounded-xl bg-gray-50 object-cover transition-transform duration-200 group-hover:scale-[1.02] sm:mb-5 sm:h-52 md:h-60"
                      onError={(event) => {
                        event.currentTarget.src =
                          "https://via.placeholder.com/400x400?text=No+Image";
                      }}
                    />
                    <span className="mb-1.5 text-[11px] font-bold uppercase tracking-wide text-blue-700 sm:mb-2.5 sm:text-sm">
                      {product.brand || product.category || "Produk"}
                    </span>
                    <h3 className="mb-2 line-clamp-2 text-sm font-semibold leading-snug text-black sm:text-lg md:text-xl">
                      {product.name || "Produk Jualin"}
                    </h3>
                    <p className="mb-3 hidden h-12 overflow-hidden text-ellipsis break-all text-base leading-6 text-gray-500 [display:-webkit-box] [-webkit-box-orient:vertical] [-webkit-line-clamp:2] sm:block">
                      {product.description || "Tidak ada deskripsi."}
                    </p>
                    {formatOfferedAgo(product.created_at) && (
                      <div className="mb-2 flex min-w-0 items-center gap-1.5 text-[11px] font-semibold text-gray-400 sm:mb-3 sm:text-xs">
                        <Clock className="h-3 w-3" />
                        <span className="truncate">
                          {formatOfferedAgo(product.created_at)}
                        </span>
                      </div>
                    )}
                    <div className="mb-3 flex max-w-full items-center gap-1.5 self-start rounded-full border border-red-100 bg-red-50 px-2.5 py-1 sm:mb-4 sm:px-3 sm:py-1.5">
                      <User className="h-3 w-3 text-red-600" />
                      <span className="truncate text-[11px] font-medium text-red-800 sm:text-xs">
                        {seller.username || "Seller"}
                      </span>
                    </div>
                    <div className="mt-auto flex w-full flex-col items-start gap-0.5 pt-1 sm:flex-row sm:items-center sm:justify-between sm:gap-3 sm:pt-2">
                      <span className="text-sm font-bold text-black sm:text-lg">
                        {formatCurrency(product.price || 0)}
                      </span>
                      <span className="text-[11px] font-medium text-gray-600 sm:text-sm">
                        Stok: {product.stock ?? product.stock_quantity ?? 0}
                      </span>
                    </div>
                  </button>
                ))}
              </div>

              {meta.totalPages > 1 && !searchQuery && activeCategory === "all" && (
                <Pagination
                  currentPage={meta.currentPage}
                  totalPages={meta.totalPages}
                  onPageChange={setPage}
                />
              )}
            </>
          )}
        </section>
      </div>
    </main>
  );
}

function SellerMetric({ icon: Icon, label, value, badge = null }) {
  return (
    <div className="flex items-center gap-3 rounded-2xl border border-white/80 bg-white/80 px-4 py-3 shadow-sm">
      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-red-50 text-[#E83030] shadow-sm">
        <Icon className="h-5 w-5" />
      </div>
      <div className="min-w-0">
        <div className="text-xs font-bold text-gray-400">{label}</div>
        <div className="mt-0.5 flex items-center gap-1 text-sm font-black text-gray-950">
          <span className="truncate">{value}</span>
          {badge}
        </div>
      </div>
    </div>
  );
}

function StoreFilterOption({ active, label, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex w-full items-center gap-2 rounded-xl px-3 py-2 text-left text-xs font-black transition ${
        active
          ? "bg-red-50 text-[#E83030]"
          : "text-gray-700 hover:bg-gray-50 hover:text-[#E83030]"
      }`}
    >
      <span
        className={`h-2.5 w-2.5 rounded-full ${
          active ? "bg-[#E83030]" : "bg-gray-300"
        }`}
      />
      {label}
    </button>
  );
}
