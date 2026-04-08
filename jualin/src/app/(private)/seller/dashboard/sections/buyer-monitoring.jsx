"use client";
import React, { useState, useMemo, useContext, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
  Search,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { ChatContext } from "@/context/ChatProvider";
import { useAuth } from "@/context/AuthProvider";
import { getProfilePictureUrl, getProductImageUrl } from "@/utils/imageHelper";
import { escrowService } from "@/services";

const BuyerMonitoringSection = ({ orders = [], isLoading = false }) => {
  const router = useRouter();
  const { openChatWithUser } = useContext(ChatContext);
  const { updateUser } = useAuth();
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [perPage, setPerPage] = useState(8);
  const [orderList, setOrderList] = useState(orders);

  // Escrow Claim State
  const [claimModalOpen, setClaimModalOpen] = useState(false);
  const [claimOrderId, setClaimOrderId] = useState(null);
  const [authCode, setAuthCode] = useState("");
  const [claimLoading, setClaimLoading] = useState(false);
  const [claimToast, setClaimToast] = useState(null);

  useEffect(() => {
    setOrderList(orders);
  }, [orders]);

  const handleClaimSubmit = async (e) => {
    e.preventDefault();
    if (!authCode.trim()) return;

    setClaimLoading(true);
    setClaimToast(null);
    try {
      const response = await escrowService.claimPayment(claimOrderId, authCode.trim());
      const nextStatus = response?.data?.transaction?.status || "verified";
      const walletBalance = Number(response?.data?.wallet_balance);

      setOrderList((currentOrders) =>
        currentOrders.map((order) =>
          String(order.id) === String(claimOrderId)
            ? { ...order, status: nextStatus }
            : order
        )
      );

      if (Number.isFinite(walletBalance)) {
        updateUser((currentUser) =>
          currentUser
            ? { ...currentUser, wallet_balance: walletBalance }
            : currentUser
        );
      }

      setClaimToast({ type: "success", message: "Payment successfully claimed to your wallet." });

      setTimeout(() => {
        setClaimModalOpen(false);
        setAuthCode("");
      }, 1200);
    } catch (err) {
      setClaimToast({ type: "error", message: err?.message || "Failed to claim payment. Please check the authentication code." });
    } finally {
      setClaimLoading(false);
    }
  };

  const openClaimModal = (orderId) => {
    setClaimOrderId(orderId);
    setAuthCode("");
    setClaimToast(null);
    setClaimModalOpen(true);
  };

  const buyerActivities =
    orderList.length > 0
      ? orderList.map((order) => ({
        id: order.id,
        buyerId: order.customer?.id,
        buyerName: order.customer?.username || "Unknown Buyer",
        productName: order.items?.[0]?.product?.name || "Product",
        productImage: getProductImageUrl(order.items?.[0]?.product?.image),
        category: order.items?.[0]?.product?.category || "General",
        amount: order.total_amount || 0,
        status: order.status || "pending",
        time: order.created_at
          ? new Date(order.created_at).toLocaleString("id-ID")
          : "Recently",
        avatar: getProfilePictureUrl(order.customer?.profile_picture),
      }))
      : [];
  const handleVerifyOrder = (orderId) =>
    router.push(`/seller/orders/${orderId}/verify`);

  const handleChatBuyer = async (buyerId) => {
    if (!buyerId) {
      alert("Buyer ID tidak tersedia");
      return;
    }

    try {
      await openChatWithUser(buyerId);
      router.push("/chat");
    } catch (error) {
      console.error("Failed to open chat:", error);
      alert(
        "Cannot open chat with this buyer. No existing conversation found."
      );
    }
  };

  const getStatusBadge = (status) => {
    const badges = {
      pending: {
        text: "Pending",
        class: "bg-red-100 text-red-700 border border-red-200",
      },
      waiting_cod: {
        text: "Waiting for COD verification",
        class: "bg-orange-100 text-orange-700 border border-orange-200",
      },
      verified: {
        text: "Verified",
        class: "bg-green-100 text-green-700 border border-green-200",
      },
      processing: {
        text: "Processing",
        class: "bg-blue-100 text-blue-700 border border-blue-200",
      },
      completed: {
        text: "Transaction completed",
        class: "bg-gray-100 text-gray-700 border border-gray-200",
      },
      refunded: {
        text: "Refunded to wallet",
        class: "bg-purple-100 text-purple-700 border border-purple-200",
      },
    };
    return badges[status] || badges.completed;
  };

  const filtered = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    const base = q
      ? buyerActivities.filter((b) =>
        [b.buyerName, b.productName, b.status].some((t) =>
          String(t).toLowerCase().includes(q)
        )
      )
      : buyerActivities;
    const start = (currentPage - 1) * perPage;
    return base.slice(start, start + perPage);
  }, [buyerActivities, searchQuery, currentPage, perPage]);

  const totalCount = buyerActivities.length;
  const totalPages = Math.max(1, Math.ceil(totalCount / perPage));

  return (
    <div className="bg-white rounded-xl shadow-lg hover:shadow-2xl transition-shadow duration-200 p-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4">
        Monitoring Buyer
      </h2>

      {/* Search & Filter */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="relative flex-1">
          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari Pembeli..."
            className="w-full px-4 py-2 pr-10 border rounded-full border-gray-300 focus:ring-2 focus:ring-brand-red focus:border-brand-red outline-none"
            disabled={isLoading}
          />
          <button className="absolute right-1 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-brand-red text-white flex items-center justify-center">
            <Search className="h-4 w-4" />
          </button>
        </div>
        <div>
          <select
            defaultValue="7days"
            className="w-full sm:w-40 rounded-lg border border-gray-300 px-3 py-2 text-sm"
            disabled={isLoading}
          >
            <option value="7days">Last 7 Days</option>
            <option value="30days">Last 30 Days</option>
            <option value="90days">Last 90 Days</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="text-sm text-gray-500">
              <th className="text-left py-3 px-2 font-medium">Item</th>
              <th className="text-left py-3 px-2 font-medium">Category</th>
              <th className="text-left py-3 px-2 font-medium">Date</th>
              <th className="text-left py-3 px-2 font-medium">Time</th>
              <th className="text-left py-3 px-2 font-medium">Buyer</th>
              <th className="text-left py-3 px-2 font-medium">Status</th>
              <th className="py-3 px-2"></th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              [...Array(8)].map((_, index) => (
                <tr
                  key={index}
                  className="hover:bg-gray-50 transition-colors duration-200"
                >
                  <td className="py-3 px-2">
                    <div className="w-12 h-12 bg-gray-200 rounded-lg animate-pulse"></div>
                  </td>
                  <td className="py-3 px-2">
                    <div className="h-4 w-16 bg-gray-200 rounded animate-pulse"></div>
                  </td>
                  <td className="py-3 px-2">
                    <div className="h-4 w-20 bg-gray-200 rounded animate-pulse"></div>
                  </td>
                  <td className="py-3 px-2">
                    <div className="h-4 w-16 bg-gray-200 rounded animate-pulse"></div>
                  </td>
                  <td className="py-3 px-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-gray-200 rounded-full animate-pulse"></div>
                      <div className="h-4 w-32 bg-gray-200 rounded animate-pulse"></div>
                    </div>
                  </td>
                  <td className="py-3 px-2">
                    <div className="h-6 w-20 bg-gray-200 rounded-full animate-pulse"></div>
                  </td>
                  <td className="py-3 px-2 text-right">
                    <div className="h-5 w-5 bg-gray-200 rounded animate-pulse ml-auto"></div>
                  </td>
                </tr>
              ))
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan="7" className="py-8 text-center text-gray-500">
                  Tidak ada data yang melakukan transaksi
                </td>
              </tr>
            ) : (
              filtered.map((activity, index) => (
                <tr
                  key={activity.id}
                  className="hover:bg-gray-50 transition-colors duration-200"
                >
                  <td className="py-3 px-2">
                    <img
                      src={activity.productImage}
                      alt={activity.productName}
                      className="w-12 h-12 rounded-lg object-cover"
                    />
                  </td>
                  <td className="py-3 px-2">
                    <span className="font-medium text-gray-900">
                      {activity.category}
                    </span>
                  </td>
                  <td className="py-3 px-2 text-gray-600">
                    {activity.time.split(",")[0]}
                  </td>
                  <td className="py-3 px-2 text-gray-600">
                    {activity.time.split(",")[1]}
                  </td>
                  <td className="py-3 px-2">
                    <div className="flex items-center gap-3">
                      <img
                        src={activity.avatar}
                        alt={activity.buyerName}
                        className="w-10 h-10 rounded-full object-cover"
                      />
                      <span className="text-gray-900">
                        {activity.buyerName}
                      </span>
                    </div>
                  </td>
                  <td className="py-3 px-2">
                    <span
                      className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusBadge(activity.status).class
                        }`}
                    >
                      {getStatusBadge(activity.status).text}
                    </span>
                  </td>
                  <td className="py-3 px-2 text-right">
                    <div className="flex items-center justify-end gap-2">
                      {["pending", "waiting_cod"].includes(activity.status) && (
                        <button
                          type="button"
                          onClick={() => handleChatBuyer(activity.buyerId)}
                          disabled={!activity.buyerId}
                          className="inline-flex items-center rounded-lg border border-brand-red bg-white px-3 py-2 text-sm font-semibold text-brand-red shadow-sm transition-colors hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                          Chat
                        </button>
                      )}
                      {activity.status === "pending" && (
                        <button
                          type="button"
                          onClick={() => handleVerifyOrder(activity.id)}
                          className="inline-flex items-center rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-semibold text-gray-700 shadow-sm transition-colors hover:bg-gray-50"
                        >
                          Verifikasi
                        </button>
                      )}
                      {activity.status === "waiting_cod" && (
                        <button
                          type="button"
                          onClick={() => openClaimModal(activity.id)}
                          className="inline-flex items-center rounded-lg bg-brand-red px-3 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-red-700"
                        >
                          Claim COD
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {!isLoading && (
        <div className="flex flex-col sm:flex-row items-center justify-between mt-6 gap-4">
          <p className="text-sm text-gray-600">
            Total Buyer:{" "}
            <span className="font-semibold text-gray-900">{totalCount}</span>
          </p>
          <div className="flex items-center gap-1">
            <button
              className="h-8 w-8 rounded-md border border-gray-300 flex items-center justify-center"
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            {Array.from({ length: totalPages }).map((_, i) => {
              const page = i + 1;
              const active = currentPage === page;
              return (
                <button
                  key={page}
                  className={`h-8 w-8 rounded-md border flex items-center justify-center ${active
                    ? "bg-brand-red text-white border-brand-red"
                    : "border-gray-300"
                    }`}
                  onClick={() => setCurrentPage(page)}
                >
                  {page}
                </button>
              );
            })}
            <button
              className="h-8 w-8 rounded-md border border-gray-300 flex items-center justify-center"
              onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600">Show per page:</span>
            <select
              value={perPage}
              onChange={(e) => setPerPage(Number(e.target.value))}
              className="w-16 h-8 border border-gray-300 rounded-md px-2"
            >
              <option value={8}>8</option>
              <option value={16}>16</option>
              <option value={24}>24</option>
            </select>
          </div>
        </div>
      )}
      {claimModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6 relative">
            <h3 className="text-xl font-bold text-gray-900 mb-2">Claim Payment</h3>
            <p className="text-sm text-gray-600 mb-6">
              Enter the authentication code provided by the buyer to immediately claim the payment into your wallet.
            </p>

            {claimToast && (
              <div
                className={`mb-6 rounded-lg p-4 shadow-sm text-sm border font-medium ${claimToast.type === "success"
                    ? "bg-green-50 text-green-700 border-green-200"
                    : "bg-red-50 text-red-700 border-red-200"
                  }`}
              >
                {claimToast.message}
              </div>
            )}

            <form onSubmit={handleClaimSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Authentication Code
                </label>
                <input
                  type="text"
                  value={authCode}
                  onChange={(e) => setAuthCode(e.target.value.toUpperCase())}
                  placeholder="e.g. A2B9X0"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-red focus:border-brand-red uppercase tracking-widest font-mono text-center text-lg"
                  maxLength={6}
                  required
                />
              </div>

              <div className="flex gap-3 mt-8">
                <button
                  type="button"
                  onClick={() => setClaimModalOpen(false)}
                  className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg focus:outline-none hover:bg-gray-200 transition-colors font-medium"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={claimLoading || authCode.length < 6}
                  className="flex-1 px-4 py-2 bg-brand-red text-white rounded-lg hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                >
                  {claimLoading ? "Verifying..." : "Claim"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default BuyerMonitoringSection;
