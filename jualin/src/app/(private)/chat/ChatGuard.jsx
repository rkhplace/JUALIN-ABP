"use client";
import React, { useEffect, useState, useContext } from "react";
import { useRouter } from "next/navigation";
import { AuthContext } from "@/context/AuthProvider";

export default function ChatGuard({ children }) {
  const router = useRouter();
  const { user } = useContext(AuthContext);
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
    const storedUser = typeof window !== "undefined" ? JSON.parse(localStorage.getItem("user") || "null") : null;
    const currentUser = user || storedUser;

    if (!token || !currentUser) {
      router.replace("/auth/login");
      return;
    }

    setAuthorized(true);
  }, [user, router]);

  if (!authorized) {
    return <div className="min-h-screen bg-white" />;
  }

  return <>{children}</>;
}
