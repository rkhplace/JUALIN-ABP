"use client";

import React, { useEffect, useMemo, useState, useRef, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { User } from "lucide-react";
import { useProductsQuery } from "@/hooks/dashboard/useProductsQuery";
import ProductFilter from "@/components/product/ProductFilter";
import { ProductCardSkeleton } from "@/components/ui/skeleton";
import Pagination from "@/components/ui/Pagination";
import { smoothScrollTo } from "@/utils/scroll";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";

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
    <main className="bg-white min-h-screen">
      <div className="max-w-6xl mx-auto px-4 py-6 space-y-6">
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
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
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
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
                {products.map((p) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => handleCardClick(p.id)}
                    className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-2xl transition-all duration-200 text-left group"
                  >
                    <img
                      src={getProductImageUrl(p.image)}
                      alt={p.name}
                      loading="lazy"
                      className="w-full h-60 object-cover rounded-xl mb-4 transition-transform duration-200 group-hover:scale-[1.02]"
                      onError={(e) => {
                        e.target.src =
                          "https://via.placeholder.com/400x400?text=No+Image";
                      }}
                    />
                    <span className="font-bold text-blue-700 uppercase text-sm mb-2 tracking-wide">
                      {p.brand || p.category}
                    </span>
                    <h3 className="font-semibold text-xl mb-1 text-black">
                      {p.name}
                    </h3>
                    <p className="text-gray-500 text-base mb-2 line-clamp-2 break-all text-ellipsis overflow-hidden">
                      {p.description || "Tidak ada informasi"}
                    </p>
                    <div className="flex justify-start mb-3">
                      <div className="flex items-center gap-1.5 bg-red-50 px-3 py-1.5 rounded-full border border-red-100">
                        <User size={12} className="text-red-600" />
                        <span className="text-xs text-red-800 font-medium">
                          {p.seller?.username || "Unknown"}
                        </span>
                      </div>
                    </div>
                    <div className="flex justify-between items-center mt-4">
                      <span className="px-4 py-2 bg-brand-red text-white rounded-full text-sm font-medium">
                        {formatCurrency(p.price)}
                      </span>
                      <span className="text-sm text-gray-600 font-medium">
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
        <main className="bg-white min-h-screen">
          <div className="max-w-6xl mx-auto px-4 py-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
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

