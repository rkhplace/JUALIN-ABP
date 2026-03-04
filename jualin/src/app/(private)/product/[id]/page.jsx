"use client";
import { useParams } from "next/navigation";
import ProductDetailSection from "../sections/detail.jsx";
import RecommendedSection from "../sections/recommended.jsx";
import { useProductDetailQuery } from "@/hooks/product/useProductDetailQuery";
import { useProductsQuery } from "@/hooks/dashboard/useProductsQuery";
import { useSellerInfo } from "@/hooks/product/useSellerInfo";
import { ProductDetailSkeleton } from "@/components/ui/skeleton";
import React, { useMemo } from "react";

export default function ProductDetailPage() {
  const params = useParams();
  const productId = Number(params.id);

  const { product, isLoading: productLoading } =
    useProductDetailQuery(productId);
  const { seller, isLoading: sellerLoading } = useSellerInfo(
    product?.seller_id || null
  );

  // Calculate availability derived from stock
  const isProductAvailable = product && (product.stock ?? 0) > 0;

  const loading = productLoading || sellerLoading;

  const recParams = useMemo(
    () => ({
      per_page: 6,
      category: product?.category || undefined,
      min_stock: 1,
    }),
    [product?.category]
  );

  const { data: recData, isLoading: recommendationsLoading } = useProductsQuery(
    recParams,
    {
      enabled: !!product?.category,
      keepPreviousData: true,
      refetchOnWindowFocus: false,
    }
  );

  const recommendedProducts =
    recData?.products?.filter((p) => p.id !== productId) || [];

  return (
    <main className="bg-[#fafafa]">
      <div className="max-w-7xl mx-auto px-2 sm:px-4 pt-8">
        {loading ? (
          <ProductDetailSkeleton />
        ) : !isProductAvailable ? (
          <div className="flex flex-col items-center justify-center min-h-[50vh] text-center p-8">
            <h2 className="text-2xl font-bold text-gray-800 mb-2">Produk Tidak Tersedia</h2>
            <p className="text-gray-600">Maaf, stok produk ini sedang kosong atau produk telah dihapus.</p>
            <a href="/products" className="mt-6 px-6 py-2 bg-brand-red text-white rounded-full font-medium hover:bg-red-700 transition">
              Cari Produk Lain
            </a>
          </div>
        ) : (
          <>
            <ProductDetailSection product={product} seller={seller} />
            <RecommendedSection
              products={recommendedProducts}
              initialFilter={product?.category || "all"}
              showFilter={false}
              isLoading={recommendationsLoading}
            />
          </>
        )}
      </div>
    </main>
  );
}
