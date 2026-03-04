"use client";
import React, { useState } from "react";
import ProductFilter from "./filter.jsx";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import { User } from "lucide-react";
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
      <h2 className="text-2xl font-bold mb-4 text-center text-black">
        Produk Terkait
      </h2>
      {showFilter && (
        <ProductFilter
          activeFilter={activeFilter}
          setActiveFilter={setActiveFilter}
        />
      )}

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
          {[...Array(3)].map((_, idx) => (
            <ProductCardSkeleton key={idx} />
          ))}
        </div>
      ) : filteredProducts.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <p className="text-lg">Tidak ada produk terkait</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-8">
          {filteredProducts.map((product, idx) => (
            <a
              key={product.id}
              href={`/product/${product.id}`}
              className="group bg-white rounded-2xl shadow p-6 flex flex-col items-start transition-all duration-200 ease-out hover:shadow-xl hover:-translate-y-1 active:scale-95 focus:outline-none"
              style={{ cursor: "pointer" }}
              tabIndex={0}
            >
              <img
                src={getProductImageUrl(product.image)}
                alt={product.name}
                loading="lazy"
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
      )}
    </section>
  );
}
