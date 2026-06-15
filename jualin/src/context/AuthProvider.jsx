"use client";
import React, { createContext, useState, useEffect, useContext } from "react";
import { doc, setDoc } from "firebase/firestore";
import { signInWithCustomToken, signOut } from "firebase/auth";
import { db, auth } from "@/lib/firebase";
import Cookies from "js-cookie";
import { authService } from "@/services/auth/authService";

export const AuthContext = createContext();

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const updateUser = (updater) => {
    setUser((currentUser) => {
      const nextUser =
        typeof updater === "function"
          ? updater(currentUser)
          : currentUser
            ? { ...currentUser, ...updater }
            : updater;

      if (typeof window !== "undefined") {
        if (nextUser) {
          localStorage.setItem("user", JSON.stringify(nextUser));
        } else {
          localStorage.removeItem("user");
        }
      }

      return nextUser;
    });
  };

  const syncUserToFirestore = async (userData) => {
    try {
      const userRef = doc(db, "users", userData.id.toString());
      await setDoc(
        userRef,
        {
          id: userData.id.toString(),
          name: userData.name || userData.username || userData.email,
          email: userData.email,
          avatar: userData.avatar || userData.profile_picture || null,
          role: userData.role || "buyer",
          updatedAt: new Date(),
        },
        { merge: true }
      );
    } catch (error) {
      console.error("❌ Error syncing user to Firestore:", error);
    }
  };

  const refetchUser = async () => {
    const token =
      typeof window !== "undefined" ? localStorage.getItem("token") : null;
    setLoading(true);
    if (!token) {
      setUser(null);
      setLoading(false);
      return;
    }
    try {
      const me = await authService.me();
      setUser(me);
      localStorage.setItem("user", JSON.stringify(me));

      // Coba sign in ke Firebase:
      // 1. Gunakan firebase_token dari response /me (jika ada)
      // 2. Fallback ke token yang disimpan saat login
      const fbToken =
        me.firebase_token ||
        (typeof window !== "undefined"
          ? localStorage.getItem("firebase_token")
          : null);

      if (fbToken) {
        try {
          await signInWithCustomToken(auth, fbToken);
          console.log("🔥 [Refetch] Firebase Auth Success");
        } catch (fbError) {
          console.warn("⚠️ [Refetch] Firebase Auth Failed:", fbError.code);
          // Token mungkin expired — hapus agar tidak dipakai lagi
          localStorage.removeItem("firebase_token");
        }
      } else {
        console.warn("⚠️ No firebase_token available — Firestore realtime disabled");
      }

      syncUserToFirestore(me);
    } catch (err) {
      console.error("Error fetching user:", err);
      setUser(null);
      localStorage.removeItem("user");
      localStorage.removeItem("token");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refetchUser();
  }, []);

  const login = async (userData, token) => {
    localStorage.removeItem("verified_popup_shown");
    localStorage.setItem("token", token);
    localStorage.setItem("user", JSON.stringify(userData));
    setUser(userData);
    Cookies.set("role", String(userData?.role || "customer").toLowerCase(), {
      sameSite: "lax",
    });
    Cookies.set("token", token, { sameSite: "lax" });

    // Login to Firebase if token is provided
    if (userData.firebase_token) {
      // Simpan firebase_token terpisah agar bisa dipakai saat page reload
      // (endpoint /me tidak selalu return firebase_token)
      localStorage.setItem("firebase_token", userData.firebase_token);
      try {
        await signInWithCustomToken(auth, userData.firebase_token);
        console.log("🔥 Firebase Custom Token Login Success");
      } catch (error) {
        console.error("❌ Firebase Custom Token Login Failed:", error);
      }
    }
  };

  const logout = async () => {
    try {
      await authService.logout();
    } catch (error) {
      console.error("Error logging out:", error);
    } finally {
      localStorage.removeItem("token");
      localStorage.removeItem("refresh_token");
      localStorage.removeItem("user");
      localStorage.removeItem("firebase_token");
      localStorage.removeItem("verified_popup_shown");
      setUser(null);
      Cookies.remove("role");
      Cookies.remove("token");
      Cookies.remove("accessToken");
      Cookies.remove("refreshToken");
    }
  };

  return (
    <AuthContext.Provider
      value={{ user, setUser, updateUser, login, logout, loading, refetchUser }}
    >
      {children}
    </AuthContext.Provider>
  );
}
