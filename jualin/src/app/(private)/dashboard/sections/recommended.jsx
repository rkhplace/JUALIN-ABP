"use client";
import React, { useMemo, useState, useEffect, useRef } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { User } from "lucide-react";
import { useProductsQuery } from "@/hooks/dashboard/useProductsQuery";
import ProductFilter from "@/components/product/ProductFilter";
import { ProductCardSkeleton } from "@/components/ui/skeleton";
import Pagination from "@/components/ui/Pagination";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
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
      className="w-full my-8 animate-fade-in scroll-mt-24"
      ref={sectionRef}
    >
      <h2 className="text-2xl font-bold mb-4 text-center text-black">
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
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
          {[...Array(6)].map((_, idx) => (
            <ProductCardSkeleton key={idx} />
          ))}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
            {products.map((product, idx) => (
              <a
                key={product.id}
                href={`/product/${product.id}`}
                className="group bg-white rounded-2xl shadow p-6 flex flex-col items-start transition-all duration-200 ease-out hover:shadow-xl hover:-translate-y-1 active:scale-95 focus:outline-none"
                style={{ cursor: "pointer" }}
                tabIndex={0}
              >
                <img
                  src={getProductImageUrl(product.image)}
                  alt={product.name || "Foto Produk"}
                  className="w-full h-60 object-cover rounded-xl mb-4 transition-transform duration-200 group-hover:scale-[1.02]"
                  onError={(e) => {
                    e.target.src =
                      "https://via.placeholder.com/400x400?text=No+Image";
                  }}
                />
                <span className="font-bold text-blue-700 uppercase text-sm mb-2 tracking-wide">
                  {product.brand || product.category}
                </span>
                <h3 className="font-semibold text-xl mb-1 text-black">
                  {product.name}
                </h3>
                <p className="text-gray-500 text-base mb-2 line-clamp-2 break-all text-ellipsis overflow-hidden">
                  {product.description}
                </p>
                <div className="flex items-center gap-1.5 mb-3 bg-red-50 px-3 py-1.5 rounded-full border border-red-100 self-start">
                  <User size={12} className="text-red-600" />
                  <span className="text-xs text-red-800 font-medium">
                    {product.seller?.username || "Unknown"}
                  </span>
                </div>
                <div className="flex justify-between items-center w-full">
                  <span className="font-bold text-lg text-black">
                    {formatCurrency(product.price)}
                  </span>
                  <span className="text-sm text-gray-600 font-medium">
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
