"use client";
import React, { useEffect, useContext, useState } from "react";
import { useRouter } from "next/navigation";
import { AuthContext } from "@/context/AuthProvider.jsx";

export default function SellerGuard({ children }) {
  const router = useRouter();
  const { user } = useContext(AuthContext);
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
    const storedUser = typeof window !== "undefined" ? JSON.parse(localStorage.getItem("user") || "null") : null;

    const currentUser = user || storedUser;

    if (!token || !currentUser) {
      router.replace("/login");
      return;
    }

    const role = String(currentUser.role || "").toLowerCase();
    if (role !== "seller") {
      router.replace("/dashboard");
      return;
    }

    setAuthorized(true);
  }, [user, router]);

  if (!authorized) {
    return <div className="min-h-screen bg-white" />;
  }

  return <>{children}</>;
}
