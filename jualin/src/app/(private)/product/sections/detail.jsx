"use client";
import React, { useContext, useState } from "react";
import { useRouter } from "next/navigation";
import Toast from "../../../../components/ui/Toast";
import Spinner from "../../../../components/ui/Spinner";
import useMidtransPayment from "../hooks/useMidtransPayment";
import { ChatContext } from "@/context/ChatProvider";
import { AuthContext } from "@/context/AuthProvider";
import { getProductImageUrl, getProfilePictureUrl } from "@/utils/imageHelper";
import { formatCurrency } from "@/utils/formatters/currency";

export default function ProductDetailSection({ product, seller }) {
  const router = useRouter();
  const { user } = useContext(AuthContext);
  const { startChat } = useContext(ChatContext);
  const { pay, loading, toast, setToast } = useMidtransPayment();
  const [isStartingChat, setIsStartingChat] = useState(false);

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
      <div className="flex flex-col md:flex-row gap-8 items-start bg-white rounded-2xl shadow p-6">
        <img
          src={getProductImageUrl(product.image)}
          alt={product.name}
          loading="lazy"
          className="w-full md:w-1/2 h-80 object-cover rounded-2xl shadow"
          onError={(e) => {
            e.target.src = "https://via.placeholder.com/400x400?text=No+Image";
          }}
        />
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
              onClick={() => pay(product)}
              disabled={loading}
            >
              {loading && <Spinner size="sm" color="white" />}
              {loading ? "Processing..." : "Buy Now"}
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
