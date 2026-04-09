"use client";
import React, { useContext, useState } from "react";
import { useRouter } from "next/navigation";
import Toast from "../../../../components/ui/Toast";
import Spinner from "../../../../components/ui/Spinner";
import useMidtransPayment from "../hooks/useMidtransPayment";
import { ChatContext } from "@/context/ChatProvider";
import { AuthContext } from "@/context/AuthProvider";
import { getProductImageUrl, getProfilePictureUrl, getImageUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";
import PaymentMethodModal from "@/components/payment/PaymentMethodModal";
import { transactionService } from "@/services";

export default function ProductDetailSection({ product, seller }) {
  const router = useRouter();
  const { user } = useContext(AuthContext);
  const { startChat } = useContext(ChatContext);
  const { pay, loading, toast, setToast } = useMidtransPayment();
  const [isStartingChat, setIsStartingChat] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isWalletLoading, setIsWalletLoading] = useState(false);
  const [isSuccessModalOpen, setIsSuccessModalOpen] = useState(false);
  const [selectedImageIndex, setSelectedImageIndex] = useState(0);

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
      setTimeout(() => router.push("/login"), 2000);
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

      await startChat(seller.id, sellerInfo, product.id);

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

  if (!product) {
    return (
      <div className="text-center py-12 text-gray-300">
        Stok produk kosong atau telah dihapus
      </div>
    );
  }

  return (
    <>
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
      <div className="flex flex-col md:flex-row gap-8 items-start bg-white rounded-2xl shadow p-6">
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
              className="w-full h-80 object-cover"
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
            <div className="flex gap-2 overflow-x-auto pb-2">
              {product.image.map((img, idx) => (
                <button
                  key={idx}
                  onClick={() => setSelectedImageIndex(idx)}
                  className={`flex-shrink-0 w-20 h-20 rounded-lg overflow-hidden border-2 transition-all ${
                    selectedImageIndex === idx
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
          <h2 className="text-3xl font-semibold mb-1 text-black">
            {product.name}
          </h2>
          <h1 className="text-2xl font-bold mb-6 text-blue-700">
            {product.brand || product.category}
          </h1>
          <p className="text-gray-600 mb-6 break-all w-full">{product.description}</p>

          {/* Seller Info */}
          <div className="flex items-center gap-3 mb-6 p-4 bg-gray-50 rounded-xl border border-gray-100">
            <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden">
              {seller?.profile_picture ? (
                <img src={getProfilePictureUrl(seller.profile_picture)} alt={seller.username} className="w-full h-full object-cover" />
              ) : (
                <span className="text-gray-500 font-bold text-lg">{(seller?.username || 'S')[0].toUpperCase()}</span>
              )}
            </div>
            <div>
              <p className="font-semibold text-gray-900">{seller?.username || "Seller"}</p>
              {seller?.city && <p className="text-xs text-gray-500">{seller.city}</p>}
            </div>
          </div>

          <div className="mb-6">
            <span className="block font-bold text-xl text-black mb-1">
              {formatCurrency(product.price)}
            </span>
            <span className="text-sm text-gray-600 font-medium">
              Stok tersedia: {product.stock} unit
            </span>
          </div>
          <div className="flex items-center gap-3">
            <button
              className="bg-red-500 text-white px-6 py-2 rounded-full font-semibold shadow hover:bg-red-600 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 cursor-pointer"
              onClick={() => {
                if (!user) {
                  setToast({
                    message: "Please login first to buy",
                    type: "error",
                  });
                  setTimeout(() => router.push("/login"), 2000);
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
              className="px-6 py-2 rounded-full font-semibold border border-gray-300 text-gray-800 bg-white hover:bg-gray-100 transition shadow disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 cursor-pointer"
              aria-label="Open chat"
              disabled={isStartingChat}
            >
              {isStartingChat && <Spinner size="sm" color="gray" />}
              {isStartingChat ? "Starting chat..." : "Chat"}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}
