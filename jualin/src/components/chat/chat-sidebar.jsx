'use client';
import { useContext, useEffect, useState } from 'react';
import { Clock3, History, MessageSquare, Search } from 'lucide-react';
import { ChatList } from './ChatList';
import { AuthContext } from '@/context/AuthProvider';

export function ChatSidebar({ chats = [], selectedId, onSelect }) {
  const { user } = useContext(AuthContext);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState('latest');
  const [chatPrefs, setChatPrefs] = useState({
    hidden: {},
    muted: {},
    pinned: {},
    read: {},
  });

  useEffect(() => {
    if (!user?.id || typeof window === 'undefined') return;
    const loadPreferences = () => {
      try {
        const saved = JSON.parse(
          localStorage.getItem(`chat_preferences:${user.id}`) || '{}'
        );
        setChatPrefs({
          hidden: saved.hidden || {},
          muted: saved.muted || {},
          pinned: saved.pinned || {},
          read: saved.read || {},
        });
      } catch {
        setChatPrefs({ hidden: {}, muted: {}, pinned: {}, read: {} });
      }
    };

    loadPreferences();

    const handlePreferencesUpdated = (event) => {
      if (String(event.detail?.userId) !== String(user.id)) return;
      const saved = event.detail?.preferences || {};
      setChatPrefs({
        hidden: saved.hidden || {},
        muted: saved.muted || {},
        pinned: saved.pinned || {},
        read: saved.read || {},
      });
    };

    window.addEventListener(
      'jualin:chat-preferences-updated',
      handlePreferencesUpdated
    );

    return () => {
      window.removeEventListener(
        'jualin:chat-preferences-updated',
        handlePreferencesUpdated
      );
    };
  }, [user?.id]);

  const updateChatPrefs = (updater) => {
    setChatPrefs((current) => {
      const next = typeof updater === 'function' ? updater(current) : updater;
      if (user?.id && typeof window !== 'undefined') {
        localStorage.setItem(`chat_preferences:${user.id}`, JSON.stringify(next));
        window.dispatchEvent(
          new CustomEvent('jualin:chat-preferences-updated', {
            detail: { userId: user.id, preferences: next },
          })
        );
      }
      return next;
    });
  };

  const markRead = (chatId) => {
    updateChatPrefs((current) => ({
      ...current,
      read: { ...current.read, [chatId]: true },
    }));
  };

  const togglePin = (chatId) => {
    updateChatPrefs((current) => {
      const pinned = { ...current.pinned };
      if (pinned[chatId]) delete pinned[chatId];
      else pinned[chatId] = Date.now();
      return { ...current, pinned };
    });
  };

  const toggleMute = (chatId) => {
    updateChatPrefs((current) => {
      const muted = { ...current.muted };
      if (muted[chatId]) delete muted[chatId];
      else muted[chatId] = true;
      return { ...current, muted };
    });
  };

  const hideChat = (chatId) => {
    updateChatPrefs((current) => ({
      ...current,
      hidden: { ...current.hidden, [chatId]: true },
    }));
  };

  const filters = [
    { value: 'latest', label: 'Terbaru', Icon: Clock3 },
    { value: 'oldest', label: 'Terlama', Icon: History },
    { value: 'unread', label: 'Belum Dibaca', Icon: MessageSquare },
  ];

  return (
    <div className="bg-white h-full flex flex-col overflow-hidden relative">
      {/* Header */}
      <div className="px-4 py-4 md:px-5 md:py-6 border-b border-gray-100 bg-white/50 backdrop-blur-sm sticky top-0 z-10 transition-all">
        <h2 className="text-lg md:text-xl font-bold text-gray-900 mb-4 md:mb-5">Chat</h2>

        {/* Search Bar */}
        <div className="relative mb-4 md:mb-5 group">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 group-focus-within:text-red-500 transition-colors" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari percakapan..."
            className="w-full pl-10 pr-4 py-2.5 md:py-3 bg-gray-50 border-none rounded-2xl text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-red-100 focus:bg-white transition-all shadow-sm group-hover:bg-white group-hover:shadow-md"
          />
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 overflow-x-auto pb-1">
          {filters.map(({ value, label, Icon }) => {
            const isActive = activeFilter === value;

            return (
              <button
                key={value}
                type="button"
                onClick={() => setActiveFilter(value)}
                className={`inline-flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-2 text-xs font-bold shadow-sm transition-all md:px-4 ${
                  isActive
                    ? 'border-red-500 bg-gradient-to-r from-red-500 to-red-600 text-white shadow-red-200'
                    : 'border-gray-200 bg-white text-gray-600 hover:border-red-200 hover:bg-red-50 hover:text-red-600'
                }`}
              >
                <Icon className="h-3.5 w-3.5" />
                {label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Chat List */}
      <ChatList
        chats={chats}
        selectedId={selectedId}
        onSelect={onSelect}
        searchQuery={searchQuery}
        filter={activeFilter}
        chatPrefs={chatPrefs}
        onMarkRead={markRead}
        onTogglePin={togglePin}
        onToggleMute={toggleMute}
        onHideChat={hideChat}
      />
    </div>
  );
}
