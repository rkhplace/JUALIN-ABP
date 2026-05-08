import { useState, useEffect } from 'react';
import { Badge } from '@/components/ui/Badge';
import { getProfilePictureUrl } from '@/utils/imageHelper';
import { fetchChatPartnerProfile } from '@/services/chat/chatService';

export function ChatItem({ chat, isSelected, onClick }) {
  const [fetchedUser, setFetchedUser] = useState(null);

  useEffect(() => {
    let isMounted = true;
    if (chat.otherUserId) {
      fetchChatPartnerProfile(chat.otherUserId)
        .then(userData => {
          if (isMounted && userData) {
            setFetchedUser(userData);
          }
        });
    }
    return () => { isMounted = false; };
  }, [chat.otherUserId]);

  const displayAvatar = getProfilePictureUrl(
    fetchedUser?.profile_picture || chat.avatar
  );

  return (
    <div
      onClick={onClick}
      className={`mx-3 my-2 p-4 rounded-2xl cursor-pointer transition-all duration-300 ease-in-out group relative overflow-hidden ${isSelected
          ? 'bg-gradient-to-r from-red-50 via-white to-white shadow-md border-l-4 border-red-500 translate-x-1'
          : 'hover:bg-gray-50 border border-transparent hover:shadow-sm hover:translate-x-1'
        }`}
    >
      <div className="flex items-start gap-4 relative z-10">
        {/* Avatar */}
        <div className="relative shrink-0">
          <div className={`h-12 w-12 rounded-full overflow-hidden shadow-sm flex items-center justify-center ${!displayAvatar ? 'bg-gradient-to-br from-gray-100 to-gray-200' : 'bg-gray-100'}`}>
            {displayAvatar ? (
              <img src={displayAvatar} alt={chat.name} className="h-full w-full object-cover" />
            ) : (
              <span className="text-gray-500 font-bold text-lg">
                {(chat.name && chat.name.length > 0 ? chat.name[0] : 'S').toUpperCase()}
              </span>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0 py-0.5">
          {/* Name and Handle */}
          <div className="flex justify-between items-start mb-1">
            <div className="min-w-0">
              <h3 className={`font-bold text-sm truncate transition-colors ${isSelected ? 'text-gray-900' : 'text-gray-800'}`}>
                {chat.name}
              </h3>
            </div>
            {chat.time && (
              <span className={`text-[10px] font-medium shrink-0 ml-2 ${isSelected ? 'text-red-500' : 'text-gray-400 group-hover:text-red-400'}`}>
                {chat.time}
              </span>
            )}
          </div>

          {/* Message Preview and Badge */}
          <div className="flex items-center justify-between gap-2">
            <p className={`text-xs truncate flex-1 leading-relaxed ${isSelected ? 'text-gray-600 font-medium' : 'text-gray-500'}`}>
              {chat.message}
            </p>
            {chat.unread > 0 && (
              <Badge className="h-5 min-w-5 rounded-full bg-gradient-to-r from-red-500 to-red-600 shadow-md shadow-red-200 text-white flex items-center justify-center px-1.5 text-[10px] font-bold shrink-0 animate-pulse-once">
                {chat.unread}
              </Badge>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
