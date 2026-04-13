'use client';
import { CheckCircle2 } from 'lucide-react';
import { getProfilePictureUrl } from '@/utils/imageHelper';

export function ChatHeader({ chat }) {
  if (!chat) {
    return (
      <div className="relative px-6 py-4 border-b border-gray-100 bg-white/80 backdrop-blur-md z-50 md:sticky md:top-0 md:z-40">
        <p className="text-sm text-gray-400 font-medium">Pilih chat untuk memulai</p>
      </div>
    );
  }

  const displayName = chat.name || "Pengguna";
  const displayHandle = chat.handle || `@${displayName.toLowerCase().replace(/\s+/g, '')}`;

  return (
    <div className="relative px-6 py-4 mx-4 mt-4 bg-white z-50 rounded-2xl shadow-sm transition-all duration-300">
      <div className="flex items-center gap-4">
        {/* Large Avatar without Ring */}
        <div className="relative shrink-0">
          <div className="h-12 w-12 rounded-full border-2 border-white overflow-hidden shadow-sm flex items-center justify-center bg-gray-100">
            {getProfilePictureUrl(chat.avatar || chat.profile_picture) ? (
              <img 
                src={getProfilePictureUrl(chat.avatar || chat.profile_picture)} 
                alt={displayName} 
                className="h-full w-full object-cover" 
              />
            ) : (
              <span className="text-gray-500 font-bold text-lg">
                {(displayName && displayName.length > 0 ? displayName[0] : 'S').toUpperCase()}
              </span>
            )}
          </div>
        </div>

        {/* User Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <h2 className="text-lg font-bold text-gray-900 truncate tracking-tight">{displayName}</h2>
            {chat.role === 'verified' && (
              <CheckCircle2 className="h-4 w-4 fill-blue-500 text-white" />
            )}
          </div>
          <div className="flex items-center gap-2 text-xs text-gray-500 font-medium">
            <p className="truncate text-gray-400">
              {displayHandle}
            </p>
            {chat.online ? (
              <>
                <span className="h-1 w-1 rounded-full bg-gray-300"></span>
                <span className="text-green-600">Online</span>
              </>
            ) : (
              <span className="pl-1">Offline</span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
