"use client"
import { useAuth } from "@/context/AuthProvider"
import { useRouter } from "next/navigation"
import { useEffect, useState } from "react"
import Cookies from "js-cookie"
import Header from "@/components/common/Header"
import DashboardBackground from "@/components/ui/DashboardBackground.jsx"
import { ProfileHeaderSection } from "./sections/profile-header"
import { profileService } from "@/services/profile/profileService"
import { authService } from "@/services/auth/authService"
import { Check, Eye, EyeOff, KeyRound, RefreshCw, ShieldAlert, ShoppingBag, Store, Type } from "lucide-react"

export default function ProfilePage() {
  const { user, setUser } = useAuth()
  const router = useRouter()
  const [showConfirm, setShowConfirm] = useState(false)
  const [showSuccess, setShowSuccess] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [deletePassword, setDeletePassword] = useState("")
  const [deletePhrase, setDeletePhrase] = useState("")
  const [deleteError, setDeleteError] = useState("")
  const [showDeletePassword, setShowDeletePassword] = useState(false)
  const [scheduledAt, setScheduledAt] = useState(null)
  const [activeRole, setActiveRole] = useState("")
  const [isBecomingSeller, setIsBecomingSeller] = useState(false)
  const [modeError, setModeError] = useState("")

  const accountRole = String(user?.role || "customer").toLowerCase()
  const isSellerAccount = accountRole === "seller"
  const modeRole = activeRole || accountRole

  useEffect(() => {
    if (typeof window === "undefined") return
    setActiveRole(
      String(localStorage.getItem("active_role") || accountRole).toLowerCase()
    )
  }, [accountRole])

  const applyActiveRole = (role) => {
    const normalizedRole = String(role || "customer").toLowerCase()
    localStorage.setItem("active_role", normalizedRole)
    Cookies.set("role", normalizedRole, { sameSite: "lax" })
    setActiveRole(normalizedRole)
  }

  const switchToBuyerMode = () => {
    applyActiveRole("customer")
    router.push("/dashboard")
  }

  const switchToSellerMode = () => {
    applyActiveRole("seller")
    router.push("/seller/dashboard")
  }

  const handleBecomeSeller = async () => {
    if (isBecomingSeller) return

    const confirmed = window.confirm(
      "Daftarkan akun email ini sebagai penjual? Akun yang sama tetap bisa digunakan untuk belanja."
    )
    if (!confirmed) return

    setIsBecomingSeller(true)
    setModeError("")
    try {
      const updatedUser = await authService.becomeSeller()
      setUser(updatedUser)
      localStorage.setItem("user", JSON.stringify(updatedUser))
      applyActiveRole("seller")
      router.push("/seller/dashboard")
    } catch (error) {
      setModeError(error?.message || "Gagal mendaftarkan akun sebagai penjual.")
    } finally {
      setIsBecomingSeller(false)
    }
  }

  const handleDeleteAccount = async () => {
    setDeleting(true)
    try {
      const response = await profileService.requestAccountDeletion(deletePassword, deletePhrase)
      setScheduledAt(response?.data?.scheduled_deletion_at || null)
      localStorage.removeItem("token")
      localStorage.removeItem("refresh_token")
      localStorage.removeItem("user")
      localStorage.removeItem("firebase_token")
      localStorage.removeItem("verified_popup_shown")
      Cookies.remove("role")
      Cookies.remove("token")
      Cookies.remove("accessToken")
      Cookies.remove("refreshToken")
      setUser(null)
      setShowConfirm(false)
      setShowSuccess(true)
    } catch (error) {
      setDeleteError(error?.message || "Gagal menjadwalkan penghapusan akun.")
    } finally {
      setDeleting(false)
    }
  }

  const openDeleteConfirmation = () => {
    setDeletePassword("")
    setDeletePhrase("")
    setDeleteError("")
    setShowConfirm(true)
  }

  const cancelScheduledDeletion = async () => {
    const response = await profileService.cancelAccountDeletion()
    setUser(response?.data || response)
  }

  return (
    <div className="jualin-dashboard-bg min-h-screen">
      <DashboardBackground />
      <div className="jualin-content-layer">
      <Header />
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center justify-between py-6">
            <h1 className="text-2xl font-semibold">Profile</h1>
            <button
              onClick={() => router.push(`/profile/edit?id=${user?.id || user?._id || user?.userId || ''}`)}
              className="px-4 py-2 rounded-md bg-red-600 text-white"
            >
              Edit Profile
            </button>
          </div>

          <ProfileHeaderSection user={user} />

          {accountRole !== "admin" && (
            <div className="mt-6 rounded-2xl border border-red-100 bg-white p-5 shadow-sm">
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div className="flex items-start gap-3">
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-red-50 text-red-600">
                    <RefreshCw size={20} />
                  </div>
                  <div>
                    <h2 className="font-bold text-gray-900">Mode Akun</h2>
                    <p className="mt-1 text-sm text-gray-600">
                      {isSellerAccount
                        ? modeRole === "seller"
                          ? "Saat ini Anda sedang mengelola toko sebagai penjual."
                          : "Saat ini Anda sedang menjelajah marketplace sebagai pembeli."
                        : "Gunakan email akun ini untuk mulai berjualan di Jualin."}
                    </p>
                  </div>
                </div>
                {!isSellerAccount ? (
                  <button
                    onClick={handleBecomeSeller}
                    disabled={isBecomingSeller}
                    className="inline-flex items-center justify-center gap-2 rounded-xl bg-red-600 px-4 py-2.5 text-sm font-bold text-white shadow-sm hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    <Store size={18} />
                    {isBecomingSeller ? "Mendaftarkan..." : "Daftar Sebagai Penjual"}
                  </button>
                ) : modeRole === "seller" ? (
                  <button
                    onClick={switchToBuyerMode}
                    className="inline-flex items-center justify-center gap-2 rounded-xl border border-red-200 bg-white px-4 py-2.5 text-sm font-bold text-red-600 hover:bg-red-50"
                  >
                    <ShoppingBag size={18} />
                    Masuk Mode Pembeli
                  </button>
                ) : (
                  <button
                    onClick={switchToSellerMode}
                    className="inline-flex items-center justify-center gap-2 rounded-xl bg-red-600 px-4 py-2.5 text-sm font-bold text-white shadow-sm hover:bg-red-700"
                  >
                    <Store size={18} />
                    Masuk Mode Penjual
                  </button>
                )}
              </div>
              {modeError && (
                <p className="mt-3 text-sm font-semibold text-red-600">
                  {modeError}
                </p>
              )}
            </div>
          )}

          <div className="mt-6 rounded-lg border border-red-100 bg-red-50 p-5">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <h2 className="font-bold text-gray-900">Hapus Akun</h2>
                <p className="mt-1 text-sm text-gray-600">
                  {user?.scheduled_deletion_at
                    ? `Akun dijadwalkan dihapus pada ${new Date(user.scheduled_deletion_at).toLocaleDateString("id-ID", { day: "numeric", month: "long", year: "numeric" })}.`
                    : "Jadwalkan penghapusan permanen dengan masa pemulihan 14 hari."}
                </p>
              </div>
              <button
                onClick={user?.scheduled_deletion_at ? cancelScheduledDeletion : openDeleteConfirmation}
                className={`rounded-md px-4 py-2 font-semibold ${user?.scheduled_deletion_at ? "border border-red-200 bg-white text-red-600 hover:bg-red-50" : "bg-red-600 text-white hover:bg-red-700"}`}
              >
                {user?.scheduled_deletion_at ? "Batalkan Penghapusan" : "Hapus Akun"}
              </button>
            </div>
          </div>
        </div>
      </div>

      {showConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md overflow-hidden rounded-[28px] border border-red-100 bg-white shadow-[0_30px_90px_-24px_rgba(17,24,39,0.48),0_18px_50px_-24px_rgba(232,48,48,0.45)]">
            <div className="bg-gradient-to-b from-red-50/90 to-white px-6 pb-5 pt-6">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-red-600 text-white shadow-[0_12px_28px_-10px_rgba(232,48,48,0.7)]">
              <ShieldAlert size={30} />
            </div>
            <h2 className="text-center text-xl font-black text-gray-900">
              Hapus Akun?
            </h2>
            <p className="mt-2 text-center text-sm leading-relaxed text-gray-500">
              Akun dijadwalkan untuk dihapus permanen dalam 14 hari. Anda masih dapat login dan membatalkannya selama masa pemulihan.
            </p>
            </div>
            <div className="px-6 pb-6">
            <div className="mt-5 rounded-2xl border border-red-100 bg-red-50 p-4 text-left">
              <p className="text-sm font-bold text-red-800">Dampak penghapusan:</p>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-xs leading-5 text-red-700">
                <li>Profil dan akses akun akan dihapus permanen.</li>
                <li>Riwayat transaksi, chat, produk, dan data terkait dapat ikut terhapus.</li>
                <li>Sesi pada perangkat ini akan langsung dikeluarkan.</li>
              </ul>
            </div>
            <div className="mt-5 space-y-3">
              <div className="rounded-2xl border border-gray-200 bg-gray-50/80 p-3 transition focus-within:border-red-300 focus-within:bg-white focus-within:shadow-[0_10px_24px_-14px_rgba(232,48,48,0.45)]">
                <div className="mb-2 flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-gray-500"><span className="grid h-6 w-6 place-items-center rounded-lg bg-white text-red-600 shadow-sm"><KeyRound size={14} /></span> 1. Password akun</div>
                <div className="flex items-center gap-2">
                  <input type={showDeletePassword ? "text" : "password"} value={deletePassword} onChange={(event) => setDeletePassword(event.target.value)} className="min-w-0 flex-1 bg-transparent px-1 py-1.5 text-sm font-semibold text-gray-900 outline-none placeholder:font-normal placeholder:text-gray-400" placeholder="Masukkan password Jualin" autoComplete="current-password" />
                  <button type="button" onClick={() => setShowDeletePassword((value) => !value)} className="grid h-9 w-9 place-items-center rounded-xl text-gray-500 hover:bg-white hover:text-red-600" aria-label={showDeletePassword ? "Sembunyikan password" : "Tampilkan password"}>{showDeletePassword ? <EyeOff size={18} /> : <Eye size={18} />}</button>
                </div>
              </div>
              <div className={`rounded-2xl border p-3 transition ${deletePhrase === "HAPUS AKUN" ? "border-emerald-200 bg-emerald-50/60" : "border-gray-200 bg-gray-50/80 focus-within:border-red-300 focus-within:bg-white focus-within:shadow-[0_10px_24px_-14px_rgba(232,48,48,0.45)]"}`}>
                <div className="mb-2 flex items-center justify-between gap-2"><span className="flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-gray-500"><span className="grid h-6 w-6 place-items-center rounded-lg bg-white text-red-600 shadow-sm"><Type size={14} /></span> 2. Konfirmasi frasa</span>{deletePhrase === "HAPUS AKUN" && <span className="flex items-center gap-1 text-xs font-bold text-emerald-700"><Check size={14} /> Cocok</span>}</div>
                <input type="text" value={deletePhrase} onChange={(event) => setDeletePhrase(event.target.value.toUpperCase())} className="w-full bg-transparent px-1 py-1.5 text-sm font-black tracking-[0.12em] text-gray-900 outline-none placeholder:font-semibold placeholder:tracking-normal placeholder:text-gray-400" placeholder="Ketik HAPUS AKUN" autoComplete="off" />
                <p className="mt-1 px-1 text-xs text-gray-500">Harus sama persis dengan <strong>HAPUS AKUN</strong>.</p>
              </div>
            </div>
            {deleteError && <p className="mt-3 text-sm font-semibold text-red-600">{deleteError}</p>}
            <div className="mt-6 grid grid-cols-2 gap-3">
              <button
                onClick={() => setShowConfirm(false)}
                className="rounded-2xl border border-red-100 px-4 py-3 font-bold text-red-600"
                disabled={deleting}
              >
                Batal
              </button>
              <button
                onClick={handleDeleteAccount}
                className="rounded-2xl bg-red-600 px-4 py-3 font-bold text-white disabled:opacity-60"
                disabled={deleting || !deletePassword || deletePhrase !== "HAPUS AKUN"}
              >
                {deleting ? "Menjadwalkan..." : "Jadwalkan Penghapusan"}
              </button>
            </div>
            </div>
          </div>
        </div>
      )}

      {showSuccess && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-white p-6 text-center shadow-2xl">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-green-50 text-3xl text-green-600">
              ✓
            </div>
            <h2 className="text-xl font-black text-gray-900">
              Penghapusan Dijadwalkan
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-gray-500">
              Akun akan dihapus permanen pada {scheduledAt ? new Date(scheduledAt).toLocaleDateString("id-ID", { day: "numeric", month: "long", year: "numeric" }) : "14 hari lagi"}. Login kembali sebelum tanggal tersebut untuk membatalkannya.
            </p>
            <button
              onClick={() => router.replace("/auth/login")}
              className="mt-6 w-full rounded-2xl bg-red-600 px-4 py-3 font-bold text-white"
            >
              Mengerti
            </button>
          </div>
        </div>
      )}
      </div>
    </div>
  )
}
