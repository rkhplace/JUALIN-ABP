'use client';
import { useState } from 'react';
import { Search } from 'lucide-react';
import { ChatList } from './ChatList';

export function ChatSidebar({ chats = [], selectedId, onSelect }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState('all');

  return (
    <div className="bg-white h-full flex flex-col overflow-hidden relative">
      {/* Header */}
      <div className="px-5 py-6 border-b border-gray-100 bg-white/50 backdrop-blur-sm sticky top-0 z-10 transition-all">
        <h2 className="text-xl font-bold text-gray-900 mb-5">Chat</h2>

        {/* Search Bar */}
        <div className="relative mb-5 group">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 group-focus-within:text-red-500 transition-colors" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari percakapan..."
            className="w-full pl-10 pr-4 py-3 bg-gray-50 border-none rounded-2xl text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-red-100 focus:bg-white transition-all shadow-sm group-hover:bg-white group-hover:shadow-md"
          />
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2.5">
          <button
            onClick={() => setActiveFilter('all')}
            className={`px-5 py-2 rounded-full text-xs font-bold transition-all shadow-sm ${activeFilter === 'all'
              ? 'bg-gradient-to-r from-red-500 to-red-600 text-white shadow-red-200 transform scale-105'
              : 'bg-white border border-gray-100 text-gray-500 hover:bg-gray-50 hover:text-gray-900'
              }`}
          >
            Semua
          </button>
          <button
            onClick={() => setActiveFilter('unread')}
            className={`px-5 py-2 rounded-full text-xs font-bold transition-all shadow-sm ${activeFilter === 'unread'
              ? 'bg-gradient-to-r from-red-500 to-red-600 text-white shadow-red-200 transform scale-105'
              : 'bg-white border border-gray-100 text-gray-500 hover:bg-gray-50 hover:text-gray-900'
              }`}
          >
            Belum Dibaca
          </button>
        </div>
      </div>

      {/* Chat List */}
      <ChatList
        chats={chats}
        selectedId={selectedId}
        onSelect={onSelect}
        searchQuery={searchQuery}
        filter={activeFilter}
      />
    </div>
  );
}
