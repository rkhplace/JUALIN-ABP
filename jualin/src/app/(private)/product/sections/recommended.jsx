"use client";
import React, { useState } from "react";
import ProductFilter from "./filter.jsx";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import { formatOfferedAgo } from "@/utils/formatters/date";
import { Clock, User } from "lucide-react";
import { ProductCardSkeleton } from "@/components/ui/skeleton";

export default function RecommendedSection({
  products,
  initialFilter = "all",
  showFilter = true,
  isLoading = false,
}) {
  const [activeFilter, setActiveFilter] = useState(initialFilter);

  const filteredProducts = showFilter
    ? activeFilter === "all"
      ? products
      : products.filter((p) => p.category === activeFilter)
    : products;

  return (
    <section className="w-full my-8 animate-fade-in">
      <h2 className="text-xl sm:text-2xl font-bold mb-4 text-center text-black">
        Produk Terkait
      </h2>
      {showFilter && (
        <ProductFilter
          activeFilter={activeFilter}
          setActiveFilter={setActiveFilter}
        />
      )}

      {isLoading ? (
        <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
          {[...Array(3)].map((_, idx) => (
            <ProductCardSkeleton key={idx} />
          ))}
        </div>
      ) : filteredProducts.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <p className="text-lg">Tidak ada produk terkait</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-3 md:gap-8">
          {filteredProducts.map((product, idx) => (
            <a
              key={product.id}
              href={`/product/${product.id}`}
              className="group flex flex-col items-start rounded-2xl bg-white p-3 shadow transition-all duration-200 ease-out hover:-translate-y-1 hover:shadow-xl active:scale-95 focus:outline-none sm:p-5 md:p-6"
              style={{ cursor: "pointer" }}
              tabIndex={0}
            >
              <img
                src={getProductImageUrl(product.img || product.image)}
                alt={product.name}
                loading="lazy"
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
              <p className="mb-3 hidden h-12 overflow-hidden text-ellipsis break-all text-base leading-6 text-gray-500 [display:-webkit-box] [-webkit-box-orient:vertical] [-webkit-line-clamp:2] sm:block">
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
      )}
    </section>
  );
}
