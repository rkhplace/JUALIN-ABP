import { initializeApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "AIzaSyBjDTf07Yo9Yuf0ugbPPioT--IbwgjZRpY",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "jualin-46db8.firebaseapp.com",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "jualin-46db8",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "jualin-46db8.firebasestorage.app",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "614205822769",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "1:614205822769:web:1962794fde2b4928e9c210",
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID || "G-BZ5N61TP8D",
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
