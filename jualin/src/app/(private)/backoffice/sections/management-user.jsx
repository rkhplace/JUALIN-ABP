"use client";

import { useState, useEffect, useMemo } from "react";
import { Search } from "lucide-react";
import { toast } from "sonner";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import { userService } from "@/services/user/userService";
import { getProfilePictureUrl } from "@/utils/imageHelper";
import Pagination from "@/components/ui/Pagination";

export default function UserManagement() {
  // const [users, setUsers] = useState([]); // Now derived
  const [searchQuery, setSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(8);
  // const [totalPages, setTotalPages] = useState(1); // Now derived
  // const [totalItems, setTotalItems] = useState(0); // Now derived
  const [isLoading, setIsLoading] = useState(false);

  const [filterPeriod, setFilterPeriod] = useState("30days");

  // State for all raw users fetched from server
  const [allUsers, setAllUsers] = useState([]);

  const [confirmModal, setConfirmModal] = useState({
    isOpen: false,
    action: null,
    user: null,
  });
  const [banDurations, setBanDurations] = useState({});
  const [processingUserId, setProcessingUserId] = useState(null);

  // Fetch All Users (Once, or on mount)
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        setIsLoading(true);
        // Fetch a large number to get "all" users for client-side manipulation
        const response = await userService.fetchAll(1, 1000, "");

        const fetchedUsers = response.data || [];
        setAllUsers(fetchedUsers);
      } catch (error) {
        console.error("Failed to fetch users:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchUsers();
  }, []); // Empty dependency array to fetch once on mount

  // Filter and Paginate Logic (useMemo)
  // Reference: buyer-monitoring.jsx
  const filteredData = useMemo(() => {
    let data = allUsers;

    // 1. Search Filter
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      data = data.filter(
        (user) =>
          user.name?.toLowerCase().includes(q) ||
          "" ||
          user.email?.toLowerCase().includes(q) ||
          "" ||
          user.role?.toLowerCase().includes(q) ||
          ""
      );
    }

    // 2. Date Filter
    const now = new Date();
    const filterDate = new Date();
    if (filterPeriod === "7days") filterDate.setDate(now.getDate() - 7);
    if (filterPeriod === "30days") filterDate.setDate(now.getDate() - 30);
    if (filterPeriod === "90days") filterDate.setDate(now.getDate() - 90);

    data = data.filter((user) => {
      if (!user.created_at) return true;
      const userDate = new Date(user.created_at);
      return userDate >= filterDate;
    });

    return data;
  }, [allUsers, searchQuery, filterPeriod]);

  // Derived Pagination
  const totalItems = filteredData.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / itemsPerPage));
  const startIndex = (currentPage - 1) * itemsPerPage;
  const users = filteredData.slice(startIndex, startIndex + itemsPerPage);

  // Reset page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, filterPeriod, itemsPerPage]);

  const closeConfirmModal = () => {
    setConfirmModal((prev) => ({ ...prev, isOpen: false }));
  };

  const openConfirmModal = (user, action) => {
    setConfirmModal({
      isOpen: true,
      action,
      user,
    });
  };

  const formatBannedUntil = (timestamp) => {
    if (!timestamp) return null;
    return `${new Date(timestamp).toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' })} ${new Date(timestamp).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}`;
  };

  const executeBanUser = async (user) => {
    const duration = banDurations[user.id] || "7";
    if (!user || !duration) return;

    setProcessingUserId(user.id);
    const promise = userService.banUser(user.id, duration);

    try {
      const response = await toast.promise(promise, {
        loading: `Memproses ban ${user.username}...`,
        success: (result) => {
          const bannedUntil = result?.banned_until || result?.data?.banned_until || result?.data?.user?.banned_until || null;
          return bannedUntil
            ? `User ${user.username} berhasil diban sampai ${formatBannedUntil(bannedUntil)}`
            : `User ${user.username} berhasil diban`;
        },
        error: (err) => err.message || `Gagal mem-ban user ${user.username}`,
      });

      const updatedUser = response?.data?.user || response?.data || response;
      const bannedUntil = response?.banned_until || response?.data?.banned_until || response?.data?.user?.banned_until || null;

      setAllUsers((prev) =>
        prev.map((u) =>
          u.id === user.id
            ? { ...u, is_banned: true, banned_until: bannedUntil || updatedUser?.banned_until }
            : u
        )
      );
    } catch (error) {
      console.error("Failed to ban user:", error);
    } finally {
      setProcessingUserId(null);
    }
  };

  const executeUnbanUser = async (user) => {
    if (!user) return;

    setProcessingUserId(user.id);
    const promise = userService.unbanUser(user.id);

    try {
      await toast.promise(promise, {
        loading: `Memproses unban ${user.username}...`,
        success: () => `User ${user.username} berhasil di-unban`,
        error: (err) => err.message || `Gagal unban user ${user.username}`,
      });

      setAllUsers((prev) =>
        prev.map((u) =>
          u.id === user.id
            ? { ...u, is_banned: false, banned_until: null }
            : u
        )
      );
    } catch (error) {
      console.error("Failed to unban user:", error);
    } finally {
      setProcessingUserId(null);
    }
  };

  const handleConfirmAction = async () => {
    if (!confirmModal.user || !confirmModal.action) return;

    const user = confirmModal.user;
    const action = confirmModal.action;
    closeConfirmModal();

    if (action === "ban") {
      await executeBanUser(user);
    } else if (action === "unban") {
      await executeUnbanUser(user);
    }
  };

  return (
    <section className="space-y-5 sm:space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-[#1F1F1F] tracking-tight">
            Managemen User
          </h1>
          <p className="text-sm text-gray-500 mt-1 leading-snug">
            Kelola pendaftaran dan status user seller di marketplace Anda.
          </p>
        </div>
      </header>

      {/* Search & Filter */}
      <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 mb-5 sm:mb-6">
        <div className="relative flex-1">
          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari Pembeli..."
            className="w-full px-4 py-2 pr-10 border rounded-full border-gray-300 focus:ring-2 focus:ring-brand-red focus:border-brand-red outline-none text-sm sm:text-base"
            disabled={isLoading}
          />
          <button className="absolute right-1 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-brand-red text-white flex items-center justify-center">
            <Search className="h-4 w-4" />
          </button>
        </div>
        <div>
          <select
            value={filterPeriod}
            onChange={(e) => setFilterPeriod(e.target.value)}
            className="w-full sm:w-40 rounded-lg border border-gray-300 px-3 py-2 text-sm"
            disabled={isLoading}
          >
            <option value="7days">Last 7 Days</option>
            <option value="30days">Last 30 Days</option>
            <option value="90days">Last 90 Days</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white border border-gray-100 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px]">
            <thead>
              <tr className="bg-gray-50/80 border-b border-gray-100">
                <th className="px-4 py-3 sm:px-6 sm:py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Name
                </th>
                <th className="px-4 py-3 sm:px-6 sm:py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Email
                </th>
                <th className="px-4 py-3 sm:px-6 sm:py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Roles
                </th>
                <th className="px-4 py-3 sm:px-6 sm:py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Date
                </th>
                <th className="px-4 py-3 sm:px-6 sm:py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Status
                </th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td
                    colSpan="5"
                    className="px-4 py-7 sm:px-6 sm:py-8 text-center text-gray-500"
                  >
                    Loading users...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td
                    colSpan="5"
                    className="px-4 py-7 sm:px-6 sm:py-8 text-center text-gray-500"
                  >
                    No users found.
                  </td>
                </tr>
              ) : (
                users.map((user) => (
                  <tr
                    key={user.id}
                    className="border-b border-gray-100 last:border-b-0 hover:bg-gray-50/60 transition-colors"
                  >
                    <td className="px-4 py-3 sm:px-6 sm:py-4">
                      <div className="flex items-center gap-3">
                        <img
                          src={getProfilePictureUrl(
                            user.profile_picture || user.avatar
                          )}
                          alt={user.name || "User"}
                          className="w-8 h-8 sm:w-9 sm:h-9 rounded-full object-cover shadow-sm"
                        />
                        <span className="text-sm font-medium text-gray-900 whitespace-nowrap">
                          {user.name || user.username}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 sm:px-6 sm:py-4">
                      <span className="text-sm text-gray-600">
                        {user.email}
                      </span>
                    </td>
                    <td className="px-4 py-3 sm:px-6 sm:py-4">
                      <span className="inline-flex items-center px-3 py-1 rounded-full bg-gray-100 text-xs font-medium text-gray-700">
                        {user.role}
                      </span>
                    </td>
                    <td className="px-4 py-3 sm:px-6 sm:py-4">
                      <span className="text-sm text-gray-600">
                        {user.created_at
                          ? new Date(user.created_at).toLocaleDateString()
                          : "-"}
                      </span>
                    </td>
                    <td className="px-4 py-3 sm:px-6 sm:py-4">
                      <div className="flex flex-col items-start gap-2">
                        <div className="flex items-center gap-2">
                          {(["seller", "customer"].includes(user.role)) && (
                            user.is_banned ? (
                              <button
                                type="button"
                                onClick={() => openConfirmModal(user, "unban")}
                                disabled={processingUserId === user.id}
                                className="inline-flex h-9 items-center gap-1.5 rounded-lg bg-emerald-600 px-3 text-xs font-semibold text-white transition-colors hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-60"
                              >
                                {processingUserId === user.id ? "Memproses..." : "Unban"}
                              </button>
                            ) : (
                              <>
                                <select
                                  value={banDurations[user.id] || "7"}
                                  onChange={(e) => setBanDurations((prev) => ({ ...prev, [user.id]: e.target.value }))}
                                  className="h-9 rounded-lg border border-gray-200 bg-white px-2 text-xs font-medium text-gray-700 focus:border-[#E83030] focus:outline-none"
                                  disabled={processingUserId === user.id}
                                >
                                  <option value="1">1 hari</option>
                                  <option value="7">7 hari</option>
                                  <option value="30">30 hari</option>
                                </select>
                                <button
                                  type="button"
                                  onClick={() => openConfirmModal(user, "ban")}
                                  disabled={processingUserId === user.id}
                                  className="inline-flex h-9 items-center gap-1.5 rounded-lg bg-red-600 px-3 text-xs font-semibold text-white transition-colors hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60"
                                >
                                  {processingUserId === user.id ? "Memproses..." : "Ban"}
                                </button>
                              </>
                            )
                          )}

                          {!(["seller", "customer"].includes(user.role)) && (
                            user.is_banned ? (
                              <span className="inline-flex items-center px-3 py-1 rounded-full bg-red-100 text-xs font-semibold text-red-700">
                                Banned
                              </span>
                            ) : (
                              <span className="text-sm text-gray-500">-</span>
                            )
                          )}
                        </div>

                        {user.banned_until && (
                          <p className="mt-1 text-xs text-red-600">
                            Dibanned sampai {`${new Date(user.banned_until).toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' })} ${new Date(user.banned_until).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}`}
                          </p>
                        )}
                      </div>
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
          Total User:{" "}
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

      <ConfirmationModal
        isOpen={confirmModal.isOpen}
        onClose={closeConfirmModal}
        onConfirm={handleConfirmAction}
        title={
          confirmModal.action === "ban"
            ? `Ban user ${confirmModal.user?.username}`
            : `Unban user ${confirmModal.user?.username}`
        }
        message={
          confirmModal.action === "ban"
            ? `Apakah Anda yakin ingin memban user ${confirmModal.user?.username} selama ${banDurations[confirmModal.user?.id] || "7"} hari?`
            : `Apakah Anda yakin ingin meng-unban user ${confirmModal.user?.username}?`
        }
        confirmText={confirmModal.action === "unban" ? "Unban" : "Ban"}
        isDanger={confirmModal.action === "ban"}
      />
    </section>
  );
}
