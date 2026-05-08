"use client";

import { useState, useEffect, useMemo } from "react";
import { Search } from "lucide-react";
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
  const [userActions, setUserActions] = useState({});

  const [filterPeriod, setFilterPeriod] = useState("30days");

  // State for all raw users fetched from server
  const [allUsers, setAllUsers] = useState([]);

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

  const handleToggleStatus = (userId, currentAction) => {
    const isSuspended = currentAction === "suspended";
    const newStatus = isSuspended ? "active" : "suspended";
    setUserActions((prev) => ({ ...prev, [userId]: newStatus }));
  };

  return (
    <section className="space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-[#1F1F1F] tracking-tight">
            Managemen User
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Kelola pendaftaran dan status user seller di marketplace Anda.
          </p>
        </div>
      </header>

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
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50/80 border-b border-gray-100">
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Name
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Email
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Roles
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Date
                </th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Status
                </th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td
                    colSpan="5"
                    className="px-6 py-8 text-center text-gray-500"
                  >
                    Loading users...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td
                    colSpan="5"
                    className="px-6 py-8 text-center text-gray-500"
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
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <img
                          src={getProfilePictureUrl(
                            user.profile_picture || user.avatar
                          )}
                          alt={user.name || "User"}
                          className="w-9 h-9 rounded-full object-cover shadow-sm"
                        />
                        <span className="text-sm font-medium text-gray-900">
                          {user.name || user.username}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-600">
                        {user.email}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center px-3 py-1 rounded-full bg-gray-100 text-xs font-medium text-gray-700">
                        {user.role}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-600">
                        {user.created_at
                          ? new Date(user.created_at).toLocaleDateString()
                          : "-"}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <div className="flex items-center gap-2">
                          {userActions[user.id] === "suspended" ? (
                            <>
                              <span className="inline-flex items-center px-3 py-1 rounded-full bg-red-100 text-xs font-semibold text-red-700 min-w-[80px] justify-center">
                                Suspended
                              </span>
                              <button
                                type="button"
                                onClick={() =>
                                  handleToggleStatus(user.id, "suspended")
                                }
                                className="text-xs text-blue-600 hover:text-blue-800 font-medium underline px-2"
                              >
                                Activate
                              </button>
                            </>
                          ) : (
                            <>
                              <span className="inline-flex items-center px-3 py-1 rounded-full bg-green-100 text-xs font-semibold text-green-700 min-w-[80px] justify-center">
                                Active
                              </span>
                              <button
                                type="button"
                                onClick={() =>
                                  handleToggleStatus(user.id, "active")
                                } // "active" just means current state is active
                                className="px-3 py-1.5 rounded-full bg-gray-100 hover:bg-gray-200 text-xs font-medium text-gray-700 transition-colors border border-gray-200"
                              >
                                Suspend
                              </button>
                            </>
                          )}
                        </div>
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
    </section>
  );
}
