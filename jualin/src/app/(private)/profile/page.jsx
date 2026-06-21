"use client"
import { useAuth } from "@/context/AuthProvider"
import { useRouter } from "next/navigation"
import { useState } from "react"
import Cookies from "js-cookie"
import Header from "@/components/common/Header"
import { ProfileHeaderSection } from "./sections/profile-header"
import { profileService } from "@/services/profile/profileService"

export default function ProfilePage() {
  const { user, setUser } = useAuth()
  const router = useRouter()
  const [showConfirm, setShowConfirm] = useState(false)
  const [showSuccess, setShowSuccess] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [deletePassword, setDeletePassword] = useState("")
  const [deletePhrase, setDeletePhrase] = useState("")
  const [deleteError, setDeleteError] = useState("")
  const [scheduledAt, setScheduledAt] = useState(null)

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
    <div className="min-h-screen bg-white">
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
          <div className="w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-red-50 text-red-600">
              <span className="text-3xl">!</span>
            </div>
            <h2 className="text-center text-xl font-black text-gray-900">
              Hapus Akun?
            </h2>
            <p className="mt-2 text-center text-sm leading-relaxed text-gray-500">
              Akun dijadwalkan untuk dihapus permanen dalam 14 hari. Anda masih dapat login dan membatalkannya selama masa pemulihan.
            </p>
            <div className="mt-5 rounded-2xl border border-red-100 bg-red-50 p-4 text-left">
              <p className="text-sm font-bold text-red-800">Dampak penghapusan:</p>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-xs leading-5 text-red-700">
                <li>Profil dan akses akun akan dihapus permanen.</li>
                <li>Riwayat transaksi, chat, produk, dan data terkait dapat ikut terhapus.</li>
                <li>Sesi pada perangkat ini akan langsung dikeluarkan.</li>
              </ul>
            </div>
            <label className="mt-5 block text-sm font-bold text-gray-700">Password akun</label>
            <input
              type="password"
              value={deletePassword}
              onChange={(event) => setDeletePassword(event.target.value)}
              className="mt-2 w-full rounded-2xl border border-gray-300 px-4 py-3 outline-none focus:border-red-500 focus:ring-2 focus:ring-red-100"
              placeholder="Masukkan password"
              autoComplete="current-password"
            />
            <label className="mt-4 block text-sm font-bold text-gray-700">Ketik HAPUS AKUN untuk melanjutkan</label>
            <input
              type="text"
              value={deletePhrase}
              onChange={(event) => setDeletePhrase(event.target.value)}
              className="mt-2 w-full rounded-2xl border border-gray-300 px-4 py-3 outline-none focus:border-red-500 focus:ring-2 focus:ring-red-100"
              placeholder="HAPUS AKUN"
              autoComplete="off"
            />
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
  )
}
