import { useState, useEffect, useCallback, useRef } from 'react';
import { createPortal } from 'react-dom';
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
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [menuPosition, setMenuPosition] = useState({ top: 0, right: 0 });
  const menuButtonRef = useRef(null);
  const menuRef = useRef(null);

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

  const updateMenuPosition = useCallback(() => {
    const button = menuButtonRef.current;
    if (!button || typeof window === 'undefined') return;

    const rect = button.getBoundingClientRect();
    const menuHeight = 196;
    const top =
      rect.bottom + 8 + menuHeight > window.innerHeight
        ? Math.max(12, rect.top - menuHeight - 8)
        : rect.bottom + 8;

    setMenuPosition({
      top,
      right: Math.max(12, window.innerWidth - rect.right),
    });
  }, []);

  useEffect(() => {
    if (!menuOpen || typeof window === 'undefined') return;

    updateMenuPosition();

    const handlePointerDown = (event) => {
      if (
        menuRef.current?.contains(event.target) ||
        menuButtonRef.current?.contains(event.target)
      ) {
        return;
      }
      setMenuOpen(false);
    };

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') setMenuOpen(false);
    };

    document.addEventListener('pointerdown', handlePointerDown);
    document.addEventListener('keydown', handleKeyDown);
    window.addEventListener('resize', updateMenuPosition);
    window.addEventListener('scroll', updateMenuPosition, true);

    return () => {
      document.removeEventListener('pointerdown', handlePointerDown);
      document.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('resize', updateMenuPosition);
      window.removeEventListener('scroll', updateMenuPosition, true);
    };
  }, [menuOpen, updateMenuPosition]);

  const handleMenuAction = (event, action) => {
    event.stopPropagation();
    setMenuOpen(false);
    action?.();
  };

  return (
    <div
      onClick={onClick}
      className={`mx-2 md:mx-3 my-2 p-3 md:p-4 rounded-2xl cursor-pointer transition-all duration-300 ease-in-out group relative ${isSelected
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
                ref={menuButtonRef}
                type="button"
                onClick={(event) => {
                  event.stopPropagation();
                  updateMenuPosition();
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
              <ChatItemMenu
                chat={chat}
                isOpen={menuOpen}
                menuRef={menuRef}
                position={menuPosition}
                onMarkRead={(event) => handleMenuAction(event, onMarkRead)}
                onTogglePin={(event) => handleMenuAction(event, onTogglePin)}
                onToggleMute={(event) => handleMenuAction(event, onToggleMute)}
                onHideChat={(event) => {
                  event.stopPropagation();
                  setMenuOpen(false);
                  setConfirmOpen(true);
                }}
              />
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
      <HideChatConfirmModal
        isOpen={confirmOpen}
        onCancel={() => setConfirmOpen(false)}
        onConfirm={() => {
          setConfirmOpen(false);
          onHideChat?.();
        }}
      />
    </div>
  );
}

function HideChatConfirmModal({ isOpen, onCancel, onConfirm }) {
  useEffect(() => {
    if (!isOpen || typeof document === 'undefined') return;

    const handleKeyDown = (event) => {
      if (event.key === 'Escape') onCancel?.();
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onCancel]);

  if (!isOpen || typeof document === 'undefined') return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[10000] flex items-center justify-center bg-black/45 px-4 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-labelledby="hide-chat-title"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-md rounded-[28px] border border-white/70 bg-white p-6 shadow-[0_30px_80px_rgba(15,23,42,0.28)]"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="flex items-start gap-4">
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-red-50 text-red-600">
            <Trash2 className="h-5 w-5" />
          </div>
          <div className="min-w-0">
            <h2 id="hide-chat-title" className="text-xl font-bold text-gray-950">
              Hapus obrolan?
            </h2>
            <p className="mt-2 text-sm font-medium leading-relaxed text-gray-500">
              Obrolan akan disembunyikan dari daftar pesan di perangkat ini.
            </p>
          </div>
        </div>
        <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button
            type="button"
            onClick={onCancel}
            className="inline-flex h-11 items-center justify-center rounded-2xl px-5 text-sm font-bold text-gray-500 transition hover:bg-gray-50 hover:text-gray-800"
          >
            Batal
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className="inline-flex h-11 items-center justify-center rounded-2xl bg-[#E83030] px-7 text-sm font-bold text-white shadow-[0_16px_34px_rgba(232,48,48,0.28)] transition hover:bg-red-600"
          >
            Hapus
          </button>
        </div>
      </div>
    </div>,
    document.body
  );
}

function ChatItemMenu({
  chat,
  isOpen,
  menuRef,
  position,
  onMarkRead,
  onTogglePin,
  onToggleMute,
  onHideChat,
}) {
  if (!isOpen || typeof document === 'undefined') return null;

  return createPortal(
    <div
      ref={menuRef}
      className="fixed z-[9999] w-52 overflow-hidden rounded-2xl border border-gray-100 bg-white py-2 shadow-[0_22px_56px_rgba(15,23,42,0.22)]"
      style={{ top: position.top, right: position.right }}
      onClick={(event) => event.stopPropagation()}
    >
      <ChatMenuButton
        icon={CheckCheck}
        label="Tandai dibaca"
        onClick={onMarkRead}
      />
      <ChatMenuButton
        icon={chat.isPinned ? PinOff : Pin}
        label={chat.isPinned ? 'Lepas pin' : 'Pin obrolan'}
        onClick={onTogglePin}
      />
      <ChatMenuButton
        icon={chat.isMuted ? Volume2 : BellOff}
        label={chat.isMuted ? 'Nyalakan' : 'Matikan'}
        onClick={onToggleMute}
      />
      <div className="my-1 h-px bg-gray-100" />
      <ChatMenuButton
        icon={Trash2}
        label="Hapus obrolan"
        danger
        onClick={onHideChat}
      />
    </div>,
    document.body
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
