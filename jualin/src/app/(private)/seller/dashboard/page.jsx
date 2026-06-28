"use client";

import { useEffect, useState } from "react";
import IncomeSection from "./sections/income.jsx";
import RecentlyAddedSection from "./sections/recently-added.jsx";
import BuyerMonitoringSection from "./sections/buyer-monitoring.jsx";
import { useSellerDashboard } from "@/hooks/seller/useSellerDashboard";
import SellerMissionPopup from "@/components/seller/SellerMissionPopup";
import SellerMissionBanner from "@/components/seller/SellerMissionBanner";

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
      {/* Seller verification mission / congrats popup */}
      <SellerMissionPopup />

      <div className="max-w-6xl mx-auto px-4 py-5 pb-24 space-y-6 sm:py-6 sm:pb-10 sm:space-y-8">
        {/* Permanent mission progress banner (hidden when verified) */}
        <SellerMissionBanner />

        <IncomeSection sellerId={sellerId || 1} />
        <RecentlyAddedSection products={products} isLoading={isLoading} />
        <BuyerMonitoringSection
          orders={orders}
          isLoading={isLoading}
          sellerId={sellerId}
        />
      </div>
    </main>
  );
}
