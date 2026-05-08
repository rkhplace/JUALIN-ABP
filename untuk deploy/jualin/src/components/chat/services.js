const chats = [
  { id: 1, name: 'seller_alpha', handle: '@alpha', online: true, message: 'Stok masih ada, kak.', unread: 2 },
  { id: 2, name: 'seller_bravo', handle: '@bravo', online: false, message: 'Siap admin, sudah diupdate.', unread: 0 },
  { id: 3, name: 'customer_neo', handle: '@neo', online: true, message: 'Ukuran jaket fit to L ya?', unread: 1 },
];

const seed = {
  1: [{ id: 1, sender: 'seller_alpha', content: 'Hai! Masih tersedia kak, stok 3 lagi ya.', time: '10:05', isMe: false }],
  2: [{ id: 2, sender: 'seller_bravo', content: 'Siap admin, stok saya sudah saya update barusan.', time: '12:15', isMe: false }],
  3: [{ id: 3, sender: 'customer_neo', content: 'Kak, ukuran jaketnya fit to L ya?', time: '08:02', isMe: false }],
};

const KEY = 'chat.messages';

function readStore() {
  if (typeof window === 'undefined') return {};
  const raw = localStorage.getItem(KEY);
  return raw ? JSON.parse(raw) : {};
}

function writeStore(data) {
  if (typeof window === 'undefined') return;
  localStorage.setItem(KEY, JSON.stringify(data));
}

export async function fetchChats() {
  return chats;
}

export async function fetchMessages(chatId) {
  const store = readStore();
  return store[chatId] || seed[chatId] || [];
}

export async function sendMessage(chatId, text) {
  const store = readStore();
  const curr = store[chatId] || (seed[chatId] ? [...seed[chatId]] : []);
  const msg = { id: Date.now(), sender: 'You', content: text, time: new Date().toLocaleTimeString(), isMe: true };
  const next = [...curr, msg];
  store[chatId] = next;
  writeStore(store);
  return next;
}