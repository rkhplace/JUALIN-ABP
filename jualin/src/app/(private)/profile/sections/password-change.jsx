"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import Button from "@/components/ui/Button";
import Toast from "@/components/ui/Toast";
import { passwordService } from "@/services";
import { useAuth } from "@/context/AuthProvider";

export function PasswordChangeSection() {
  const router = useRouter();
  const { user, logout } = useAuth();
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);

  const handleDirectReset = async () => {
    if (!user?.email) {
      setToast({ message: "Email profil tidak ditemukan.", type: "error" });
      return;
    }

    setLoading(true);
    setToast(null);

    try {
      await passwordService.sendResetLink(user.email);
      setToast({
        message: "Link reset telah dikirim ke email Anda. Anda akan keluar...",
        type: "success",
      });
      await logout();
      router.replace("/auth/login");
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
    <div className="bg-white rounded-xl p-8 shadow-md hover:shadow-lg transition-all duration-200">
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      <div className="flex items-center justify-between mb-6">
        <h2 className="text-lg font-semibold text-[#1F1F1F]">
          Ubah Kata Sandi
        </h2>
      </div>

      <p className="text-sm text-gray-600 mb-4">
        Untuk keamanan, kami akan mengirimkan tautan reset ke email profil Anda
        ({user?.email || "-"}).
      </p>

      <Button variant="primary" onClick={handleDirectReset} disabled={loading}>
        {loading ? "Memproses..." : "Kirim Link Reset & Keluar"}
      </Button>
    </div>
  );
}
