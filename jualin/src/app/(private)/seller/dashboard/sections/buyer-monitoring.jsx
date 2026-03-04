"use client";
import React, { useState, useMemo, useContext } from "react";
import { useRouter } from "next/navigation";
import DropdownMenu from "@/components/ui/DropdownMenu";
import {
  Search,
  MoreHorizontal,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { ChatContext } from "@/context/ChatProvider";
import { getProfilePictureUrl, getProductImageUrl } from "@/utils/imageHelper";

const BuyerMonitoringSection = ({ orders = [], isLoading = false }) => {
  const router = useRouter();
  const { openChatWithUser } = useContext(ChatContext);
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [perPage, setPerPage] = useState(8);

  const buyerActivities =
    orders.length > 0
      ? orders.map((order) => ({
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

  const handleViewDetails = (orderId) =>
    router.push(`/seller/orders/${orderId}`);

  const getStatusBadge = (status) => {
    const badges = {
      pending: {
        text: "Pending",
        class: "bg-red-100 text-red-700 border border-red-200",
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
        text: "Completed",
        class: "bg-gray-100 text-gray-700 border border-gray-200",
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
                      className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                        getStatusBadge(activity.status).class
                      }`}
                    >
                      {getStatusBadge(activity.status).text}
                    </span>
                  </td>
                  <td className="py-3 px-2 text-right">
                    <DropdownMenu
                      trigger={
                        <MoreHorizontal className="h-5 w-5 text-gray-400" />
                      }
                      items={[
                        ...(activity.status === "pending"
                          ? [
                              {
                                label: "Verifikasi Order",
                                onClick: () => handleVerifyOrder(activity.id),
                              },
                            ]
                          : []),
                        {
                          label: "Chat Pembeli",
                          onClick: () => handleChatBuyer(activity.buyerId),
                        },
                        {
                          label: "Lihat Detail",
                          onClick: () => handleViewDetails(activity.id),
                        },
                      ]}
                    />
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
                  className={`h-8 w-8 rounded-md border flex items-center justify-center ${
                    active
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
    </div>
  );
};

export default BuyerMonitoringSection;
