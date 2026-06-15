"use client"

import { useEffect, useState } from 'react';
import VerifiedBadge from '@/components/ui/VerifiedBadge';
import { sellerService } from '@/services/seller/sellerService';
import UserAvatar from '@/components/ui/UserAvatar';

export function ProfileHeaderSection({ user }) {
  const [isVerified, setIsVerified] = useState(false);

  // Fetch live verification status only for sellers
  useEffect(() => {
    if (user?.role !== 'seller') return;

    sellerService
      .getVerificationStatus()
      .then((data) => {
        setIsVerified(data?.is_verified ?? false);
      })
      .catch(() => {
        // silently ignore
      });
  }, [user?.role]);

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

  return (
    <div className="bg-white rounded-lg border p-6">
      {/* Profile Picture */}
      <div className="mb-6 flex justify-center">
        <UserAvatar
          name={user?.username || user?.name || 'User'}
          src={user?.profile_picture || user?.avatar}
          sizeClass="w-32 h-32"
          className="text-4xl"
        />
      </div>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Username</label>
          <p className="mt-1 text-sm text-gray-900 flex items-center gap-1.5">
            {user?.username || "Not set"}
            {isVerified && <VerifiedBadge size="sm" />}
          </p>
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
          <p className="mt-1 text-sm text-gray-900 capitalize flex items-center gap-1.5">
            {user?.role || "Customer"}
            {user?.role === 'seller' && isVerified && (
              <span className="text-xs text-blue-500 font-semibold">(Terverifikasi)</span>
            )}
          </p>
        </div>
      </div>
    </div>
  );
}
