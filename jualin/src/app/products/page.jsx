"use client";

import React, { useEffect, useMemo, useState, useRef, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Clock, User } from "lucide-react";
import { useProductsQuery } from "@/hooks/dashboard/useProductsQuery";
import ProductFilter from "@/components/product/ProductFilter";
import { ProductCardSkeleton } from "@/components/ui/skeleton";
import Pagination from "@/components/ui/Pagination";
import { smoothScrollTo } from "@/utils/scroll";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import { formatOfferedAgo } from "@/utils/formatters/date";

function ProductsPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const productsRef = useRef(null);

  const categoryFromQuery = (
    searchParams.get("category") || "all"
  ).toLowerCase();

  const [activeFilter, setActiveFilter] = useState(categoryFromQuery);
  const [searchQuery, setSearchQuery] = useState(
    (searchParams.get("q") || "").trim()
  );

  const [page, setPage] = useState(1);

  useEffect(() => {
    setActiveFilter(categoryFromQuery);
    const newQuery = (searchParams.get("q") || "").trim();
    setSearchQuery(newQuery);

    if (newQuery && productsRef.current) {
      smoothScrollTo(productsRef.current, 500, 100);
    }

    setPage(1);
  }, [categoryFromQuery, searchParams]);

  const queryParams = {
    page,
    per_page: 6,
    name: searchQuery || undefined,
    category: activeFilter !== "all" ? activeFilter : undefined,
    min_stock: 1, // Filter out out-of-stock products from backend
  };

  const { data, isLoading } = useProductsQuery(queryParams);
  const { products, totalPages, currentPage } = data || {
    products: [],
    totalPages: 1,
    currentPage: 1,
  };

  const handleCardClick = (id) => {
    router.push(`/product/${id}`);
  };

  const handlePageChange = (newPage) => {
    setPage(newPage);
    if (productsRef.current) {
      smoothScrollTo(productsRef.current, 500, 100);
    }
  };

  return (
    <main className="jualin-page-bg min-h-screen">
      <div className="jualin-content-layer max-w-6xl mx-auto px-4 py-6 space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Semua Produk</h1>
          </div>
        </div>

        <div className="flex flex-col gap-4 scroll-mt-24" ref={productsRef}>
          <ProductFilter
            activeFilter={activeFilter}
            setActiveFilter={setActiveFilter}
          />

          {isLoading ? (
            <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
              {[...Array(6)].map((_, idx) => (
                <ProductCardSkeleton key={idx} />
              ))}
            </div>
          ) : products.length === 0 ? (
            <div className="border-2 border-dashed rounded-2xl p-8 text-center text-gray-500">
              <p className="font-medium mb-2">Produk tidak ditemukan</p>
              <p className="text-sm">
                Coba ubah kategori atau kata kunci pencarianmu.
              </p>
            </div>
          ) : (
            <>
              <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
                {products.map((p) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => handleCardClick(p.id)}
                    className="group flex h-full flex-col rounded-2xl bg-white p-3 text-left shadow-lg transition-all duration-200 hover:shadow-2xl sm:p-5 md:p-6"
                  >
                    <img
                      src={getProductImageUrl(p.image)}
                      alt={p.name}
                      loading="lazy"
                      className="mb-3 h-32 w-full rounded-xl object-cover transition-transform duration-200 group-hover:scale-[1.02] sm:mb-5 sm:h-52 md:h-60"
                      onError={(e) => {
                        e.target.src =
                          "https://via.placeholder.com/400x400?text=No+Image";
                      }}
                    />
                    <span className="mb-1.5 text-[11px] font-bold uppercase tracking-wide text-blue-700 sm:mb-2.5 sm:text-sm">
                      {p.brand || p.category}
                    </span>
                    <h3 className="mb-2 line-clamp-2 text-sm font-semibold leading-snug text-black sm:text-lg md:text-xl">
                      {p.name}
                    </h3>
                    <p className="hidden sm:block h-12 text-gray-500 text-base leading-6 mb-3 overflow-hidden text-ellipsis break-all [display:-webkit-box] [-webkit-line-clamp:2] [-webkit-box-orient:vertical]">
                      {p.description || "Tidak ada informasi"}
                    </p>
                    {formatOfferedAgo(p.created_at) && (
                      <div className="mb-2 flex min-w-0 items-center gap-1.5 text-[11px] font-semibold text-gray-400 sm:mb-3 sm:text-xs">
                        <Clock size={12} />
                        <span className="truncate">
                          {formatOfferedAgo(p.created_at)}
                        </span>
                      </div>
                    )}
                    <div className="mb-3 flex max-w-full items-center gap-1.5 self-start rounded-full border border-red-100 bg-red-50 px-2.5 py-1 sm:mb-4 sm:px-3 sm:py-1.5">
                      <User size={12} className="text-red-600" />
                      <span className="truncate text-[11px] font-medium text-red-800 sm:text-xs">
                        {p.seller?.username || "Unknown"}
                      </span>
                    </div>
                    <div className="mt-auto flex w-full flex-col items-start gap-0.5 pt-1 sm:flex-row sm:items-center sm:justify-between sm:gap-2 sm:pt-2">
                      <span className="text-sm font-bold text-black sm:text-lg">
                        {formatCurrency(p.price)}
                      </span>
                      <span className="text-[11px] font-medium text-gray-600 sm:text-sm">
                        Stok: {p.stock}
                      </span>
                    </div>
                  </button>
                ))}
              </div>

              <Pagination
                currentPage={currentPage}
                totalPages={totalPages}
                onPageChange={handlePageChange}
              />
            </>
          )}
        </div>
      </div>
    </main>
  );
}

export default function ProductsPage() {
  return (
    <Suspense
      fallback={
        <main className="jualin-page-bg min-h-screen">
          <div className="jualin-content-layer max-w-6xl mx-auto px-4 py-6 space-y-6">
            <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
              {[...Array(6)].map((_, idx) => (
                <ProductCardSkeleton key={idx} />
              ))}
            </div>
          </div>
        </main>
      }
    >
      <ProductsPageContent />
    </Suspense>
  );
}

