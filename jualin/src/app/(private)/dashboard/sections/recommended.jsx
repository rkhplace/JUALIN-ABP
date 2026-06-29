"use client";
import React, { useMemo, useState, useEffect, useRef } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Clock, User } from "lucide-react";
import { useProductsQuery } from "@/hooks/dashboard/useProductsQuery";
import ProductFilter from "@/components/product/ProductFilter";
import { ProductCardSkeleton } from "@/components/ui/skeleton";
import Pagination from "@/components/ui/Pagination";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import { formatOfferedAgo } from "@/utils/formatters/date";
import { smoothScrollTo } from "@/utils/scroll";

export default function RecommendedSection() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const q = (searchParams.get("q") || "").trim().toLowerCase();
  const sectionRef = useRef(null);

  const [activeFilter, setActiveFilter] = useState("all");
  const [page, setPage] = useState(1);

  useEffect(() => {
    setPage(1);
    if (q && sectionRef.current) {
      smoothScrollTo(sectionRef.current, 500, 100);
    }
  }, [activeFilter, q]);

  const queryParams = {
    page,
    per_page: 6,
    category: activeFilter !== "all" ? activeFilter : undefined,
    name: q || undefined,
    min_stock: 1,
  };

  const { data, isLoading } = useProductsQuery(queryParams);
  const { products, totalPages, currentPage } = data || {
    products: [],
    totalPages: 1,
    currentPage: 1,
  };

  const handlePageChange = (newPage) => {
    setPage(newPage);
    if (sectionRef.current) {
      smoothScrollTo(sectionRef.current, 500, 100);
    }
  };

  const handleSeeAll = () => {
    const params = new URLSearchParams();
    if (activeFilter && activeFilter !== "all") {
      params.set("category", activeFilter);
    }
    const query = params.toString();
    router.push(query ? `/products?${query}` : "/products");
  };

  return (
    <section
      className="w-full my-6 sm:my-8 animate-fade-in scroll-mt-24"
      ref={sectionRef}
    >
      <h2 className="px-3 text-center text-xl font-bold text-black sm:text-2xl">
        Produk yang mungkin kamu suka
      </h2>
      <ProductFilter
        activeFilter={activeFilter}
        setActiveFilter={setActiveFilter}
      />
      <div className="w-full flex justify-center sm:justify-end mb-4">
        <button
          type="button"
          onClick={handleSeeAll}
          className="text-sm text-brand-red font-semibold hover:text-red-600 hover:opacity-90 hover:drop-shadow-sm transform hover:scale-105 transition-all duration-150 cursor-pointer"
        >
          Lihat semua
        </button>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
          {[...Array(6)].map((_, idx) => (
            <ProductCardSkeleton key={idx} />
          ))}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
            {products.map((product, idx) => (
              <a
                key={product.id}
                href={`/product/${product.id}`}
                className="group flex h-full flex-col items-start rounded-2xl bg-white p-3 text-left shadow transition-all duration-200 ease-out hover:-translate-y-1 hover:shadow-xl active:scale-95 focus:outline-none sm:p-5 md:p-6"
                style={{ cursor: "pointer" }}
                tabIndex={0}
              >
                <img
                  src={getProductImageUrl(product.img || product.image)}
                  alt={product.name || "Foto Produk"}
                  className="mb-3 h-32 w-full rounded-xl object-cover transition-transform duration-200 group-hover:scale-[1.02] sm:mb-5 sm:h-52 md:h-60"
                  onError={(e) => {
                    e.target.src =
                      "https://via.placeholder.com/400x400?text=No+Image";
                  }}
                />
                <span className="mb-1.5 text-[11px] font-bold uppercase tracking-wide text-blue-700 sm:mb-2.5 sm:text-sm">
                  {product.brand || product.category}
                </span>
                <h3 className="mb-2 line-clamp-2 text-sm font-semibold leading-snug text-black sm:text-lg md:text-xl">
                  {product.name}
                </h3>
                <p className="hidden sm:block h-12 text-gray-500 text-base leading-6 mb-3 overflow-hidden text-ellipsis break-all [display:-webkit-box] [-webkit-line-clamp:2] [-webkit-box-orient:vertical]">
                  {product.description}
                </p>
                {formatOfferedAgo(product.created_at) && (
                  <div className="mb-2 flex min-w-0 items-center gap-1.5 text-[11px] font-semibold text-gray-400 sm:mb-3 sm:text-xs">
                    <Clock size={12} />
                    <span className="truncate">
                      {formatOfferedAgo(product.created_at)}
                    </span>
                  </div>
                )}
                <div className="mb-3 flex max-w-full items-center gap-1.5 self-start rounded-full border border-red-100 bg-red-50 px-2.5 py-1 sm:mb-4 sm:px-3 sm:py-1.5">
                  <User size={12} className="text-red-600" />
                  <span className="truncate text-[11px] font-medium text-red-800 sm:text-xs">
                    {product.seller?.username || "Unknown"}
                  </span>
                </div>
                <div className="mt-auto flex w-full flex-col items-start gap-0.5 pt-1 sm:flex-row sm:items-center sm:justify-between sm:gap-2 sm:pt-2">
                  <span className="text-sm font-bold text-black sm:text-lg">
                    {formatCurrency(product.price)}
                  </span>
                  <span className="text-[11px] font-medium text-gray-600 sm:text-sm">
                    Stok: {product.stock}
                  </span>
                </div>
              </a>
            ))}
          </div>

          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={handlePageChange}
          />
        </>
      )
      }
    </section >
  );
}
