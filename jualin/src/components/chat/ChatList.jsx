"use client";
import { useContext } from "react";
import { ChatItem } from "./ChatItem";
import { AuthContext } from "@/context/AuthProvider";
import { getProfilePictureUrl } from "@/utils/imageHelper";

export function ChatList({
  chats = [],
  selectedId,
  onSelect,
  searchQuery = "",
  filter = "all",
}) {
  const { user } = useContext(AuthContext);

  const transformedChats = chats.map((chat) => {
    const otherParticipantId = chat.participants?.find(
      (id) => id !== user?.id?.toString()
    );
    const otherParticipant = otherParticipantId
      ? chat.participantDetails?.[otherParticipantId]
      : null;

    let timeStr = "";
    if (chat.lastMessage?.timestamp) {
      const timestamp = chat.lastMessage.timestamp;
      const date = timestamp?.toDate ? timestamp.toDate() : new Date(timestamp);

      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffMs / 86400000);

      if (diffMins < 1) {
        timeStr = "Just now";
      } else if (diffMins < 60) {
        timeStr = `${diffMins}m ago`;
      } else if (diffHours < 24) {
        timeStr = `${diffHours}h ago`;
      } else if (diffDays === 1) {
        timeStr = "Yesterday";
      } else if (diffDays < 7) {
        timeStr = `${diffDays}d ago`;
      } else {
        timeStr = date.toLocaleDateString("id-ID", {
          day: "numeric",
          month: "short",
        });
      }
    }

    return {
      id: chat.id,
      otherUserId: otherParticipantId,
      name: otherParticipant?.name || "Unknown User",
      handle: otherParticipant?.name
        ? `@${otherParticipant.name.toLowerCase().replace(/\s+/g, "")}`
        : "@user",
      message: chat.lastMessage?.text || "No messages yet",
      time: timeStr,
      unread: chat.unreadCount?.[user?.id?.toString()] || 0,
      avatar: getProfilePictureUrl(otherParticipant?.profile_picture || otherParticipant?.avatar),
      role: otherParticipant?.role,
      originalChat: chat,
    };
  });

  const filteredChats = transformedChats.filter((chat) => {
    const matchesSearch =
      chat.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      chat.handle?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      chat.message?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesFilter =
      filter === "all" || (filter === "unread" && chat.unread > 0);

    return matchesSearch && matchesFilter;
  });

  if (chats.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="text-center">
          <div className="h-20 w-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
            <svg
              className="h-10 w-10 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
          </div>
          <p className="text-sm text-gray-500 font-medium">
            No conversations yet
          </p>
          <p className="text-xs text-gray-400 mt-1">
            Start chatting with sellers from product pages
          </p>
        </div>
      </div>
    );
  }

  if (filteredChats.length === 0) {
    return (
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="text-center">
          <p className="text-sm text-gray-500">Chat tidak ditemukan</p>
          <p className="text-xs text-gray-400 mt-1">
            Coba kata kunci lain
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto py-2 custom-scrollbar">
      {filteredChats.map((chat) => (
        <ChatItem
          key={chat.id}
          chat={chat}
          isSelected={selectedId === chat.id}
          onClick={() => onSelect?.(chat.id)}
        />
      ))}
    </div>
  );
}
