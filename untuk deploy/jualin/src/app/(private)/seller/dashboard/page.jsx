"use client";

import { useEffect, useState } from "react";
import IncomeSection from "./sections/income.jsx";
import RecentlyAddedSection from "./sections/recently-added.jsx";
import BuyerMonitoringSection from "./sections/buyer-monitoring.jsx";
import { useSellerDashboard } from "@/hooks/seller/useSellerDashboard";

export default function SellerDashboardPage() {
  const [sellerId, setSellerId] = useState(null);

  useEffect(() => {
    const storedUser =
      typeof window !== "undefined"
        ? JSON.parse(localStorage.getItem("user") || "null")
        : null;

    const id = storedUser?.id || 1;
    setSellerId(id);
  }, []);

  const { products, orders, isLoading } = useSellerDashboard(sellerId);

  return (
    <main className="bg-white min-h-screen">
      <div className="max-w-6xl mx-auto px-4 py-6 space-y-8">
        <IncomeSection sellerId={sellerId || 1} />
        <RecentlyAddedSection products={products} isLoading={isLoading} />
        <BuyerMonitoringSection orders={orders} isLoading={isLoading} />
      </div>
    </main>
  );
}
