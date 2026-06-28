"use client";

import React, { useContext, useEffect, useMemo, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import {
  ArrowLeft,
  BadgeCheck,
  Boxes,
  MapPin,
  MessageCircle,
  PackageSearch,
  ShieldCheck,
  Store,
  User,
} from "lucide-react";
import Spinner from "@/components/ui/Spinner";
import Toast from "@/components/ui/Toast";
import UserAvatar from "@/components/ui/UserAvatar";
import VerifiedBadge from "@/components/ui/VerifiedBadge";
import { ProductCardSkeleton } from "@/components/ui/skeleton";
import { AuthContext } from "@/context/AuthProvider";
import { ChatContext } from "@/context/ChatProvider";
import { sellerService } from "@/services/seller/sellerService";
import { userService } from "@/services/user/userService";
import { formatCurrency } from "@/utils/formatters/currency";
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

  useEffect(() => {
    let mounted = true;

    async function loadStoreProfile() {
      if (!sellerId) return;

      setIsLoading(true);
      try {
        const [sellerData, productData] = await Promise.all([
          userService.fetchById(sellerId),
          sellerService.fetchProducts(sellerId, 12, page),
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
      <main className="min-h-screen bg-[#F7F7F8] px-4 py-8">
        <div className="mx-auto max-w-6xl space-y-6">
          <div className="h-52 animate-pulse rounded-[28px] bg-white" />
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {[...Array(8)].map((_, index) => (
              <ProductCardSkeleton key={index} />
            ))}
          </div>
        </div>
      </main>
    );
  }

  if (!seller) {
    return (
      <main className="min-h-screen bg-[#F7F7F8] px-4 py-8">
        <div className="mx-auto flex min-h-[55vh] max-w-xl flex-col items-center justify-center text-center">
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
    <main className="min-h-screen bg-[#F7F7F8] px-4 py-6 sm:py-8">
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="mx-auto max-w-6xl space-y-6">
        <button
          type="button"
          onClick={() => router.back()}
          className="inline-flex items-center gap-2 rounded-full border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-700 shadow-sm transition hover:border-red-200 hover:text-[#E83030]"
        >
          <ArrowLeft className="h-4 w-4" />
          Kembali
        </button>

        <section className="overflow-hidden rounded-[28px] border border-gray-100 bg-white shadow-[0_22px_55px_rgba(15,23,42,0.08)]">
          <div className="relative bg-gradient-to-br from-[#E83030] to-[#FF5A5F] px-5 py-7 sm:px-8 sm:py-9">
            <div className="absolute right-8 top-0 h-36 w-36 rounded-full border border-white/15" />
            <div className="absolute -right-10 bottom-0 h-28 w-28 rounded-full border border-white/15" />
            <div className="relative flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
              <div className="flex items-center gap-4">
                <div className="rounded-[24px] bg-white/15 p-2 ring-1 ring-white/20">
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
                className="inline-flex items-center justify-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-black text-[#E83030] shadow-[0_14px_30px_rgba(127,29,29,0.22)] transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
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

          <div className="grid gap-3 px-5 py-5 sm:grid-cols-3 sm:px-8">
            <SellerMetric
              icon={Boxes}
              label="Produk Aktif"
              value={`${meta.totalProducts || products.length} produk`}
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
        </section>

        <section className="rounded-[24px] border border-gray-100 bg-white p-5 shadow-sm sm:p-6">
          <div className="mb-5 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 className="text-xl font-black text-gray-950">
                Barang yang Dijual
              </h2>
              <p className="mt-1 text-sm font-medium text-gray-500">
                Lihat produk aktif dari {seller.username || "seller"}.
              </p>
            </div>
            <div className="rounded-full bg-red-50 px-3 py-1.5 text-xs font-bold text-[#E83030]">
              {meta.totalProducts || products.length} produk
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
          ) : (
            <>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                {products.map((product) => (
                  <button
                    key={product.id}
                    type="button"
                    onClick={() => router.push(`/product/${product.id}`)}
                    className="group flex h-full flex-col rounded-2xl border border-gray-100 bg-white p-3 text-left shadow-sm transition hover:-translate-y-1 hover:border-red-100 hover:shadow-xl"
                  >
                    <img
                      src={getProductImageUrl(product.img || product.image)}
                      alt={product.name || "Produk"}
                      loading="lazy"
                      className="h-44 w-full rounded-xl bg-gray-50 object-cover transition group-hover:scale-[1.02]"
                      onError={(event) => {
                        event.currentTarget.src =
                          "https://via.placeholder.com/400x400?text=No+Image";
                      }}
                    />
                    <div className="mt-3 flex flex-1 flex-col">
                      <div className="text-xs font-black uppercase tracking-wide text-blue-700">
                        {product.brand || product.category || "Produk"}
                      </div>
                      <h3 className="mt-1 line-clamp-2 text-sm font-black text-gray-950">
                        {product.name || "Produk Jualin"}
                      </h3>
                      <p className="mt-1 line-clamp-2 text-xs font-medium leading-5 text-gray-500">
                        {product.description || "Tidak ada deskripsi."}
                      </p>
                      <div className="mt-auto flex items-center justify-between gap-3 pt-4">
                        <span className="text-base font-black text-gray-950">
                          {formatCurrency(product.price || 0)}
                        </span>
                        <span className="rounded-full bg-gray-100 px-2 py-1 text-[11px] font-bold text-gray-600">
                          Stok: {product.stock ?? product.stock_quantity ?? 0}
                        </span>
                      </div>
                    </div>
                  </button>
                ))}
              </div>

              {meta.totalPages > 1 && (
                <div className="mt-6 flex items-center justify-center gap-2">
                  <button
                    type="button"
                    onClick={() => setPage((current) => Math.max(1, current - 1))}
                    disabled={page <= 1}
                    className="rounded-full border border-gray-200 px-4 py-2 text-sm font-bold text-gray-700 disabled:opacity-40"
                  >
                    Sebelumnya
                  </button>
                  <span className="rounded-full bg-red-50 px-4 py-2 text-sm font-black text-[#E83030]">
                    {meta.currentPage} / {meta.totalPages}
                  </span>
                  <button
                    type="button"
                    onClick={() =>
                      setPage((current) => Math.min(meta.totalPages, current + 1))
                    }
                    disabled={page >= meta.totalPages}
                    className="rounded-full border border-gray-200 px-4 py-2 text-sm font-bold text-gray-700 disabled:opacity-40"
                  >
                    Berikutnya
                  </button>
                </div>
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
    <div className="flex items-center gap-3 rounded-2xl border border-gray-100 bg-gray-50 px-4 py-3">
      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-white text-[#E83030] shadow-sm">
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
