"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Check, Search, SlidersHorizontal, X } from "lucide-react";
import { sellerService } from "@/services/seller/sellerService";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import Toast from "@/components/ui/Toast";
import Pagination from "@/components/ui/Pagination";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import { smoothScrollTo } from "@/utils/scroll";

const PRODUCTS_PER_PAGE = 6;

const STOCK_FILTERS = [
  { value: "all", label: "Semua" },
  { value: "empty", label: "Stok Habis" },
  { value: "available", label: "Stok Tersedia" },
];

const getProductStock = (product) =>
  Number(product?.stock_quantity ?? product?.stock ?? 0);

export default function SellerProductsPage() {
  const router = useRouter();
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [stockFilter, setStockFilter] = useState("all");
  const [draftCategoryFilter, setDraftCategoryFilter] = useState("all");
  const [draftStockFilter, setDraftStockFilter] = useState("all");
  const [filterModalOpen, setFilterModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);
  const scrollRef = React.useRef(null);
  const [toast, setToast] = useState({
    show: false,
    message: "",
    type: "info",
  });

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const data = await sellerService.fetchMyProducts(200, 1);
        const list = data.products || [];
        setProducts(Array.isArray(list) ? list : []);
      } catch (err) {
        console.error("Failed to load seller products:", err);
        setProducts([]);
      } finally {
        setLoading(false);
      }
    };

    load();
  }, []);

  useEffect(() => {
    if (scrollRef.current) {
      smoothScrollTo(scrollRef.current, 500, 100);
    }
  }, [page]);

  const categories = useMemo(() => {
    return [
      ...new Set(
        products
          .map((product) => String(product?.category || "").trim())
          .filter(Boolean)
      ),
    ].sort((first, second) => first.localeCompare(second, "id"));
  }, [products]);

  const filteredProducts = useMemo(() => {
    const normalizedQuery = searchQuery.trim().toLowerCase();

    return products.filter((product) => {
      const name = String(product?.name || "").toLowerCase();
      const category = String(product?.category || "").trim();
      const normalizedCategory = category.toLowerCase();
      const stock = getProductStock(product);

      const matchesSearch =
        !normalizedQuery ||
        name.includes(normalizedQuery) ||
        normalizedCategory.includes(normalizedQuery);
      const matchesCategory =
        categoryFilter === "all" ||
        normalizedCategory === categoryFilter.trim().toLowerCase();
      const matchesStock =
        stockFilter === "empty"
          ? stock <= 0
          : stockFilter === "available"
            ? stock > 0
            : true;

      return matchesSearch && matchesCategory && matchesStock;
    });
  }, [categoryFilter, products, searchQuery, stockFilter]);

  const totalPages = Math.max(
    1,
    Math.ceil(filteredProducts.length / PRODUCTS_PER_PAGE)
  );
  const paginatedProducts = filteredProducts.slice(
    (page - 1) * PRODUCTS_PER_PAGE,
    page * PRODUCTS_PER_PAGE
  );
  const hasActiveFilter =
    categoryFilter !== "all" || stockFilter !== "all";

  useEffect(() => {
    if (page > totalPages) {
      setPage(totalPages);
    }
  }, [page, totalPages]);

  const handleDeleteClick = (product) => {
    setProductToDelete(product);
    setDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!productToDelete) return;

    try {
      const success = await sellerService.deleteProduct(productToDelete.id);

      if (!success) {
        throw new Error("Gagal menghapus produk");
      }

      const data = await sellerService.fetchMyProducts(200, 1);
      setProducts(data.products || []);
      setToast({
        show: true,
        message: "Produk berhasil dihapus",
        type: "success",
      });
    } catch (err) {
      console.error("Delete error:", err);
      setToast({
        show: true,
        message: "Gagal menghapus produk. Silakan coba lagi.",
        type: "error",
      });
    } finally {
      setDeleteModalOpen(false);
      setProductToDelete(null);
    }
  };

  const openFilterModal = () => {
    setDraftCategoryFilter(categoryFilter);
    setDraftStockFilter(stockFilter);
    setFilterModalOpen(true);
  };

  const applyFilter = () => {
    setCategoryFilter(draftCategoryFilter);
    setStockFilter(draftStockFilter);
    setPage(1);
    setFilterModalOpen(false);
  };

  const resetFilter = () => {
    setDraftCategoryFilter("all");
    setDraftStockFilter("all");
    setCategoryFilter("all");
    setStockFilter("all");
    setPage(1);
    setFilterModalOpen(false);
  };

  return (
    <main className="min-h-screen bg-white" ref={scrollRef}>
      <div className="mx-auto max-w-6xl space-y-6 px-4 py-5 pb-24 sm:py-6 sm:pb-10">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Produk Saya</h1>
            {!loading && products.length > 0 && (
              <p className="mt-1 text-sm text-gray-500">
                {filteredProducts.length} produk ditampilkan
              </p>
            )}
          </div>
          <button
            type="button"
            onClick={() => router.push("/seller/products/new")}
            className="h-10 w-10 rounded-lg bg-brand-red font-bold text-white shadow-sm transition-all duration-200 hover:bg-red-600 hover:shadow-lg hover:shadow-red-200"
            aria-label="Tambah produk"
          >
            +
          </button>
        </div>

        {!loading && products.length > 0 && (
          <div className="flex items-center gap-3 rounded-2xl border border-gray-200 bg-white p-3 shadow-sm">
            <label className="flex min-w-0 flex-1 items-center gap-3 rounded-xl bg-gray-50 px-4 py-3">
              <Search className="h-5 w-5 flex-none text-gray-400" />
              <input
                type="search"
                value={searchQuery}
                onChange={(event) => {
                  setSearchQuery(event.target.value);
                  setPage(1);
                }}
                placeholder="Cari produk..."
                className="min-w-0 flex-1 bg-transparent text-sm text-gray-900 outline-none placeholder:text-gray-400"
              />
            </label>
            <button
              type="button"
              onClick={openFilterModal}
              className={`inline-flex h-12 items-center justify-center gap-2 rounded-xl border px-4 text-sm font-semibold shadow-sm transition ${
                hasActiveFilter
                  ? "border-brand-red bg-brand-red text-white hover:bg-red-600"
                  : "border-red-200 bg-white text-brand-red hover:bg-red-50"
              }`}
              aria-label="Filter produk"
            >
              <SlidersHorizontal className="h-5 w-5" />
              <span className="hidden sm:inline">Filter</span>
            </button>
          </div>
        )}

        {loading ? (
          <div className="py-10 text-center text-gray-500">
            Memuat produk...
          </div>
        ) : products.length === 0 ? (
          <div className="rounded-2xl border-2 border-dashed p-8 text-center text-gray-500">
            <p className="mb-2 font-medium">Belum ada produk</p>
            <p className="mb-4 text-sm">
              Tambahkan produk pertama Anda untuk mulai berjualan.
            </p>
            <button
              type="button"
              onClick={() => router.push("/seller/products/new")}
              className="rounded-full bg-brand-red px-4 py-2 text-sm font-medium text-white shadow-sm transition-all duration-200 hover:bg-red-600 hover:shadow-lg hover:shadow-red-200"
            >
              Tambah Produk
            </button>
          </div>
        ) : filteredProducts.length === 0 ? (
          <div className="rounded-2xl border-2 border-dashed border-gray-200 p-8 text-center text-gray-500">
            <p className="font-medium text-gray-700">Produk tidak ditemukan</p>
            <p className="mt-2 text-sm">
              Coba ubah kata pencarian atau reset filter produk.
            </p>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-8 md:grid-cols-3">
              {paginatedProducts.map((product) => (
                <div
                  key={product.id}
                  className="bg-white rounded-2xl p-4 sm:p-6 shadow-lg hover:shadow-2xl transition-shadow text-left"
                >
                  <div className="flex justify-center mb-4">
                    <img
                      src={getProductImageUrl(product.image)}
                      alt={product.name}
                      className="w-full h-36 sm:h-60 object-cover rounded-xl transition-transform duration-200 group-hover:scale-[1.02]"
                      onError={(event) => {
                        event.target.src = "/ProfilePhoto.png";
                      }}
                    />
                  </div>
                  <h3 className="font-semibold text-gray-900 text-base sm:text-xl mb-2 line-clamp-2">
                    {product.name}
                  </h3>
                  <p className="text-sm text-blue-600 font-medium uppercase tracking-wide mb-2">
                    {product.category || "Tidak ada kategori"}
                  </p>
                  <p className="text-xs sm:text-sm text-gray-500 mb-4">
                    Stok: {getProductStock(product).toLocaleString("id-ID")} |
                    Kondisi:{" "}
                    {product.condition === "new" ? "Baru" : "Bekas"}
                  </p>
                  <div className="flex flex-wrap items-center gap-3">
                    <button
                      type="button"
                      onClick={() =>
                        router.push(`/seller/products/${product.id}/edit`)
                      }
                      className="px-4 py-2 border border-gray-300 rounded-full text-sm hover:bg-gray-50 font-medium"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => router.push(`/product/${product.id}`)}
                      className="px-4 py-2 bg-brand-red text-white rounded-full text-sm hover:bg-red-600 font-medium"
                    >
                      {formatCurrency(product.price)}
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteClick(product)}
                      className="px-4 py-2 bg-red-50 text-red-600 border border-red-100 rounded-full text-sm hover:bg-red-100 hover:text-red-700 font-medium transition-colors"
                    >
                      Hapus
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <Pagination
              currentPage={page}
              totalPages={totalPages}
              onPageChange={setPage}
            />
          </>
        )}
      </div>

      <ConfirmationModal
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        onConfirm={handleConfirmDelete}
        title="Hapus Produk?"
        message="Produk yang dihapus tidak dapat dipulihkan. Apakah Anda yakin ingin melanjutkan?"
        confirmText="Hapus"
        cancelText="Batal"
        isDanger={true}
      />

      {filterModalOpen && (
        <div
          className="fixed inset-0 z-[90] flex items-end justify-center bg-black/50 backdrop-blur-sm sm:items-center sm:p-4"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setFilterModalOpen(false);
            }
          }}
        >
          <div className="w-full rounded-t-3xl bg-white p-5 shadow-2xl sm:max-w-xl sm:rounded-3xl sm:p-6">
            <div className="mx-auto mb-5 h-1 w-12 rounded-full bg-gray-200 sm:hidden" />
            <div className="mb-5 flex items-center justify-between">
              <h2 className="text-xl font-bold text-gray-900">Filter Produk</h2>
              <button
                type="button"
                onClick={() => setFilterModalOpen(false)}
                className="rounded-full p-2 text-gray-400 transition hover:bg-gray-100 hover:text-gray-700"
                aria-label="Tutup filter"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div>
              <p className="mb-3 font-semibold text-gray-900">Kategori</p>
              <div className="flex flex-wrap gap-3">
                {["all", ...categories].map((category) => {
                  const isActive = draftCategoryFilter === category;

                  return (
                    <button
                      key={category}
                      type="button"
                      onClick={() => setDraftCategoryFilter(category)}
                      className={`inline-flex items-center gap-2 rounded-full border px-4 py-2.5 text-sm font-medium transition ${
                        isActive
                          ? "border-brand-red bg-brand-red text-white shadow-sm"
                          : "border-gray-300 bg-white text-gray-600 hover:border-red-300 hover:bg-red-50"
                      }`}
                    >
                      {isActive && <Check className="h-4 w-4" />}
                      {category === "all" ? "Semua" : category}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="mt-6">
              <p className="mb-3 font-semibold text-gray-900">Stok</p>
              <div className="flex flex-wrap gap-3">
                {STOCK_FILTERS.map((filter) => {
                  const isActive = draftStockFilter === filter.value;

                  return (
                    <button
                      key={filter.value}
                      type="button"
                      onClick={() => setDraftStockFilter(filter.value)}
                      className={`inline-flex items-center gap-2 rounded-full border px-4 py-2.5 text-sm font-medium transition ${
                        isActive
                          ? "border-brand-red bg-brand-red text-white shadow-sm"
                          : "border-gray-300 bg-white text-gray-600 hover:border-red-300 hover:bg-red-50"
                      }`}
                    >
                      {isActive && <Check className="h-4 w-4" />}
                      {filter.label}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="mt-8 grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={resetFilter}
                className="rounded-xl border border-brand-red px-4 py-3 font-semibold text-brand-red transition hover:bg-red-50"
              >
                Reset
              </button>
              <button
                type="button"
                onClick={applyFilter}
                className="rounded-xl bg-brand-red px-4 py-3 font-semibold text-white shadow-sm transition hover:bg-red-600"
              >
                Terapkan
              </button>
            </div>
          </div>
        </div>
      )}

      {toast.show && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast((current) => ({ ...current, show: false }))}
        />
      )}
    </main>
  );
}
