"use client";
import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function DashboardGuard({ children }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const storedUser = typeof window !== "undefined" ? JSON.parse(localStorage.getItem("user") || "null") : null;
    const accountRole = String(storedUser?.role || "customer").toLowerCase();
    const activeRole = String(
      localStorage.getItem("active_role") || accountRole
    ).toLowerCase();
    if (activeRole === "seller") {
      router.replace("/seller/dashboard");
      return;
    }
    setReady(true);
  }, [router]);

  if (!ready) return <div className="min-h-screen bg-white" />;
  return <>{children}</>;
}
