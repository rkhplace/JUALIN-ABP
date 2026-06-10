"use client";
import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useRef,
} from "react";
import { AuthContext } from "./AuthProvider";
import {
  getUserChatRooms,
  getChatMessages,
  sendMessage as sendMessageService,
  sendProductMessage as sendProductMessageService,
  getOrCreateChatRoom,
  getChatRoomInfo,
  resetUnreadCount,
} from "@/services/chat/chatService";

export const ChatContext = createContext();

export function ChatProvider({ children }) {
  const { user } = useContext(AuthContext);
  const [chats, setChats] = useState([]);
  const [currentChat, setCurrentChat] = useState(null);
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  // Ref ke fungsi refresh() dari getChatMessages — dipanggil setelah sendMessage
  const refreshMessagesRef = useRef(null);

  useEffect(() => {
    if (!user?.id) {
      setChats([]);
      return;
    }

    const unsubscribe = getUserChatRooms(user.id, (chatsData) => {
      setChats(chatsData);
    });

    return () => {
      unsubscribe();
    };
  }, [user?.id]);

  useEffect(() => {
    if (!currentChat?.id) {
      setMessages([]);
      refreshMessagesRef.current = null;
      return;
    }

    const { unsubscribe, refresh } = getChatMessages(currentChat.id, (messagesData) => {
      setMessages(messagesData);
    });

    // Simpan ref ke refresh() agar bisa dipanggil dari sendMessage
    refreshMessagesRef.current = refresh;

    if (user?.id) {
      resetUnreadCount(currentChat.id, user.id).catch((err) => {
        console.error("Failed to reset unread count:", err);
      });
    }

    return () => {
      unsubscribe();
      refreshMessagesRef.current = null;
    };
  }, [currentChat?.id, user?.id]);

  const startChat = useCallback(
    async (otherUserId, otherUserInfo, productPayload = null) => {
      if (!user?.id) {
        throw new Error("User belum login");
      }

      setLoading(true);
      try {
        const currentUserInfo = {
          name: user.name || user.username || user.email,
          avatar: user.avatar || user.profile_picture || null,
          role: String(user.role || "customer").toLowerCase(),
        };

        const otherUserInfoWithRole = {
          ...otherUserInfo,
          role: otherUserInfo.role || "seller",
        };

        const isCurrentUserCustomer = currentUserInfo.role === "customer";

        const customerId = isCurrentUserCustomer ? user.id : otherUserId;
        const sellerId = isCurrentUserCustomer ? otherUserId : user.id;

        const chatId = await getOrCreateChatRoom(
          customerId,
          sellerId,
          currentUserInfo,
          otherUserInfoWithRole,
          productPayload?.id || productPayload
        );

        const chatInfoFromList = chats.find(
          (chat) => String(chat.id) === String(chatId)
        );
        const currentUserId = String(user.id);
        const otherUserIdStr = String(otherUserId);
        const fallbackChatInfo = {
          id: chatId,
          participants: [currentUserId, otherUserIdStr],
          participantDetails: {
            [currentUserId]: currentUserInfo,
            [otherUserIdStr]: {
              name:
                otherUserInfoWithRole.name ||
                otherUserInfoWithRole.username ||
                otherUserInfoWithRole.email ||
                "Seller",
              avatar: otherUserInfoWithRole.avatar || null,
              role: otherUserInfoWithRole.role || "seller",
            },
          },
          lastMessage: null,
          unreadCount: { [currentUserId]: 0 },
          updatedAt: new Date(),
        };

        setCurrentChat(chatInfoFromList || fallbackChatInfo);

        getChatRoomInfo(chatId)
          .then((chatInfo) => {
            if (chatInfo) setCurrentChat(chatInfo);
          })
          .catch((err) => {
            console.error("[startChat] Failed to refresh chat info:", err);
          });

        // Send product as a chat message in the background.
        if (productPayload && typeof productPayload === "object" && chatId) {
          sendProductMessageService(chatId, productPayload)
            .then(() => {
              refreshMessagesRef.current?.();
              console.log("[startChat] Product message sent for chatId:", chatId);
            })
            .catch((err) => {
              console.error("[startChat] Failed to send product message:", err);
            });
        }

        return chatId;
      } catch (error) {
        console.error("❌ Error starting chat:", error);
        throw error;
      } finally {
        setLoading(false);
      }
    },
    [user, chats]
  );

  const openChatWithUser = useCallback(
    async (targetUserId) => {
      if (!user?.id) {
        throw new Error("User belum login");
      }

      setLoading(true);
      try {
        const targetUserIdStr = String(targetUserId);

        const existingChat = chats.find((chat) => {
          if (!chat.participants) return false;
          const participantsStr = chat.participants.map((p) => String(p));
          return participantsStr.includes(targetUserIdStr);
        });

        if (existingChat) {
          setCurrentChat(existingChat);
          return existingChat.id;
        }
        throw new Error("No existing conversation found with this user");
      } catch (error) {
        console.error("❌ Error opening chat:", error);
        throw error;
      } finally {
        setLoading(false);
      }
    },
    [user, chats]
  );

  const sendMessage = useCallback(
    async (text) => {
      if (!currentChat?.id || !user?.id || !text.trim()) {
        console.warn("⚠️ Cannot send message: missing data");
        return;
      }

      // Optimistic update — tampilkan pesan langsung di UI tanpa tunggu server
      const optimisticId = `optimistic-${Date.now()}`;
      const optimisticMsg = {
        id: optimisticId,
        text: text.trim(),
        senderId: user.id.toString(),
        senderName: user.name || user.username || user.email,
        senderAvatar: user.avatar || user.profile_picture || null,
        timestamp: new Date(),
        read: false,
        _optimistic: true,
      };
      setMessages((prev) => [...prev, optimisticMsg]);

      try {
        await sendMessageService(
          currentChat.id,
          user.id,
          user.name || user.username || user.email,
          text.trim(),
          user.avatar || user.profile_picture || null,
          currentChat.participants || [] // pastikan room Firestore ada sebelum tulis pesan
        );
        // Hapus optimistis lalu ambil versi final dari Laravel
        setMessages((prev) => prev.filter((m) => m.id !== optimisticId));
        refreshMessagesRef.current?.();
      } catch (error) {
        // Rollback: hapus pesan optimistis jika server gagal
        setMessages((prev) => prev.filter((m) => m.id !== optimisticId));
        console.error("❌ Error sending message:", error);
        throw error;
      }
    },
    [currentChat, user]
  );

  const selectChat = useCallback((chat) => {
    setCurrentChat(chat);
  }, []);

  return (
    <ChatContext.Provider
      value={{
        chats,
        currentChat,
        messages,
        loading,
        startChat,
        openChatWithUser,
        sendMessage,
        selectChat,
      }}
    >
      {children}
    </ChatContext.Provider>
  );
}
