"use client";

import React, { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Clock3, MailCheck, ShieldCheck } from "lucide-react";
import Logo from "@/components/ui/Logo";
import Input from "@/components/ui/Input";
import Button from "@/components/ui/Button";
import Toast from "@/components/ui/Toast";
import { passwordService } from "@/services";

const formatCountdown = (seconds) => {
  const safeSeconds = Math.max(0, seconds);
  const minutes = Math.floor(safeSeconds / 60);
  const remainder = safeSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`;
};

function ForgotPasswordContent() {
  const searchParams = useSearchParams();
  const isLocked = searchParams.get("reason") === "locked";
  const lockedUntil = searchParams.get("locked_until");
  const emailWasSent = searchParams.get("email_sent") === "1";
  const initialEmail = searchParams.get("email") || "";
  const [email, setEmail] = useState(initialEmail);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);
  const [remainingSeconds, setRemainingSeconds] = useState(0);

  const lockEnd = useMemo(() => {
    const timestamp = lockedUntil ? new Date(lockedUntil).getTime() : NaN;
    return Number.isFinite(timestamp) ? timestamp : null;
  }, [lockedUntil]);

  useEffect(() => {
    if (!lockEnd) return;
    const update = () => setRemainingSeconds(Math.max(0, Math.ceil((lockEnd - Date.now()) / 1000)));
    update();
    const timer = window.setInterval(update, 1000);
    return () => window.clearInterval(timer);
  }, [lockEnd]);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setToast(null);
    setLoading(true);
    try {
      await passwordService.sendResetLink(email);
      setToast({ message: "Link reset password telah dikirim. Silakan cek email Anda.", type: "success" });
    } catch (error) {
      setToast({ message: error.message || "Gagal mengirim link reset password.", type: "error" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex items-center justify-center relative overflow-hidden px-4 py-8">
      <div className="absolute -top-32 -left-36 w-96 h-96 bg-[#E83030] rounded-full blur-3xl opacity-15" />
      <div className="absolute -bottom-36 -right-32 w-96 h-96 bg-[#E83030] rounded-full blur-3xl opacity-15" />

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

      <main className="relative z-10 w-full max-w-md rounded-3xl border border-red-100/80 bg-white p-7 shadow-[0_28px_80px_-26px_rgba(17,24,39,0.30),0_18px_48px_-24px_rgba(232,48,48,0.48)] md:p-10">
        <Logo size="xl" className="mb-7" />

        {isLocked && (
          <section className="relative mb-7 overflow-hidden rounded-2xl border border-red-200/80 bg-gradient-to-br from-red-50 via-white to-red-50/40 p-5 shadow-[0_18px_38px_-16px_rgba(17,24,39,0.24),0_12px_30px_-18px_rgba(232,48,48,0.55)] ring-1 ring-white">
            <div className="pointer-events-none absolute -right-10 -top-12 h-28 w-28 rounded-full bg-red-200/35 blur-2xl" />
            <div className="mb-4 flex items-center gap-3">
              <span className="grid h-11 w-11 place-items-center rounded-full bg-[#E83030] text-white shadow-lg shadow-red-200">
                <ShieldCheck size={22} aria-hidden="true" />
              </span>
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-[#E83030]">Akun dilindungi</p>
                <h1 className="text-lg font-bold text-gray-900">Login dikunci sementara</h1>
              </div>
            </div>
            <p className="text-sm leading-6 text-gray-600">
              Terlalu banyak percobaan login. Coba lagi setelah waktu tunggu berakhir atau reset password Anda.
            </p>
            <div className="relative mt-4 flex items-center justify-between rounded-xl bg-white px-4 py-3 shadow-[0_10px_24px_-12px_rgba(17,24,39,0.28),0_6px_18px_-12px_rgba(232,48,48,0.45)] ring-1 ring-red-100">
              <span className="flex items-center gap-2 text-sm font-medium text-gray-600"><Clock3 size={17} /> Coba lagi dalam</span>
              <span className="font-mono text-xl font-bold tabular-nums text-[#E83030]">{formatCountdown(remainingSeconds)}</span>
            </div>
            {emailWasSent && (
              <p className="mt-4 flex items-start gap-2 text-xs leading-5 text-emerald-700">
                <MailCheck size={17} className="mt-0.5 shrink-0" /> Email peringatan dan link reset sudah dikirim ke alamat akun Anda.
              </p>
            )}
          </section>
        )}

        <div className="mb-6">
          {!isLocked && <h1 className="mb-2 text-2xl font-bold text-gray-900 md:text-3xl">Lupa Password</h1>}
          <p className="text-sm leading-6 text-gray-600">
            {isLocked ? "Kirim ulang link jika email belum masuk dalam beberapa menit." : "Masukkan email Anda untuk menerima tautan reset password."}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <Input label="Email" type="email" name="email" placeholder="nama@email.com" value={email} onChange={(event) => setEmail(event.target.value)} required />
          <Button type="submit" variant="primary" disabled={loading}>
            {loading ? "Mengirim..." : isLocked ? "Kirim Ulang Link Reset" : "Kirim Link Reset Password"}
          </Button>
        </form>

        <p className="mt-6 text-center text-sm text-gray-600">
          <Link href="/auth/login" className="font-semibold text-[#E83030] hover:text-red-600">
            Kembali ke halaman login
          </Link>
        </p>
      </main>
    </div>
  );
}

export default function ForgotPasswordPage() {
  return <Suspense fallback={<div className="min-h-screen bg-white" />}><ForgotPasswordContent /></Suspense>;
}
