"use client"
import { useAuth } from "@/context/AuthProvider"
import { useRouter } from "next/navigation"
import Header from "@/components/common/Header"
import { ProfileHeaderSection } from "./sections/profile-header"

export default function ProfilePage() {
  const { user } = useAuth()
  const router = useRouter()

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
        </div>
      </div>
    </div>
  )
}