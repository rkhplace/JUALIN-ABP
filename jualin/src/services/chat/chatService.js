import { fetcher } from "@/lib/fetcher";
import { userService } from "@/services/user/userService";
import { db, auth } from "@/lib/firebase";
import { signInWithCustomToken } from "firebase/auth";
import {
  collection,
  doc,
  onSnapshot,
  addDoc,
  setDoc,
  serverTimestamp,
  query,
  orderBy,
  where,
  limit,
} from "firebase/firestore";

// ---------------------------------------------------------------------------
// Helper: fetch partner profile
// ---------------------------------------------------------------------------
export async function fetchChatPartnerProfile(userId) {
  try {
    return await userService.fetchById(userId);
  } catch (error) {
    console.error("❌ Error fetching chat partner profile:", error);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Helper: format Laravel room → shape React components expect
// ---------------------------------------------------------------------------
function formatRoomData(room, currentUserId) {
  const currentIdStr = parseInt(currentUserId).toString();
  const otherIdStr = room.other_user ? room.other_user.id.toString() : null;

  const participants = [currentIdStr];
  const participantDetails = {
    [currentIdStr]: { role: "customer" },
  };

  if (otherIdStr) {
    participants.push(otherIdStr);
    participantDetails[otherIdStr] = {
      name: room.other_user.username,
      avatar: room.other_user.profile_picture,
      role: room.room_type === "private" ? "seller" : "customer",
    };
  }

  let lastMessage = null;
  let unreadCount = { [currentIdStr]: 0 };

  if (room.latest_message) {
    const latestType = room.latest_message.type || "text";
    lastMessage = {
      text:
        latestType === "image"
          ? "Mengirim foto"
          : room.latest_message.message,
      type: latestType,
      timestamp: new Date(room.latest_message.sent_at),
      senderId: room.latest_message.sender_id.toString(),
    };

    if (
      !room.latest_message.is_read &&
      room.latest_message.sender_id.toString() !== currentIdStr
    ) {
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

// ---------------------------------------------------------------------------
// Create / find a chat room (stays on Laravel for validation)
// ---------------------------------------------------------------------------
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
      product_id: productId,
    });
    const roomId = res?.data?.room_id || res?.room_id || res?.data?.id;

    // Ensure Firestore document exists so onSnapshot can pick it up
    if (roomId) {
      await _ensureFirestoreRoom(roomId, [
        customerId.toString(),
        sellerId.toString(),
      ]);
    }

    return roomId;
  } catch (e) {
    console.error("❌ Error starting chat:", e);
    throw e;
  }
}

// ---------------------------------------------------------------------------
// Internal: create / merge Firestore room document
// ---------------------------------------------------------------------------
async function _ensureFirestoreRoom(roomId, participantIds) {
  try {
    const roomRef = doc(db, "chats", roomId.toString());
    await setDoc(
      roomRef,
      {
        participants: participantIds,
        updatedAt: serverTimestamp(),
      },
      { merge: true }
    );
  } catch (e) {
    console.error("❌ Error ensuring Firestore room:", e);
  }
}

// ---------------------------------------------------------------------------
// Helper: pastikan user terautentikasi ke Firebase sebelum Firestore ops
// ---------------------------------------------------------------------------
async function ensureFirebaseAuth() {
  if (auth.currentUser) {
    console.log("🔥 Firebase already authenticated as:", auth.currentUser.uid);
    return true;
  }

  console.warn("⚠️ auth.currentUser is null, mencoba re-auth dari localStorage...");

  if (typeof window === "undefined") return false;

  const fbToken = localStorage.getItem("firebase_token");
  if (!fbToken) {
    console.error("❌ Tidak ada firebase_token di localStorage. Silakan logout & login ulang.");
    return false;
  }

  try {
    await signInWithCustomToken(auth, fbToken);
    console.log("🔥 Firebase re-auth berhasil sebagai:", auth.currentUser?.uid);
    return true;
  } catch (e) {
    console.error("❌ Firebase re-auth gagal:", e.code, e.message);
    if (e.code === "auth/invalid-custom-token" || e.code === "auth/custom-token-mismatch") {
      // Token expired atau invalid — hapus
      localStorage.removeItem("firebase_token");
      console.error("❌ firebase_token expired. Silakan logout & login ulang.");
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Send message — write to Laravel (validation + DB) then mirror to Firestore
// ---------------------------------------------------------------------------
export async function sendMessage(
  chatId,
  senderId,
  senderName,
  text,
  senderAvatar = null,
  participants = [] // array of user ID strings, dari currentChat.participants
) {
  let res;
  try {
    // 1. Persist to Laravel backend (authoritative source)
    res = await fetcher.post(`/api/v1/chat/rooms/${chatId}/messages`, {
      message: text,
    });
  } catch (e) {
    console.error("\u274c Error sending message to Laravel:", e);
    throw e;
  }

  // 2. Mirror to Firestore (non-blocking)
  try {
    // Pastikan user terautentikasi ke Firebase (auth.currentUser bisa null setelah reload)
    const isAuthed = await ensureFirebaseAuth();
    if (!isAuthed) {
      console.warn("⚠️ Firestore skip: user tidak terautentikasi ke Firebase");
      return res;
    }

    // Pastikan room document ada di Firestore SEBELUM tulis pesan
    // Ini penting agar rules 'isParticipant' bisa dicek dan onSnapshot penerima trigger
    if (participants.length > 0) {
      await _ensureFirestoreRoom(chatId, participants.map(String));
    }

    const savedMsg = res?.data || res;
    const msgId = savedMsg?.id?.toString() ?? Date.now().toString();

    const msgsRef = collection(db, "chats", chatId.toString(), "messages");
    await addDoc(msgsRef, {
      id: msgId,
      text,
      senderId: senderId.toString(),
      senderName,
      senderAvatar: senderAvatar || null,
      timestamp: serverTimestamp(),
      read: false,
    });

    const roomRef = doc(db, "chats", chatId.toString());
    setDoc(roomRef, { updatedAt: serverTimestamp() }, { merge: true }).catch(
      (e) => console.warn("⚠️ Firestore room update failed:", e.code)
    );
  } catch (e) {
    console.error("\u274c Error mirroring message to Firestore:", e.code, e.message);
  }

  return res;
}

export async function sendImageMessage(
  chatId,
  senderId,
  senderName,
  imageFile,
  senderAvatar = null,
  participants = []
) {
  let res;
  try {
    const formData = new FormData();
    formData.append("type", "image");
    formData.append("image", imageFile);

    res = await fetcher.upload(
      `/api/v1/chat/rooms/${chatId}/messages`,
      formData
    );
  } catch (e) {
    console.error("❌ Error sending image to Laravel:", e);
    throw e;
  }

  try {
    const isAuthed = await ensureFirebaseAuth();
    if (!isAuthed) {
      console.warn("⚠️ Firestore skip: user tidak terautentikasi ke Firebase");
      return res;
    }

    if (participants.length > 0) {
      await _ensureFirestoreRoom(chatId, participants.map(String));
    }

    const savedMsg = res?.data || res;
    const msgId = savedMsg?.id?.toString() ?? Date.now().toString();
    const imageUrl = savedMsg?.message || "";

    const msgsRef = collection(db, "chats", chatId.toString(), "messages");
    await addDoc(msgsRef, {
      id: msgId,
      text: imageUrl,
      type: "image",
      senderId: senderId.toString(),
      senderName,
      senderAvatar: senderAvatar || null,
      timestamp: serverTimestamp(),
      read: false,
    });

    const roomRef = doc(db, "chats", chatId.toString());
    setDoc(roomRef, { updatedAt: serverTimestamp() }, { merge: true }).catch(
      (e) => console.warn("⚠️ Firestore room update failed:", e.code)
    );
  } catch (e) {
    console.error("❌ Error mirroring image message to Firestore:", e.code, e.message);
  }

  return res;
}

// ---------------------------------------------------------------------------
// Real-time room list via Firestore onSnapshot
// Falls back to initial REST fetch so the list isn't empty on first load
// ---------------------------------------------------------------------------
export function getUserChatRooms(userId, callback) {
  const userIdStr = userId.toString();

  // Seed the room list from Laravel immediately so UI isn't blank
  let latestLaravelRooms = [];
  fetcher
    .get("/api/v1/chat/rooms")
    .then((res) => {
      const roomsData = res?.data || res || [];
      if (Array.isArray(roomsData)) {
        latestLaravelRooms = roomsData.map((r) => formatRoomData(r, userId));
        callback(latestLaravelRooms);

        // Make sure every Laravel room has a Firestore doc (idempotent)
        roomsData.forEach((r) => {
          const ids = [userIdStr];
          if (r.other_user?.id) ids.push(r.other_user.id.toString());
          _ensureFirestoreRoom(r.id, ids);
        });
      }
    })
    .catch((e) => console.error("❌ Initial rooms fetch error:", e));

  // Firestore real-time listener — triggers on any room update
  const chatsRef = collection(db, "chats");
  const q = query(
    chatsRef,
    where("participants", "array-contains", userIdStr)
  );

  const unsubscribe = onSnapshot(
    q,
    (snapshot) => {
      // When Firestore triggers, refresh the full list from Laravel
      // (Firestore is the trigger, Laravel is the source of truth for message data)
      fetcher
        .get("/api/v1/chat/rooms")
        .then((res) => {
          const roomsData = res?.data || res || [];
          if (Array.isArray(roomsData)) {
            const mapped = roomsData.map((r) => formatRoomData(r, userId));
            callback(mapped);
          }
        })
        .catch((e) =>
          console.error("❌ Rooms refresh on Firestore trigger failed:", e)
        );
    },
    (err) => {
      console.error("❌ Firestore rooms onSnapshot error:", err);
    }
  );

  return unsubscribe;
}

// ---------------------------------------------------------------------------
// Helper: parse Laravel messages response → array
// ---------------------------------------------------------------------------
function parseLaravelMessages(res) {
  let msgsData = [];
  if (res?.data?.data) msgsData = res.data.data;
  else if (Array.isArray(res?.data)) msgsData = res.data;
  else if (Array.isArray(res)) msgsData = res;

  return msgsData.map((m) => {
    const messageType =
      m.type ||
      (typeof m.message === "string" && m.message.includes("/chat-images/")
        ? "image"
        : "text");

    return {
      id: m.id,
      text: m.message,
      senderId: m.sender_id.toString(),
      senderName: m.sender?.username || "User",
      senderAvatar: m.sender?.profile_picture || null,
      timestamp: new Date(m.sent_at),
      read: m.is_read,
      type: messageType,
      product: m.product_data || null,
    };
  });
}

// ---------------------------------------------------------------------------
// Real-time messages via Firestore onSnapshot
// Returns { unsubscribe, refresh } — panggil refresh() untuk re-fetch dari Laravel
// ---------------------------------------------------------------------------
export function getChatMessages(chatId, callback) {
  const msgsRef = collection(db, "chats", chatId.toString(), "messages");
  const q = query(msgsRef, orderBy("timestamp", "asc"), limit(200));

  // refresh(): re-fetch messages dari Laravel (dipanggil setelah sendMessage atau onSnapshot trigger)
  const refresh = () =>
    fetcher
      .get(`/api/v1/chat/rooms/${chatId}/messages?per_page=100`)
      .then((res) => {
        const mapped = parseLaravelMessages(res);
        callback(mapped);
      })
      .catch((e) => console.error("❌ Messages refresh error:", e));

  // Seed from Laravel immediately so the chat window isn't blank
  refresh();

  // Firestore real-time listener — hanya sebagai TRIGGER, data tetap dari Laravel
  // Ini memastikan senderId selalu Laravel user ID (angka), bukan Firebase UID
  const unsubscribe = onSnapshot(
    q,
    (snapshot) => {
      if (snapshot.empty) return;
      // Ada perubahan di Firestore → fetch data terbaru dari Laravel
      refresh();
    },
    (err) => {
      console.error("❌ Firestore messages onSnapshot error:", err);
    }
  );

  // Return both unsubscribe and refresh
  return { unsubscribe, refresh };
}

// ---------------------------------------------------------------------------
// Send product message to chat (product bubble feature)
// ---------------------------------------------------------------------------
export async function sendProductMessage(chatId, productData) {
  try {
    const res = await fetcher.post(`/api/v1/chat/rooms/${chatId}/product-message`, {
      product_data: productData,
    });
    return res;
  } catch (e) {
    console.error("❌ Error sending product message:", e);
    throw e;
  }
}

// ---------------------------------------------------------------------------
// Room info helper (used by startChat flow)
// ---------------------------------------------------------------------------
export async function getChatRoomInfo(chatId) {
  try {
    const res = await fetcher.get("/api/v1/chat/rooms");
    const roomsData = res?.data || res || [];
    if (Array.isArray(roomsData)) {
      const room = roomsData.find((r) => parseInt(r.id) === parseInt(chatId));
      if (room) {
        const currentData = await fetcher.get("/api/v1/me");
        const userId =
          currentData?.data?.id || currentData?.id || room.other_user?.id || 1;
        return formatRoomData(room, userId);
      }
    }
  } catch (e) {
    console.error("❌ Error fetching room info:", e);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Read-status helpers (handled server-side on Laravel messages fetch)
// ---------------------------------------------------------------------------
export async function markMessageAsRead(chatId, messageId) {}
export async function incrementUnreadCount(chatId, receiverId) {}
export async function resetUnreadCount(chatId, userId) {}
