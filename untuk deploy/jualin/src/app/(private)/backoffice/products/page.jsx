"use client";

import { useState, useEffect, Suspense } from "react";
import { useRouter } from "next/navigation";
import { Plus, Edit2, Trash2, Search, ArrowLeft, User } from "lucide-react";
import { productService } from "@/services/product/productService";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import Pagination from "@/components/ui/Pagination";
import { ProductCardSkeleton } from "@/components/ui/skeleton";
import Navbar from "@/components/ui/Navbar";
import BackofficeSidebar from "../sections/backoffice-sidebar";

export default function BackofficeProductsPage() {
  const router = useRouter();
  const [products, setProducts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // Filtering & Pagination
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(9); // Matches grid better (3x3)
  const [totalItems, setTotalItems] = useState(0);

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        setIsLoading(true);
        const response = await productService.fetchAll({
          page: currentPage,
          limit: itemsPerPage,
          search: searchQuery,
          sort: "created_at",
          order: "desc",
        });

        setProducts(response.products || []);
        // Adapt total count strategy based on API response
        setTotalItems(
          response.pagination?.total || response.products?.length || 0
        );
      } catch (error) {
        console.error("Failed to fetch products:", error);
      } finally {
        setIsLoading(false);
      }
    };

    const debounce = setTimeout(() => {
      fetchProducts();
    }, 300);

    return () => clearTimeout(debounce);
  }, [currentPage, itemsPerPage, searchQuery]);

  const handleDelete = async (id) => {
    if (confirm("Are you sure you want to delete this product?")) {
      try {
        await productService.delete(id);
        setProducts(products.filter((p) => p.id !== id));
        setTotalItems((prev) => prev - 1);
      } catch (error) {
        console.error("Failed to delete product:", error);
        alert("Failed to delete product");
      }
    }
  };

  const handleEdit = (id) => {
    alert(`Edit functionality for product ${id} coming soon`);
  };

  const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors text-gray-500"
          >
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-[#1F1F1F] tracking-tight">
              Semua Produk
            </h1>
            <p className="text-sm text-gray-500">
              Kelola produk yang anda miliki
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3 w-full sm:w-auto">
          <div className="relative flex-1 sm:flex-initial sm:min-w-[240px]">
            <input
              type="text"
              placeholder="Search products..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500 transition-all bg-white"
            />
            <Search
              className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
              size={16}
            />
          </div>

          <button
            type="button"
            onClick={() => router.push("/backoffice/products/add")}
            className="bg-[#E53935] hover:bg-[#D32F2F] text-white px-4 py-2 rounded-xl text-sm font-medium flex items-center gap-2 shadow-sm transition-colors whitespace-nowrap"
          >
            <Plus size={16} />
            <span className="hidden sm:inline">Tambah Produk</span>
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, idx) => (
            <ProductCardSkeleton key={idx} />
          ))}
        </div>
      ) : products.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center text-gray-500 border border-dashed border-gray-200">
          <div className="mx-auto w-12 h-12 bg-gray-50 rounded-full flex items-center justify-center mb-3">
            <Search className="text-gray-400" />
          </div>
          <p className="font-medium">No products found</p>
          <p className="text-sm mt-1">Try adjusting your search terms</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
          {products.map((p) => (
            <div
              key={p.id}
              className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-2xl transition-all duration-200 text-center group border border-gray-100"
            >
              <div className="relative mb-4">
                <img
                  src={getProductImageUrl(p.image || p.img)}
                  alt={p.name}
                  loading="lazy"
                  className="w-full h-60 object-cover rounded-xl shadow-sm transition-transform duration-200 group-hover:scale-[1.02]"
                  onError={(e) => {
                    if (e.target.src.includes("/placeholder.svg")) return;
                    e.target.src = "/placeholder.svg";
                  }}
                />
              </div>

              <h3 className="font-bold text-xl mb-1 text-gray-900 line-clamp-1">
                {p.name}
              </h3>

              <p className="text-blue-600 font-medium text-sm mb-2 uppercase tracking-wide">
                {p.brand || p.category || "Uncategorized"}
              </p>

              <div className="text-sm text-gray-500 mb-6">
                Stok: {p.stock_quantity || p.stock || 0} | Kondisi:{" "}
                {p.condition === "new" ? "Baru" : "Bekas"}
              </div>

              <div className="flex items-center justify-center gap-3">
                <button
                  type="button"
                  onClick={() =>
                    router.push(`/backoffice/products/${p.id}/edit`)
                  }
                  className="px-4 py-2 rounded-full border border-gray-200 text-gray-700 font-medium text-sm hover:bg-gray-50 hover:border-gray-300 transition-colors shadow-sm"
                >
                  Edit
                </button>

                <div className="px-4 py-2 bg-brand-red text-white rounded-full text-sm font-bold shadow-md shadow-red-200">
                  {formatCurrency(p.price)}
                </div>

                <button
                  type="button"
                  onClick={() => handleDelete(p.id)}
                  className="px-4 py-2 rounded-full bg-red-50 text-red-600 font-medium text-sm hover:bg-red-100 transition-colors border border-red-100"
                >
                  Hapus
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Pagination */}
      <div className="flex justify-center pt-4">
        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          onPageChange={setCurrentPage}
        />
      </div>
    </div>
  );
}
