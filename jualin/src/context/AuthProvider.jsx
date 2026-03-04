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

      // Sync to Firebase Auth
      if (me.firebase_token) {
        try {
          await signInWithCustomToken(auth, me.firebase_token);
          console.log("🔥 [Refetch] Firebase Custom Token Login Success");
        } catch (fbError) {
          console.error("❌ [Refetch] Firebase Login Failed:", fbError);
        }
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
    localStorage.setItem("token", token);
    localStorage.setItem("user", JSON.stringify(userData));
    setUser(userData);
    Cookies.set("role", String(userData?.role || "customer").toLowerCase(), {
      sameSite: "lax",
    });
    Cookies.set("token", token, { sameSite: "lax" });

    // Login to Firebase if token is provided
    if (userData.firebase_token) {
      try {
        await signInWithCustomToken(auth, userData.firebase_token);
        console.log("🔥 Firebase Custom Token Login Success");
      } catch (error) {
        console.error("❌ Firebase Custom Token Login Failed:", error);
      }
    }
  };

  const logout = async () => {
    const accessToken =
      typeof window !== "undefined" ? localStorage.getItem("token") : null;
    try {
      await authService.logout();
    } catch (error) {
      console.error("Error logging out:", error);
    } finally {
      localStorage.removeItem("token");
      localStorage.removeItem("refresh_token");
      localStorage.removeItem("user");
      setUser(null);
      Cookies.remove("role");
      Cookies.remove("token");
      Cookies.remove("accessToken");
      Cookies.remove("refreshToken");
    }
  };

  return (
    <AuthContext.Provider
      value={{ user, setUser, login, logout, loading, refetchUser }}
    >
      {children}
    </AuthContext.Provider>
  );
}
