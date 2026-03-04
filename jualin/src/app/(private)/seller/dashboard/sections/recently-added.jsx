"use client";
import React from "react";
import { useRouter } from "next/navigation";
import DropdownMenu from "@/components/ui/DropdownMenu";
import { MoreHorizontal, Plus } from "lucide-react";
import { getProductImageUrl } from "@/utils/imageHelper";
import { sellerService } from "@/services/seller/sellerService";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import Toast from "@/components/ui/Toast";
import { useState } from "react";

const RecentlyAddedSection = ({ products, isLoading = false }) => {
  const router = useRouter();
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);
  const [toast, setToast] = useState({
    show: false,
    message: "",
    type: "info",
  });
  const [deletedProductIds, setDeletedProductIds] = useState([]);

  const handleEdit = (productId) => {
    router.push(`/seller/products/${productId}/edit`);
  };

  const handleView = (productId) => {
    router.push(`/product/${productId}`);
  };

  const handleDelete = (productId) => {
    setProductToDelete(productId);
    setDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!productToDelete) return;

    try {
      const success = await sellerService.deleteProduct(productToDelete);

      if (success) {
        setDeletedProductIds([...deletedProductIds, productToDelete]);
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

  const formatRupiah = (price) => {
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      minimumFractionDigits: 0,
    }).format(price);
  };

  const visibleProducts = Array.isArray(products)
    ? products.filter((p) => !deletedProductIds.includes(p.id))
    : [];

  const hasProducts = visibleProducts.length > 0;

  return (
    <div className="bg-white rounded-xl shadow-lg hover:shadow-2xl transition-shadow duration-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-lg font-semibold text-gray-900">
            Produk Terbaru
          </h2>
          <p className="text-sm text-gray-600">Produk yang baru ditambahkan</p>
        </div>
        <button
          onClick={() => router.push("/seller/products")}
          className="text-sm text-brand-red hover:text-red-600 font-medium"
        >
          Lihat Semua
        </button>
      </div>

      <div className="grid grid-cols-5 gap-4">
        {isLoading ? (
          <>
            {[...Array(4)].map((_, index) => (
              <div
                key={index}
                className="bg-white rounded-2xl p-4 shadow-lg animate-pulse"
              >
                <div className="relative">
                  <div className="absolute top-0 right-0 h-6 w-6 bg-gray-200 rounded-full"></div>
                  <div className="flex justify-center mb-3">
                    <div className="h-20 w-full bg-gray-200 rounded-lg"></div>
                  </div>
                </div>
                <div className="text-center">
                  <div className="h-4 bg-gray-200 rounded mb-2"></div>
                  <div className="h-3 bg-gray-200 rounded mb-3 w-3/4 mx-auto"></div>
                  <div className="h-8 bg-gray-200 rounded-full w-24 mx-auto"></div>
                </div>
              </div>
            ))}
            <div className="border-2 border-dashed rounded-2xl p-4 min-h-[180px] flex items-center justify-center">
              <button
                onClick={() => router.push("/seller/products/new")}
                className="h-12 w-12 rounded-full border-2 border-dashed border-gray-400 text-gray-500 hover:text-gray-700 hover:border-gray-700 flex items-center justify-center"
              >
                <Plus className="h-6 w-6" />
              </button>
            </div>
          </>
        ) : hasProducts ? (
          <>
            {visibleProducts.slice(0, 4).map((product) => (
              <div
                key={product.id}
                className="bg-white rounded-2xl p-4 shadow-lg hover:shadow-2xl transition-shadow duration-200"
              >
                <div className="relative">
                  <div className="absolute top-0 right-0 h-6 w-6 text-gray-400 flex items-center justify-center">
                    <DropdownMenu
                      trigger={<MoreHorizontal className="h-4 w-4" />}
                      items={[
                        {
                          label: "Edit Produk",
                          onClick: () => handleEdit(product.id),
                        },
                        {
                          label: "Hapus Produk",
                          onClick: () => handleDelete(product.id),
                          variant: "danger",
                        },
                      ]}
                    />
                  </div>
                  <div className="flex justify-center mb-3">
                    <img
                      src={getProductImageUrl(product.image)}
                      alt={product.name}
                      className="h-20 object-contain"
                      onError={(e) => {
                        e.target.src = "/ProfilePhoto.png";
                      }}
                    />
                  </div>
                </div>
                <div className="text-center">
                  <h3 className="font-semibold text-gray-900 text-sm truncate">
                    {product.name}
                  </h3>
                  <p className="text-xs text-gray-600 mb-3">
                    {product.size ||
                      product.brand ||
                      product.category ||
                      "Tidak ada informasi ukuran / brand"}
                  </p>
                  <button
                    onClick={() => handleView(product.id)}
                    className="bg-brand-red text-white rounded-full px-4 py-1 text-sm hover:bg-red-600"
                  >
                    {formatRupiah(product.price)}
                  </button>
                </div>
              </div>
            ))}
            {/* Add New Product Card - selalu di posisi ke-5 */}
            <div className="border-2 border-dashed rounded-2xl p-4 min-h-[180px] flex items-center justify-center">
              <button
                onClick={() => router.push("/seller/products/new")}
                className="h-12 w-12 rounded-full border-2 border-dashed border-gray-400 text-gray-500 hover:text-gray-700 hover:border-gray-700 flex items-center justify-center"
              >
                <Plus className="h-6 w-6" />
              </button>
            </div>
          </>
        ) : (
          <>
            {/* Empty state untuk 4 kolom pertama */}
            <div className="col-span-4 flex flex-col items-center justify-center text-center text-gray-500 border-2 border-dashed rounded-2xl p-6">
              <p className="font-medium mb-1">Belum ada produk terbaru</p>
              <p className="text-sm mb-3">
                Tambahkan produk pertama Anda agar tampil di sini.
              </p>
              <button
                onClick={() => router.push("/seller/products/new")}
                className="inline-flex items-center gap-2 bg-brand-red text-white rounded-full px-4 py-2 text-sm hover:bg-red-600"
              >
                <Plus className="h-4 w-4" />
                Tambah Produk
              </button>
            </div>
            {/* Add New Product Card - selalu di posisi ke-5 */}
            <div className="border-2 border-dashed rounded-2xl p-4 min-h-[180px] flex items-center justify-center">
              <button
                onClick={() => router.push("/seller/products/new")}
                className="h-12 w-12 rounded-full border-2 border-dashed border-gray-400 text-gray-500 hover:text-gray-700 hover:border-gray-700 flex items-center justify-center"
              >
                <Plus className="h-6 w-6" />
              </button>
            </div>
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
    </div>
  );
};

export default RecentlyAddedSection;
