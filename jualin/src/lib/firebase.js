import { initializeApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "AIzaSyBC48eQP1Cr3Pyl1k3x3bc8jM1E1E1NwEA",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "jualin-chat-app.firebaseapp.com",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "jualin-chat-app",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "jualin-chat-app.firebasestorage.app",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "373985633037",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "1:373985633037:web:d444ddad60fbb8bb01c644",
};

// Debug: log missing Firebase config keys in development
if (process.env.NODE_ENV !== "production") {
  const missingKeys = Object.entries(firebaseConfig)
    .filter(([, v]) => !v)
    .map(([k]) => k);
  if (missingKeys.length > 0) {
    console.error("❌ Firebase: Missing config keys:", missingKeys);
  } else {
    console.log("✅ Firebase config loaded for project:", firebaseConfig.projectId);
  }
}

const app =
  getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

export const db = getFirestore(app);
export const auth = getAuth(app);
export default app;
