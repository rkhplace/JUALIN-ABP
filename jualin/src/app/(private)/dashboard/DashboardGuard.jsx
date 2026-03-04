"use client";
import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function DashboardGuard({ children }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const storedUser = typeof window !== "undefined" ? JSON.parse(localStorage.getItem("user") || "null") : null;
    const role = String(storedUser?.role || "customer").toLowerCase();
    if (role === "seller") {
      router.replace("/seller/dashboard");
      return;
    }
    setReady(true);
  }, [router]);

  if (!ready) return <div className="min-h-screen bg-white" />;
  return <>{children}</>;
}

