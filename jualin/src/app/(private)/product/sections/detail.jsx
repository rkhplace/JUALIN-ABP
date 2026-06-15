"use client";
import React, { useContext, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { BadgeCheck } from "lucide-react";
import Toast from "../../../../components/ui/Toast";
import Spinner from "../../../../components/ui/Spinner";
import useMidtransPayment from "../hooks/useMidtransPayment";
import { ChatContext } from "@/context/ChatProvider";
import { AuthContext } from "@/context/AuthProvider";
import { reportService } from "@/services/backoffice/reportService";
import { getProductImageUrl, getProfilePictureUrl, getImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import PaymentMethodModal from "@/components/payment/PaymentMethodModal";
import { transactionService } from "@/services";
import VerifiedBadge from "@/components/ui/VerifiedBadge";

export default function ProductDetailSection({ product, seller }) {
  const router = useRouter();
  const { user } = useContext(AuthContext);
  const { startChat } = useContext(ChatContext);
  const { pay, loading, toast, setToast } = useMidtransPayment();
  const [isStartingChat, setIsStartingChat] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isWalletLoading, setIsWalletLoading] = useState(false);
  const [isSuccessModalOpen, setIsSuccessModalOpen] = useState(false);
  const [isReportModalOpen, setIsReportModalOpen] = useState(false);
  const [reportType, setReportType] = useState("");
  const isOwnProduct = user?.id && seller?.id && user.id === seller.id;
  const [reportDescription, setReportDescription] = useState("");
  const [isReportSubmitting, setIsReportSubmitting] = useState(false);
  const [reportErrors, setReportErrors] = useState({});
  const [selectedImageIndex, setSelectedImageIndex] = useState(0);
  const [isVerifiedSellerModalOpen, setIsVerifiedSellerModalOpen] =
    useState(false);

  useEffect(() => {
    if (
      typeof window === "undefined" ||
      user?.role !== "customer" ||
      !user?.id ||
      !seller?.id ||
      seller?.is_verified !== true
    ) {
      return;
    }

    const storageKey = `verified_seller_notice:${user.id}:${seller.id}`;
    if (localStorage.getItem(storageKey) === "true") return;

    localStorage.setItem(storageKey, "true");
    setIsVerifiedSellerModalOpen(true);
  }, [seller?.id, seller?.is_verified, user?.id, user?.role]);

  const reportReasons = [
    "Produk Terlarang",
    "Penipuan",
    "Pornografi",
    "Hak Cipta",
    "Kategori Tidak Sesuai",
    "Lainnya",
  ];

  const handleConfirmPayment = async (method) => {
    setIsModalOpen(false);

    if (method === "gateway") {
      pay(product, {
        onSuccess: () => {
          setIsSuccessModalOpen(true);
        }
      });
    } else if (method === "wallet") {
      setIsWalletLoading(true);
      try {
        await transactionService.payWallet({
          seller_id: product.seller_id,
          product_id: product.id,
        });

        // Show the success modal instead of a toast
        setIsSuccessModalOpen(true);
      } catch (err) {
        setToast({
          message: err.message || "Failed to process wallet payment",
          type: "error",
        });
      } finally {
        setIsWalletLoading(false);
      }
    }
  };

  const handleChatSeller = async () => {
    if (!user) {
      setToast({
        message: "Please login first to chat with seller",
        type: "error",
      });
      return;
    }

    if (!seller || !seller.id) {
      if (seller && seller.success === false) {
        if (seller.status_code === 401) {
          setToast({
            message: "Session expired. Please login to continue.",
            type: "error",
          });
          setTimeout(() => router.push("/auth/login"), 1500);
          return;
        }
        setToast({
          message: seller.message || "Seller information is not available",
          type: "error",
        });
        return;
      }

      setToast({
        message: "Seller information is not available",
        type: "error",
      });
      return;
    }

    if (user?.id && seller?.id && user.id === seller.id) {
      setToast({
        message: "You cannot chat with yourself",
        type: "error",
      });
      return;
    }

    setIsStartingChat(true);

    try {
      const sellerInfo = {
        name: seller?.username || seller?.email || "Seller",
        avatar: getProfilePictureUrl(seller?.profile_picture),
      };

      const productPayload = {
        id: product.id,
        name: product.name,
        price: product.price,
        image: product.image,
        slug: product.slug || null,
        description: product.description || "",
      };

      await startChat(seller.id, sellerInfo, productPayload);

      router.push("/chat");
    } catch (error) {
      console.error("❌ Error starting chat:", error);
      setToast({
        message: "Failed to start chat. Please try again.",
        type: "error",
      });
    } finally {
      setIsStartingChat(false);
    }
  };

  const handleReportClick = () => {
    if (!user) {
      setToast({
        message: "Please login first to report this product",
        type: "error",
      });
      return;
    }

    if (isOwnProduct) {
      setToast({
        message: "Anda tidak bisa melaporkan produk Anda sendiri.",
        type: "error",
      });
      return;
    }

    setIsReportModalOpen(true);
  };

  const handleCloseReportModal = () => {
    setIsReportModalOpen(false);
    setReportType("");
    setReportDescription("");
    setReportErrors({});
  };

  const validateReport = () => {
    const errors = {};

    if (!reportType) {
      errors.type = "Pilih alasan laporan produk";
    }

    if (!reportDescription.trim()) {
      errors.description = "Deskripsi laporan wajib diisi";
    }

    setReportErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmitProductReport = async (event) => {
    event.preventDefault();

    if (!validateReport()) {
      return;
    }

    setIsReportSubmitting(true);

    try {
      await reportService.createReport({
        product_id: product.id,
        type: reportType,
        description: reportDescription.trim(),
        reported_user_id: seller?.id || null,
        reported_username: seller?.username || null,
        target_username: seller?.username || null,
      });

      setToast({
        message: "Laporan produk berhasil dikirim. Terima kasih.",
        type: "success",
      });
      handleCloseReportModal();
    } catch (err) {
      setToast({
        message: err.message || "Gagal mengirim laporan produk",
        type: "error",
      });
      if (err.errors) {
        setReportErrors(err.errors);
      }
    } finally {
      setIsReportSubmitting(false);
    }
  };

  if (!product) {
    return (
      <div className="text-center py-12 text-gray-300">
        Stok produk kosong atau telah dihapus
      </div>
    );
  }

  return (
    <>
      {isVerifiedSellerModalOpen && (
        <div
          className="fixed inset-0 z-[70] flex items-center justify-center bg-black/45 p-4 backdrop-blur-sm"
          role="presentation"
        >
          <div
            className="w-full max-w-md rounded-[28px] bg-white px-6 py-8 text-center shadow-2xl sm:px-9"
            role="dialog"
            aria-modal="true"
            aria-labelledby="verified-seller-title"
          >
            <div className="mx-auto mb-5 flex h-24 w-24 items-center justify-center rounded-full bg-blue-50">
              <BadgeCheck className="h-14 w-14 fill-blue-500 text-white" />
            </div>
            <h2
              id="verified-seller-title"
              className="text-2xl font-bold text-gray-900"
            >
              Penjual Terverifikasi
            </h2>
            <p className="mt-4 text-sm leading-7 text-gray-500 sm:text-base">
              {seller?.username || "Penjual"} sudah melewati proses verifikasi
              Jualin. Badge ini membantu kamu membedakan penjual yang sudah
              tervalidasi dengan yang belum.
            </p>
            <button
              type="button"
              onClick={() => setIsVerifiedSellerModalOpen(false)}
              className="mt-7 w-full rounded-2xl bg-[#EF2F35] px-5 py-3.5 text-base font-semibold text-white shadow-lg shadow-red-200 transition hover:bg-[#D9252B] focus:outline-none focus:ring-4 focus:ring-red-100"
            >
              Mengerti
            </button>
          </div>
        </div>
      )}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
      <PaymentMethodModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onConfirm={handleConfirmPayment}
        walletBalance={user?.wallet_balance || 0}
        productPrice={product.price}
      />

      {/* Success Modal */}
      {isSuccessModalOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div
            className="bg-white rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden animate-in fade-in zoom-in duration-300 text-center p-8"
            role="dialog"
            aria-modal="true"
          >
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h3 className="text-2xl font-bold text-gray-900 mb-2">Pembayaran Berhasil!</h3>
            <p className="text-gray-600 mb-6">
              Terima kasih, pembayaran Anda telah berhasil diproses. Silakan cek riwayat pembelian Anda.
            </p>
            <div className="flex flex-col gap-3">
              <button
                onClick={() => setIsSuccessModalOpen(false)}
                className="w-full text-white bg-red-600 hover:bg-red-700 focus:ring-4 focus:outline-none focus:ring-red-300 font-bold rounded-xl text-md px-5 py-3 transition-colors"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}
      <div className="flex flex-col md:flex-row gap-4 md:gap-8 items-start bg-white rounded-2xl shadow p-4 md:p-6">
        {/* Image Gallery Section */}
        <div className="w-full md:w-1/2 flex flex-col gap-4">
          {/* Main Image */}
          <div className="relative bg-gray-100 rounded-2xl overflow-hidden shadow">
            <img
              src={
                Array.isArray(product.image) && product.image.length > 0
                  ? getImageUrl(product.image[selectedImageIndex])
                  : getProductImageUrl(product.img || product.image)
              }
              alt={product.name}
              loading="lazy"
              className="w-full h-56 sm:h-72 md:h-80 object-cover"
              onError={(e) => {
                e.target.src = "https://via.placeholder.com/400x400?text=No+Image";
              }}
            />
            {/* Image Counter Badge */}
            {Array.isArray(product.image) && product.image.length > 1 && (
              <div className="absolute top-3 right-3 bg-black/50 text-white px-3 py-1 rounded-full text-sm font-medium">
                {selectedImageIndex + 1} / {product.image.length}
              </div>
            )}
          </div>

          {/* Thumbnail Gallery */}
          {Array.isArray(product.image) && product.image.length > 1 && (
            <div className="flex gap-2 overflow-x-auto pb-1 md:pb-2">
              {product.image.map((img, idx) => (
                <button
                  key={idx}
                  onClick={() => setSelectedImageIndex(idx)}
                  className={`flex-shrink-0 w-20 h-20 rounded-lg overflow-hidden border-2 transition-all ${selectedImageIndex === idx
                      ? "border-red-500 scale-105"
                      : "border-gray-300 hover:border-gray-400"
                    }`}
                >
                  <img
                    src={getImageUrl(img)}
                    alt={`${product.name} ${idx + 1}`}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      e.target.src = "https://via.placeholder.com/80x80?text=No+Image";
                    }}
                  />
                </button>
              ))}
            </div>
          )}
        </div>
        <div className="flex-1">
          <h2 className="text-2xl md:text-3xl font-semibold mb-1 text-black">
            {product.name}
          </h2>
          <h1 className="text-lg md:text-2xl font-bold mb-4 md:mb-6 text-blue-700">
            {product.brand || product.category}
          </h1>
          <p className="text-sm md:text-base text-gray-600 mb-4 md:mb-6 break-words w-full line-clamp-4">{product.description}</p>

          {/* Seller Info */}
          <div className="flex items-center gap-3 mb-4 md:mb-6 p-3 md:p-4 bg-gray-50 rounded-xl border border-gray-100">
            <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden">
              {seller?.profile_picture ? (
                <img src={getProfilePictureUrl(seller.profile_picture)} alt={seller.username} className="w-full h-full object-cover" />
              ) : (
                <span className="text-gray-500 font-bold text-lg">{(seller?.username || 'S')[0].toUpperCase()}</span>
              )}
            </div>
            <div>
              <p className="font-semibold text-gray-900 flex items-center gap-1">
                {seller?.username || "Seller"}
                {seller?.is_verified && <VerifiedBadge size="sm" />}
              </p>
              {seller?.city && <p className="text-xs text-gray-500">{seller.city}</p>}
            </div>
          </div>

          <div className="mb-4 md:mb-6">
            <span className="block font-bold text-xl text-black mb-1">
              {formatCurrency(product.price)}
            </span>
            <span className="text-sm text-gray-600 font-medium">
              Stok tersedia: {product.stock} unit
            </span>
          </div>
          <div className="flex flex-col sm:flex-row w-full sm:w-auto gap-3">
            <button
              className="w-full sm:w-auto justify-center bg-red-500 text-white px-6 py-2 rounded-full font-semibold shadow hover:bg-red-600 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 cursor-pointer"
              onClick={() => {
                if (!user) {
                  setToast({
                    message: "Please login first to buy",
                    type: "error",
                  });
                  return;
                }
                setIsModalOpen(true);
              }}
              disabled={loading || isWalletLoading}
            >
              {(loading || isWalletLoading) && <Spinner size="sm" color="white" />}
              {(loading || isWalletLoading) ? "Processing..." : "Buy Now"}
            </button>
            <button
              onClick={handleChatSeller}
              className="w-full sm:w-auto justify-center px-6 py-2 rounded-full font-semibold border border-gray-300 text-gray-800 bg-white hover:bg-gray-100 transition shadow disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 cursor-pointer"
              aria-label="Open chat"
              disabled={isStartingChat}
            >
              {isStartingChat && <Spinner size="sm" color="gray" />}
              {isStartingChat ? "Starting chat..." : "Chat"}
            </button>
            <button
              onClick={handleReportClick}
              className="w-full sm:w-auto justify-center px-5 py-2 rounded-full font-semibold border border-red-400 text-red-700 bg-white hover:bg-red-50 transition shadow disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={isOwnProduct}
              title={isOwnProduct ? "Tidak dapat melaporkan produk sendiri" : undefined}
            >
              Laporkan Produk
            </button>
          </div>
        </div>
      </div>

      {isReportModalOpen && (
        <div
          className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm"
          onClick={handleCloseReportModal}
        >
          <div
            className="w-full max-w-[340px] sm:max-w-2xl bg-white rounded-2xl sm:rounded-3xl shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-300"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="px-5 py-4 sm:px-6 sm:py-5 border-b border-gray-200 bg-gray-50 flex items-center justify-between">
              <div>
                <h3 className="text-lg sm:text-xl font-semibold text-gray-900">Laporkan Produk</h3>
                <p className="text-xs sm:text-sm text-gray-500 mt-1">Pilih jenis laporan dan jelaskan detailnya.</p>
              </div>
              <button
                onClick={handleCloseReportModal}
                className="text-gray-500 hover:text-gray-700 transition"
                aria-label="Tutup laporan produk"
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleSubmitProductReport} className="px-5 py-5 sm:px-6 sm:py-6 space-y-4 sm:space-y-5">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Alasan Laporan <span className="text-red-500">*</span></label>
                <select
                  value={reportType}
                  onChange={(event) => {
                    setReportType(event.target.value);
                    setReportErrors((prev) => ({ ...prev, type: "" }));
                  }}
                  className={`w-full rounded-xl sm:rounded-2xl border px-4 py-2.5 sm:py-3 text-sm sm:text-base text-gray-700 focus:outline-none focus:ring-2 focus:ring-red-100 focus:border-red-400 ${reportErrors.type ? 'border-red-500 bg-red-50' : 'border-gray-200 bg-white'}`}
                >
                  <option value="">Pilih alasan laporan...</option>
                  {reportReasons.map((reason) => (
                    <option key={reason} value={reason}>{reason}</option>
                  ))}
                </select>
                {reportErrors.type && <p className="text-xs text-red-500 mt-2">{reportErrors.type}</p>}
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Detail Laporan <span className="text-red-500">*</span></label>
                <textarea
                  value={reportDescription}
                  onChange={(event) => {
                    setReportDescription(event.target.value);
                    setReportErrors((prev) => ({ ...prev, description: "" }));
                  }}
                  rows={4}
                  placeholder={reportType === 'Lainnya' ? 'Jelaskan alasan custom Anda untuk laporan produk ini...' : 'Tuliskan detail masalah produk di sini...'}
                  className={`w-full rounded-xl sm:rounded-2xl border px-4 py-2.5 sm:py-3 text-sm sm:text-base text-gray-700 focus:outline-none focus:ring-2 focus:ring-red-100 focus:border-red-400 ${reportErrors.description ? 'border-red-500 bg-red-50' : 'border-gray-200 bg-white'}`}
                />
                {reportErrors.description && <p className="text-xs text-red-500 mt-2">{reportErrors.description}</p>}
              </div>
              <div className="flex flex-col sm:flex-row items-stretch gap-3">
                <button
                  type="button"
                  onClick={handleCloseReportModal}
                  className="flex-1 rounded-xl sm:rounded-2xl border border-gray-200 px-5 py-2.5 sm:py-3 text-sm sm:text-base text-gray-700 font-semibold hover:bg-gray-50 transition"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isReportSubmitting}
                  className="flex-1 rounded-xl sm:rounded-2xl bg-red-600 text-white px-5 py-2.5 sm:py-3 text-sm sm:text-base font-semibold shadow hover:bg-red-700 transition disabled:opacity-70 disabled:cursor-not-allowed"
                >
                  {isReportSubmitting ? 'Mengirim...' : 'Kirim Laporan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
