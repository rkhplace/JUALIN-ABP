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

  const handleDeleteAccount = async () => {
    setDeleting(true)
    try {
      await profileService.deleteAccount()
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
    } finally {
      setDeleting(false)
    }
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
                  Hapus akun Jualin secara permanen dari sistem.
                </p>
              </div>
              <button
                onClick={() => setShowConfirm(true)}
                className="rounded-md bg-red-600 px-4 py-2 font-semibold text-white hover:bg-red-700"
              >
                Hapus Akun
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
              Akun Anda akan dihapus permanen dan sesi login akan keluar.
              Tindakan ini tidak dapat dibatalkan.
            </p>
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
                disabled={deleting}
              >
                {deleting ? "Menghapus..." : "Hapus"}
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
              Akun Berhasil Dihapus
            </h2>
            <p className="mt-2 text-sm leading-relaxed text-gray-500">
              Terima kasih sudah menggunakan Jualin. Anda akan diarahkan ke halaman login.
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
