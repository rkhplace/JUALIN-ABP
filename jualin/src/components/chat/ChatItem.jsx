import { useState, useEffect } from 'react';
import { Badge } from '@/components/ui/Badge';
import UserAvatar from '@/components/ui/UserAvatar';
import { fetchChatPartnerProfile } from '@/services/chat/chatService';
import {
  BellOff,
  CheckCheck,
  MoreHorizontal,
  Pin,
  PinOff,
  Trash2,
  Volume2,
} from 'lucide-react';

export function ChatItem({
  chat,
  isSelected,
  onClick,
  onMarkRead,
  onTogglePin,
  onToggleMute,
  onHideChat,
}) {
  const [fetchedUser, setFetchedUser] = useState(null);
  const [menuOpen, setMenuOpen] = useState(false);

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

  const displayAvatar = fetchedUser?.profile_picture || chat.avatar;

  const handleMenuAction = (event, action) => {
    event.stopPropagation();
    setMenuOpen(false);
    action?.();
  };

  return (
    <div
      onClick={onClick}
      className={`mx-2 md:mx-3 my-2 p-3 md:p-4 rounded-2xl cursor-pointer transition-all duration-300 ease-in-out group relative overflow-hidden ${isSelected
          ? 'bg-gradient-to-r from-red-50 via-white to-white shadow-md border-l-4 border-red-500 translate-x-1'
          : 'hover:bg-gray-50 border border-transparent hover:shadow-sm hover:translate-x-1'
        }`}
    >
      <div className="flex items-start gap-3 md:gap-4 relative z-10">
        {/* Avatar */}
        <div className="relative shrink-0">
          <UserAvatar
            name={chat.name}
            src={displayAvatar}
            sizeClass="h-10 w-10 md:h-12 md:w-12"
          />
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0 py-0.5">
          {/* Name and Handle */}
          <div className="flex justify-between items-start mb-1">
            <div className="min-w-0">
              <div className="flex min-w-0 items-center gap-1.5">
                {chat.isPinned && (
                  <Pin className="h-3.5 w-3.5 shrink-0 fill-red-500 text-red-500" />
                )}
                {chat.isMuted && (
                  <BellOff className="h-3.5 w-3.5 shrink-0 text-gray-400" />
                )}
                <h3 className={`font-bold text-sm truncate transition-colors ${isSelected ? 'text-gray-900' : 'text-gray-800'}`}>
                  {chat.name}
                </h3>
              </div>
            </div>
            <div className="relative ml-2 flex shrink-0 items-center gap-1">
              {chat.time && (
                <span className={`text-[10px] font-medium ${isSelected ? 'text-red-500' : 'text-gray-400 group-hover:text-red-400'}`}>
                  {chat.time}
                </span>
              )}
              <button
                type="button"
                onClick={(event) => {
                  event.stopPropagation();
                  setMenuOpen((value) => !value);
                }}
                className={`grid h-7 w-7 place-items-center rounded-full transition ${
                  menuOpen
                    ? 'bg-red-50 text-red-600'
                    : 'text-gray-400 hover:bg-gray-100 hover:text-gray-700'
                }`}
                aria-label="Opsi chat"
              >
                <MoreHorizontal className="h-4 w-4" />
              </button>
              {menuOpen && (
                <div
                  className="absolute right-0 top-8 z-30 w-52 overflow-hidden rounded-2xl border border-gray-100 bg-white py-2 shadow-[0_18px_48px_rgba(15,23,42,0.18)]"
                  onClick={(event) => event.stopPropagation()}
                >
                  <ChatMenuButton
                    icon={CheckCheck}
                    label="Tandai dibaca"
                    onClick={(event) => handleMenuAction(event, onMarkRead)}
                  />
                  <ChatMenuButton
                    icon={chat.isPinned ? PinOff : Pin}
                    label={chat.isPinned ? 'Lepas pin' : 'Pin obrolan'}
                    onClick={(event) => handleMenuAction(event, onTogglePin)}
                  />
                  <ChatMenuButton
                    icon={chat.isMuted ? Volume2 : BellOff}
                    label={chat.isMuted ? 'Nyalakan' : 'Matikan'}
                    onClick={(event) => handleMenuAction(event, onToggleMute)}
                  />
                  <div className="my-1 h-px bg-gray-100" />
                  <ChatMenuButton
                    icon={Trash2}
                    label="Hapus obrolan"
                    danger
                    onClick={(event) => {
                      if (window.confirm('Sembunyikan obrolan ini dari daftar chat?')) {
                        handleMenuAction(event, onHideChat);
                      }
                    }}
                  />
                </div>
              )}
            </div>
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

function ChatMenuButton({ icon: Icon, label, onClick, danger = false }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm font-semibold transition ${
        danger
          ? 'text-red-600 hover:bg-red-50'
          : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
      }`}
    >
      <Icon className="h-4 w-4" />
      {label}
    </button>
  );
}
