"use client"

import { getProfilePictureUrl } from '@/utils/imageHelper';

export function ProfileHeaderSection({ user }) {
  const formatBirthday = (birthday) => {
    if (!birthday) return "Not set";
    const date = new Date(birthday);
    return date.toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' });
  };

  const getLocation = () => {
    const parts = [];
    if (user?.city) parts.push(user.city);
    if (user?.region) parts.push(user.region);
    return parts.length > 0 ? parts.join(', ') : "Not set";
  };

  const profileImageUrl = getProfilePictureUrl(user?.profile_picture);

  return (
    <div className="bg-white rounded-lg border p-6">
      {/* Profile Picture */}
      {user?.profile_picture && (
        <div className="mb-6 flex justify-center">
          <img
            src={profileImageUrl}
            alt={user.username || 'Profile'}
            className="w-32 h-32 rounded-full object-cover border-2 border-gray-200"
            onError={(e) => {
              e.target.src = '/ProfilePhoto.png';
            }}
          />
        </div>
      )}

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Username</label>
          <p className="mt-1 text-sm text-gray-900">{user?.username || "Not set"}</p>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Email</label>
          <p className="mt-1 text-sm text-gray-900">{user?.email || "Not set"}</p>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Gender</label>
          <p className="mt-1 text-sm text-gray-900 capitalize">{user?.gender || "Not set"}</p>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Birthday</label>
          <p className="mt-1 text-sm text-gray-900">{formatBirthday(user?.birthday)}</p>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Location</label>
          <p className="mt-1 text-sm text-gray-900">{getLocation()}</p>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Bio</label>
          <p className="mt-1 text-sm text-gray-900">{user?.bio || "Not set"}</p>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Role</label>
          <p className="mt-1 text-sm text-gray-900 capitalize">{user?.role || "Customer"}</p>
        </div>
      </div>
    </div>
  );
}
