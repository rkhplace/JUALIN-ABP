"use client";
import React from "react";
import DashboardBackground from "@/components/ui/DashboardBackground.jsx";

export default function ProductLayout({ children }) {
  return (
    <main className="jualin-dashboard-bg min-h-screen">
      <DashboardBackground />
      <div className="jualin-content-layer w-full">{children}</div>
    </main>
  );
}
