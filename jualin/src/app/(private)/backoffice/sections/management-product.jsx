"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Trash2, Edit2 } from "lucide-react";
import { productService } from "@/services/product/productService";
import { getProductImageUrl } from "@/utils/imageHelper";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import Toast from "@/components/ui/Toast";

export default function ProductManagement() {
  const router = useRouter(); // Use router
  const [products, setProducts] = useState([]);
  const [productsLoading, setProductsLoading] = useState(false);
  const [showProductModal, setShowProductModal] = useState(false);

  // Delete & Toast State
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);
  const [toast, setToast] = useState({
    show: false,
    message: "",
    type: "info",
  });

  // Fetch Products (Recently Added)
  useEffect(() => {
    const fetchProducts = async () => {
      try {
        setProductsLoading(true);
        // Fetch recently added: sort by created_at desc
        const response = await productService.fetchAll({
          page: 1,
          limit: 3,
          sort: "created_at",
          order: "desc",
        });
        setProducts((response.products || []).slice(0, 3));
      } catch (error) {
        console.error("Failed to fetch products:", error);
      } finally {
        setProductsLoading(false);
      }
    };
    fetchProducts();
  }, []);

  // Handle Delete Click (Open Modal)
  const handleDeleteClick = (product) => {
    setProductToDelete(product);
    setDeleteModalOpen(true);
  };

  // Handle Confirm Delete
  const handleConfirmDelete = async () => {
    if (!productToDelete) return;

    try {
      await productService.delete(productToDelete.id); // Keeping productService for admin
      setProducts(products.filter((p) => p.id !== productToDelete.id)); // Optimistic update

      setToast({
        show: true,
        message: "Produk berhasil dihapus",
        type: "success",
      });
    } catch (error) {
      console.error("Failed to delete product:", error);
      setToast({
        show: true,
        message: "Gagal menghapus produk",
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

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h3 className="text-base sm:text-lg font-semibold text-[#1F1F1F]">
          Management Product
        </h3>
        <div className="flex items-center gap-3">
          <a
            href="/backoffice/products"
            className="text-xs sm:text-sm font-medium text-red-500 hover:underline"
          >
            View All Product
          </a>
        </div>
      </div>

      {productsLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 sm:gap-8">
          {[...Array(3)].map((_, i) => (
            <div
              key={i}
              className="bg-white rounded-2xl h-72 sm:h-96 animate-pulse border border-gray-100"
            ></div>
          ))}
        </div>
      ) : products.length === 0 ? (
        <div className="p-8 text-center text-gray-500 bg-white rounded-xl border border-gray-100">
          No recent products found.
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 sm:gap-8">
          {products.map((p) => (
            <div
              key={p.id}
              className="bg-white rounded-xl sm:rounded-2xl p-4 sm:p-6 shadow-lg hover:shadow-2xl transition-all duration-200 text-left group border border-gray-100"
            >
              <div className="relative mb-4">
                <img
                  src={getProductImageUrl(p.image || p.img)}
                  alt={p.name}
                  className="w-full h-36 sm:h-60 object-cover rounded-lg sm:rounded-xl shadow-sm transition-transform duration-200 group-hover:scale-[1.02]"
                  onError={(e) => {
                    if (e.target.src.includes("/placeholder.svg")) return;
                    e.target.src = "/placeholder.svg";
                  }}
                />
              </div>

              <h3 className="font-bold text-base sm:text-xl mb-1 text-gray-900 line-clamp-1">
                {p.name}
              </h3>

              <p className="text-blue-600 font-medium text-xs sm:text-sm mb-2 uppercase tracking-wide">
                {p.category || "Uncategorized"}
              </p>

              <div className="text-xs sm:text-sm text-gray-500 mb-4 sm:mb-6">
                Stok: {p.stock_quantity || 0} | Kondisi:{" "}
                {p.condition === "new" ? "Baru" : "Bekas"}
              </div>

              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() =>
                    router.push(`/backoffice/products/${p.id}/edit`)
                  }
                  className="px-3 sm:px-4 py-1.5 sm:py-2 rounded-full border border-gray-200 text-gray-700 font-medium text-xs sm:text-sm hover:bg-gray-50 hover:border-gray-300 transition-colors shadow-sm"
                >
                  Edit
                </button>

                <div className="px-3 sm:px-4 py-1.5 sm:py-2 bg-brand-red text-white rounded-full text-xs sm:text-sm font-bold shadow-md shadow-red-200">
                  Rp {p.price?.toLocaleString("id-ID")}
                </div>

                <button
                  type="button"
                  onClick={() => handleDeleteClick(p)}
                  className="px-3 sm:px-4 py-1.5 sm:py-2 rounded-full bg-red-50 text-red-600 font-medium text-xs sm:text-sm hover:bg-red-100 transition-colors border border-red-100"
                >
                  Hapus
                </button>
              </div>
            </div>
          ))}


        </div>
      )}

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
    </div>
  );
}
