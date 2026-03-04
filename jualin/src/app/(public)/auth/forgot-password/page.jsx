"use client";

import React, { useState } from "react";
import Link from "next/link";
import Logo from "@/components/ui/Logo";
import Input from "@/components/ui/Input";
import Button from "@/components/ui/Button";
import Toast from "@/components/ui/Toast";
import { passwordService } from "@/services";

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setToast(null);
    setLoading(true);
    try {
      await passwordService.sendResetLink(email);
      setToast({
        message: "Link reset password telah dikirim. Silakan cek email Anda.",
        type: "success",
      });
      setEmail("");
    } catch (err) {
      setToast({
        message: err.message || "Gagal mengirim link reset password.",
        type: "error",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex items-center justify-center relative overflow-hidden">
      <div className="absolute top-0 -left-48 w-96 h-96 bg-[#E83030] rounded-full mix-blend-multiply filter blur-3xl opacity-20"></div>
      <div className="absolute bottom-0 -right-48 w-96 h-96 bg-[#E83030] rounded-full mix-blend-multiply filter blur-3xl opacity-20"></div>

      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="relative z-10 w-full max-w-md mx-4">
        <div className="bg-white rounded-2xl shadow-2xl p-8 md:p-10">
          <Logo size="xl" className="mb-6" />

          <div className="mb-6">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-900 mb-2">
              Lupa Password
            </h1>
            <p className="text-gray-600 text-sm md:text-base">
              Masukkan email Anda untuk menerima tautan reset password.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              label="Email"
              type="email"
              name="email"
              placeholder="Enter your mail address"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />

            <Button type="submit" variant="primary" disabled={loading}>
              {loading ? "Sending..." : "Send Email Verification Link"}
            </Button>
          </form>

          <p className="mt-6 text-center text-sm text-gray-600">
            Ingat password Anda?{" "}
            <Link
              href="/auth/login"
              className="text-[#E83030] hover:text-red-600 font-medium"
            >
              Kembali ke halaman login
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
