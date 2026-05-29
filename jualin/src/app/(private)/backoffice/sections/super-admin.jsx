"use client";

import ProductManagement from "./management-product";
import BuyerMonitoring from "./monitoring-buyer";

export default function SuperAdminDashboard() {
  return (
    <section className="space-y-6 sm:space-y-8">
      <header className="flex flex-col md:flex-row md:items-end md:justify-between gap-2">
        <div>
          <h2 className="text-2xl sm:text-3xl font-bold text-[#1F1F1F] tracking-tight">
            Monitoring Product
          </h2>
          <p className="text-sm text-gray-500 mt-1 leading-snug">
            Monitoring produk terbaru dan aktivitas buyer secara realtime.
          </p>
        </div>
      </header>

      {/* Recently Added Products */}
      <ProductManagement />

      {/* Monitoring Buyer */}
      <BuyerMonitoring />
    </section>
  );
}
