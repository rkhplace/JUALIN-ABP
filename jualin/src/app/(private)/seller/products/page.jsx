"use client";
import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { sellerService } from "@/services/seller/sellerService";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import Toast from "@/components/ui/Toast";
import { getProductImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";

import Pagination from "@/components/ui/Pagination";
import { smoothScrollTo } from "@/utils/scroll";

export default function SellerProductsPage() {
  const router = useRouter();
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [currentPage, setCurrentPage] = useState(1);
  const scrollRef = React.useRef(null);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);
  const [toast, setToast] = useState({
    show: false,
    message: "",
    type: "info",
  });

  useEffect(() => {
    if (scrollRef.current) {
      smoothScrollTo(scrollRef.current, 500, 100);
    }

    const storedUser =
      typeof window !== "undefined"
        ? JSON.parse(localStorage.getItem("user") || "null")
        : null;

    const sellerId =
      storedUser?.id || storedUser?.user_id || storedUser?.userId || 1;

    const load = async () => {
      setLoading(true);
      try {
        const data = await sellerService.fetchProducts(sellerId, 6, page);

        const list = data.products || [];
        setProducts(Array.isArray(list) ? list : []);
        setTotalPages(data.totalPages || 1);
        setCurrentPage(data.currentPage || 1);
      } catch (err) {
        console.error("❌ Failed to load seller products:", err);
        setProducts([]);
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [page]);

  const handleDeleteClick = (product) => {
    setProductToDelete(product);
    setDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!productToDelete) return;

    try {
      const success = await sellerService.deleteProduct(productToDelete.id);

      if (success) {
        if (products.length === 1 && page > 1) {
          setPage((prev) => prev - 1);
        } else {
          const storedUser =
            typeof window !== "undefined"
              ? JSON.parse(localStorage.getItem("user") || "null")
              : null;
          const sellerId = storedUser?.id || storedUser?.user_id || 1;
          const data = await sellerService.fetchProducts(sellerId, 6, page);
          setProducts(data.products || []);
          setTotalPages(data.totalPages || 1);
        }

        setToast({
          show: true,
          message: "Produk berhasil dihapus",
          type: "success",
        });
      } else {
        throw new Error("Gagal menghapus produk");
      }
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

  const closeToast = () => {
    setToast({ ...toast, show: false });
  };

  const handlePageChange = (newPage) => {
    setPage(newPage);
  };

  return (
    <main className="bg-white min-h-screen" ref={scrollRef}>
      <div className="max-w-6xl mx-auto px-4 py-6 space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Produk Saya</h1>
          <button
            onClick={() => router.push("/seller/products/new")}
            className="px-4 py-2 bg-brand-red text-white rounded-lg hover:bg-red-600 hover:shadow-lg hover:shadow-red-200 transition-all duration-200 shadow-sm font-medium"
          >
            Tambah Produk
          </button>
        </div>

        {loading ? (
          <div className="text-center text-gray-500 py-10">
            Memuat produk...
          </div>
        ) : products.length === 0 ? (
          <div className="border-2 border-dashed rounded-2xl p-8 text-center text-gray-500">
            <p className="font-medium mb-2">Belum ada produk</p>
            <p className="text-sm mb-4">
              Tambahkan produk pertama Anda untuk mulai berjualan.
            </p>
            <button
              onClick={() => router.push("/seller/products/new")}
              className="px-4 py-2 bg-brand-red text-white rounded-full text-sm hover:bg-red-600 hover:shadow-lg hover:shadow-red-200 transition-all duration-200 shadow-sm font-medium"
            >
              Tambah Produk
            </button>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {products.map((p) => (
                <div
                  key={p.id}
                  className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-2xl transition-shadow"
                >
                  <div className="flex justify-center mb-4">
                    <img
                      src={getProductImageUrl(p.image)}
                      alt={p.name}
                      className="w-full h-60 object-cover rounded-xl mb-4 transition-transform duration-200 group-hover:scale-[1.02]"
                      onError={(e) => {
                        e.target.src = "/ProfilePhoto.png";
                      }}
                    />
                  </div>
                  <h3 className="font-semibold text-gray-900 text-base text-center mb-2 line-clamp-2">
                    {p.name}
                  </h3>
                  <p className="text-sm text-gray-600 text-center mb-2">
                    {p.category || "Tidak ada kategori"}
                  </p>
                  <p className="text-xs text-gray-500 text-center mb-4">
                    Stok: {p.stock_quantity || 0} | Kondisi:{" "}
                    {p.condition === "new" ? "Baru" : "Bekas"}
                  </p>
                  <div className="flex justify-center gap-3">
                    <button
                      onClick={() =>
                        router.push(`/seller/products/${p.id}/edit`)
                      }
                      className="px-4 py-2 border border-gray-300 rounded-full text-sm hover:bg-gray-50 font-medium"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => router.push(`/product/${p.id}`)}
                      className="px-4 py-2 bg-brand-red text-white rounded-full text-sm hover:bg-red-600 font-medium"
                    >
                      {formatCurrency(p.price)}
                    </button>
                    <button
                      onClick={() => handleDeleteClick(p)}
                      className="px-4 py-2 bg-red-50 text-red-600 border border-red-100 rounded-full text-sm hover:bg-red-100 hover:text-red-700 font-medium transition-colors"
                    >
                      Hapus
                    </button>
                  </div>
                </div>
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

      {toast.show && (
        <Toast message={toast.message} type={toast.type} onClose={closeToast} />
      )}
    </main>
  );
}
