"use client";

import React, { useMemo, useState, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import Logo from "@/components/ui/Logo";
import Input from "@/components/ui/Input";
import Button from "@/components/ui/Button";
import Toast from "@/components/ui/Toast";
import { passwordService } from "@/services";

function ResetPasswordContent() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const tokenFromLink = useMemo(
    () => searchParams.get("token") || "",
    [searchParams]
  );
  const emailFromLink = useMemo(
    () => searchParams.get("email") || "",
    [searchParams]
  );

  const [email, setEmail] = useState(emailFromLink);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);

  const getStrength = () => {
    if (newPassword.length === 0) return 0;
    if (newPassword.length < 8) return 1;
    let score = 1;
    if (/[A-Z]/.test(newPassword)) score++;
    if (/[0-9]/.test(newPassword)) score++;
    if (/[^A-Za-z0-9]/.test(newPassword)) score++;
    return Math.min(score, 4);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setToast(null);

    if (!tokenFromLink) {
      setToast({
        message: "Token reset tidak ditemukan dari link email.",
        type: "error",
      });
      return;
    }
    if (!email) {
      setToast({ message: "Email wajib diisi.", type: "error" });
      return;
    }
    if (newPassword.length < 8) {
      setToast({ message: "Password minimal 8 karakter.", type: "error" });
      return;
    }
    if (newPassword !== confirmPassword) {
      setToast({ message: "Konfirmasi password tidak cocok.", type: "error" });
      return;
    }

    setLoading(true);
    try {
      await passwordService.resetPassword({
        token: tokenFromLink,
        email,
        password: newPassword,
        password_confirmation: confirmPassword,
      });
      setToast({
        message: "Password berhasil direset. Silakan login kembali.",
        type: "success",
      });
      setNewPassword("");
      setConfirmPassword("");
      router.replace("/auth/login");
    } catch (err) {
      setToast({
        message: err.message || "Gagal mereset password.",
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
              Buat Password Baru
            </h1>
            <p className="text-gray-600 text-sm md:text-base">
              Minimal 8 karakter. Gunakan kombinasi huruf, angka, dan simbol.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {!emailFromLink && (
              <Input
                label="Email"
                type="email"
                name="email"
                placeholder="Enter your email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            )}

            <Input
              label="New Password"
              type="password"
              name="newPassword"
              placeholder="Enter your new password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              required
            />

            <div className="flex gap-2 mb-2">
              {[1, 2, 3, 4].map((level) => (
                <div
                  key={level}
                  className={`h-2 flex-1 rounded-full ${
                    getStrength() >= level
                      ? level <= 2
                        ? "bg-[#E83030]"
                        : level === 3
                        ? "bg-yellow-400"
                        : "bg-green-500"
                      : "bg-gray-200"
                  }`}
                />
              ))}
            </div>

            <Input
              label="Confirm Password"
              type="password"
              name="confirmPassword"
              placeholder="Confirm your password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />

            <Button type="submit" variant="primary" disabled={loading}>
              {loading ? "Processing..." : "Set new password"}
            </Button>
          </form>

          <p className="mt-6 text-center text-sm text-gray-600">
            Sudah berhasil reset?{" "}
            <Link
              href="/auth/login"
              className="text-[#E83030] hover:text-red-600 font-medium"
            >
              Kembali ke login
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

export default function ResetPasswordPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-gray-500">Loading…</div>
        </div>
      }
    >
      <ResetPasswordContent />
    </Suspense>
  );
}
