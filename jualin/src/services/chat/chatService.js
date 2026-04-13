import { fetcher } from "@/lib/fetcher";
import { userService } from "@/services/user/userService";

// Keep this identical
export async function fetchChatPartnerProfile(userId) {
  try {
    return await userService.fetchById(userId);
  } catch (error) {
    console.error("❌ Error fetching chat partner profile:", error);
    return null;
  }
}

// Convert Laravel room structure to the format React components expect from Firebase
function formatRoomData(room, currentUserId) {
  const currentIdStr = parseInt(currentUserId).toString();
  const otherIdStr = room.other_user ? room.other_user.id.toString() : null;
  
  const participants = [currentIdStr];
  const participantDetails = {
    [currentIdStr]: { role: "customer" }, // dummy
  };

  if (otherIdStr) {
    participants.push(otherIdStr);
    participantDetails[otherIdStr] = {
      name: room.other_user.username,
      avatar: room.other_user.profile_picture,
      role: room.room_type === "private" ? "seller" : "customer", // simplistic role assignment
    };
  }

  let lastMessage = null;
  let unreadCount = { [currentIdStr]: 0 };

  if (room.latest_message) {
    lastMessage = {
      text: room.latest_message.message,
      timestamp: new Date(room.latest_message.sent_at),
      senderId: room.latest_message.sender_id.toString(),
    };
    
    if (!room.latest_message.is_read && room.latest_message.sender_id.toString() !== currentIdStr) {
      unreadCount[currentIdStr] = 1;
    }
  }

  return {
    id: room.id,
    participants,
    participantDetails,
    lastMessage,
    unreadCount,
    updatedAt: room.updated_at ? new Date(room.updated_at) : new Date(),
  };
}

export async function getOrCreateChatRoom(
  customerId,
  sellerId,
  customerInfo = null,
  sellerInfo = null,
  productId = null
) {
  try {
    const res = await fetcher.post("/api/v1/chat/rooms/start", {
      user_id: customerId,
      seller_id: sellerId,
    });
    // Support { data: { room_id: 123 } } or { room_id: 123 }
    const roomId = res?.data?.room_id || res?.room_id || res?.data?.id;
    return roomId;
  } catch (e) {
    console.error("❌ Error starting chat:", e);
    throw e;
  }
}

export async function sendMessage(
  chatId,
  senderId,
  senderName,
  text,
  senderAvatar = null
) {
  try {
    const res = await fetcher.post(`/api/v1/chat/rooms/${chatId}/messages`, {
      message: text,
    });
    return res;
  } catch (e) {
    console.error("❌ Error sending message:", e);
    throw e;
  }
}

export function getUserChatRooms(userId, callback) {
  let isCancelled = false;

  const poll = async () => {
    if (isCancelled) return;
    try {
      const res = await fetcher.get("/api/v1/chat/rooms");
      const roomsData = res?.data || res || [];
      
      if (Array.isArray(roomsData)) {
        const mappedChats = roomsData.map((r) => formatRoomData(r, userId));
        callback(mappedChats);
      }
    } catch (e) {
      console.error("❌ Error fetching chat rooms:", e);
      // don't empty on network error, but if we need to:
      // if (!isCancelled) callback([]); 
    }

    if (!isCancelled) {
      setTimeout(poll, 3000); // Poll every 3 seconds
    }
  };

  poll();

  return () => {
    isCancelled = true;
  };
}

export function getChatMessages(chatId, callback) {
  let isCancelled = false;

  const poll = async () => {
    if (isCancelled) return;
    try {
      const res = await fetcher.get(`/api/v1/chat/rooms/${chatId}/messages?per_page=100`);
      
      let msgsData = [];
      if (res?.data?.data) {
        msgsData = res.data.data;
      } else if (Array.isArray(res?.data)) {
        msgsData = res.data;
      } else if (Array.isArray(res)) {
        msgsData = res;
      }

      const mappedMsgs = msgsData.map((m) => ({
        id: m.id,
        text: m.message,
        senderId: m.sender_id.toString(),
        senderName: m.sender?.username || "User",
        senderAvatar: m.sender?.profile_picture || null,
        timestamp: new Date(m.sent_at),
        read: m.is_read,
      }));

      callback(mappedMsgs);
    } catch (e) {
      console.error("❌ Error fetching messages:", e);
    }

    if (!isCancelled) {
      setTimeout(poll, 2000); // Poll every 2 seconds
    }
  };

  poll();

  return () => {
    isCancelled = true;
  };
}

export async function getChatRoomInfo(chatId) {
  try {
    const res = await fetcher.get("/api/v1/chat/rooms");
    const roomsData = res?.data || res || [];
    if (Array.isArray(roomsData)) {
      const room = roomsData.find(r => parseInt(r.id) === parseInt(chatId));
      if (room) {
        const currentData = await fetcher.get("/api/v1/me");
        const userId = currentData?.data?.id || currentData?.id || room.other_user?.id || 1;
        return formatRoomData(room, userId);
      }
    }
  } catch (e) {
    console.error("❌ Error info:", e);
  }
  return null;
}

export async function markMessageAsRead(chatId, messageId) {
  // Handled automatically by Laravel messages endpoint
}

export async function incrementUnreadCount(chatId, receiverId) {
  // Handled automatically by Laravel messages endpoint
}

export async function resetUnreadCount(chatId, userId) {
  // Handled automatically by Laravel messages endpoint
}
