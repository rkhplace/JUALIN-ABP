"use client";

import { useState, useEffect, useMemo } from "react";
import { Search, X, MoreHorizontal } from "lucide-react";
import { transactionService } from "@/services/backoffice/transactionService";
import { getProfilePictureUrl, getProductImageUrl } from "@/utils/imageHelper";
import Pagination from "@/components/ui/Pagination";
import DropdownMenu from "@/components/ui/DropdownMenu";

export default function BuyerMonitoring() {
  const [allTransactions, setAllTransactions] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  const [searchQuery, setSearchQuery] = useState("");
  const [filterPeriod, setFilterPeriod] = useState("30days");

  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(8);

  const [editingBuyer, setEditingBuyer] = useState(null);
  const [showBuyerModal, setShowBuyerModal] = useState(false);

  const [deletingBuyerId, setDeletingBuyerId] = useState(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  // Fetch All Transactions (Once)
  useEffect(() => {
    const fetchTransactions = async () => {
      try {
        setIsLoading(true);
        // Fetch all (limit 1000) for client-side filtering
        const response = await transactionService.fetchAllTransactions({
          limit: 1000,
          status: "all",
          page: 1,
        });
        const data = Array.isArray(response) ? response : response.data || [];
        setAllTransactions(data);
      } catch (error) {
        console.error("Failed to fetch transactions:", error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchTransactions();
  }, []);

  // Filter Logic (useMemo)
  const filteredActivities = useMemo(() => {
    let data = allTransactions;

    // 1. Search (Buyer, Product, Category, Status)
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      data = data.filter(
        (t) =>
          t.customer?.name?.toLowerCase().includes(q) ||
          "" ||
          t.customer?.username?.toLowerCase().includes(q) ||
          "" ||
          t.items?.[0]?.product?.name?.toLowerCase().includes(q) ||
          "" ||
          t.items?.[0]?.product?.category?.toLowerCase().includes(q) ||
          "" ||
          t.status?.toLowerCase().includes(q) ||
          ""
      );
    }

    // 2. Date Filter
    const now = new Date();
    const filterDate = new Date();
    if (filterPeriod === "7days") filterDate.setDate(now.getDate() - 7);
    if (filterPeriod === "30days") filterDate.setDate(now.getDate() - 30);
    if (filterPeriod === "90days") filterDate.setDate(now.getDate() - 90);

    data = data.filter((t) => {
      if (!t.created_at) return true;
      const tDate = new Date(t.created_at);
      return tDate >= filterDate;
    });

    // Map to View Model
    return data.map((order) => ({
      id: order.id,
      productImage: getProductImageUrl(order.items?.[0]?.product?.image),
      productName: order.items?.[0]?.product?.name || "Product", // Added product name
      category: order.items?.[0]?.product?.category || "Unknown",
      code: order.id + 10000,
      time: order.created_at
        ? new Date(order.created_at).toLocaleString("id-ID")
        : "N/A",
      buyer: order.customer?.username || order.customer?.name || "Unknown",
      buyerImage: getProfilePictureUrl(order.customer?.profile_picture),
      status: order.status,
      buyerId: order.customer_id,
      originalData: order,
    }));
  }, [allTransactions, searchQuery, filterPeriod]);

  // Pagination Logic
  const totalItems = filteredActivities.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / itemsPerPage));
  const startIndex = (currentPage - 1) * itemsPerPage;
  const currentActivities = filteredActivities.slice(
    startIndex,
    startIndex + itemsPerPage
  );

  // Reset page on filter change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, filterPeriod, itemsPerPage]);

  const handleDeleteBuyer = (id) => {
    setDeletingBuyerId(id);
    setShowDeleteModal(true);
  };

  const confirmDeleteBuyer = () => {
    if (deletingBuyerId) {
      // In real app, call API. For now, filter local state (but ideally refetch or optimistic update)
      // Since we derived from allTransactions, we update allTransactions
      setAllTransactions((prev) => prev.filter((t) => t.id !== deletingBuyerId));
      setDeletingBuyerId(null);
      setShowDeleteModal(false);
    }
  };

  const handleEditBuyer = (buyer) => {
    setEditingBuyer(buyer);
    setShowBuyerModal(true);
  };

  const handleSaveEdit = (updatedBuyer) => {
    // Update local state
    setAllTransactions((prev) =>
      prev.map((t) => {
        if (t.id === updatedBuyer.id) {
          return { ...t, status: updatedBuyer.status }; // Minimal update for demo
        }
        return t;
      })
    );
    setEditingBuyer(null);
    setShowBuyerModal(false);
    // TODO: Implement API update
  };

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
      cancelled: {
        text: "Cancelled",
        class: "bg-gray-100 text-gray-700 border border-gray-200",
      },
    };
    return badges[status?.toLowerCase()] || badges.completed;
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-[#1F1F1F]">
          Monitoring Buyer
        </h3>
      </div>

      {/* Search Bar */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1 max-w-md">
          <input
            type="text"
            placeholder="Cari buyer atau kategori..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-4 pr-11 py-2.5 rounded-full border border-gray-200 bg-white text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#E53935]/80 focus:border-transparent shadow-sm"
          />
          <span className="absolute right-3 top-1/2 -translate-y-1/2 inline-flex items-center justify-center w-7 h-7 rounded-full bg-[#E53935] text-white shadow-sm">
            <Search size={15} />
          </span>
        </div>
        <div>
          <select
            value={filterPeriod}
            onChange={(e) => setFilterPeriod(e.target.value)}
            className="w-full sm:w-40 rounded-lg border border-gray-300 px-3 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#E53935]/80"
          >
            <option value="7days">Last 7 Days</option>
            <option value="30days">Last 30 Days</option>
            <option value="90days">Last 90 Days</option>
          </select>
        </div>
      </div>

      {/* Buyers Table */}
      <div className="bg-white border border-gray-100 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50/80 border-b border-gray-100">
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Item
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Category
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Date
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Time
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Buyer
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Status
                </th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Action
                </th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td
                    colSpan="7"
                    className="px-6 py-8 text-center text-gray-500"
                  >
                    Loading activities...
                  </td>
                </tr>
              ) : currentActivities.length === 0 ? (
                <tr>
                  <td
                    colSpan="7"
                    className="px-6 py-8 text-center text-gray-500"
                  >
                    No buyer activities found.
                  </td>
                </tr>
              ) : (
                currentActivities.map((buyer) => (
                  <tr
                    key={buyer.id}
                    className="border-b border-gray-100 last:border-b-0 hover:bg-gray-50/60 transition-colors"
                  >
                    <td className="px-6 py-4">
                      <img
                        src={buyer.productImage}
                        alt="product"
                        className="w-12 h-12 rounded-lg object-cover shadow-sm bg-gray-50"
                        onError={(e) => {
                          e.target.src = "/placeholder.svg";
                        }}
                      />
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm font-medium text-gray-900">
                        {buyer.category}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-600">
                        {buyer.time.split(", ")[0]}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-600">
                        {buyer.time.split(", ")[1] || buyer.time}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <img
                          src={buyer.buyerImage}
                          alt={buyer.buyer}
                          className="w-9 h-9 rounded-full object-cover shadow-sm bg-gray-100"
                          onError={(e) => {
                            e.target.src = "/ProfilePhoto.png";
                          }}
                        />
                        <span className="text-sm text-gray-700 font-medium">
                          {buyer.buyer}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${
                          getStatusBadge(buyer.status).class
                        }`}
                      >
                        {getStatusBadge(buyer.status).text}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <DropdownMenu
                        trigger={
                          <MoreHorizontal className="h-5 w-5 text-gray-400 hover:text-gray-600 cursor-pointer" />
                        }
                        items={[
                          {
                            label: "Edit Order",
                            onClick: () => handleEditBuyer(buyer),
                          },
                          {
                            label: "Delete Order",
                            onClick: () => handleDeleteBuyer(buyer.id),
                            variant: "danger",
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
      </div>

      {/* Pagination Footer */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mt-6">
        <div className="text-sm text-gray-600">
          Total:{" "}
          <span className="font-semibold text-gray-900">{totalItems}</span>
        </div>

        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          onPageChange={setCurrentPage}
        />

        <div className="flex items-center justify-end gap-2 text-sm text-gray-600">
          <span>Show per page:</span>
          <select
            value={itemsPerPage}
            onChange={(e) => {
              setItemsPerPage(Number.parseInt(e.target.value));
              setCurrentPage(1);
            }}
            className="px-3 py-1.5 border border-gray-200 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-[#E53935]/70 bg-white shadow-sm"
          >
            <option value={5}>5</option>
            <option value={8}>8</option>
            <option value={10}>10</option>
            <option value={15}>15</option>
          </select>
        </div>
      </div>

      {/* Edit Buyer (Order) Modal */}
      {showBuyerModal && editingBuyer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">
                Edit Order
              </h3>
              <button
                type="button"
                onClick={() => setShowBuyerModal(false)}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X size={20} />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Buyer Name
                </label>
                <input
                  type="text"
                  disabled
                  defaultValue={editingBuyer.buyer}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none bg-gray-50 text-gray-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Status
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#E53935]/80"
                  defaultValue={editingBuyer.status}
                  onChange={(e) => {
                    setEditingBuyer({
                      ...editingBuyer,
                      status: e.target.value,
                    });
                  }}
                >
                  <option value="pending">Pending</option>
                  <option value="verified">Verified</option>
                  <option value="processing">Processing</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
              <button
                type="button"
                onClick={() => handleSaveEdit(editingBuyer)}
                className="w-full bg-[#E53935] text-white py-2.5 rounded-lg font-medium hover:bg-[#D32F2F] transition-colors shadow-sm"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Buyer (Order) Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">
                Delete Order
              </h3>
              <button
                type="button"
                onClick={() => {
                  setShowDeleteModal(false);
                  setDeletingBuyerId(null);
                }}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X size={20} />
              </button>
            </div>
            <div className="mb-6">
              <p className="text-sm text-gray-600">
                Are you sure you want to delete this order record? This action cannot be undone.
              </p>
            </div>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => {
                  setShowDeleteModal(false);
                  setDeletingBuyerId(null);
                }}
                className="flex-1 bg-white border border-gray-300 text-gray-700 py-2.5 rounded-lg font-medium hover:bg-gray-50 transition-colors shadow-sm"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={confirmDeleteBuyer}
                className="flex-1 bg-[#E53935] text-white py-2.5 rounded-lg font-medium hover:bg-[#D32F2F] transition-colors shadow-sm"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
