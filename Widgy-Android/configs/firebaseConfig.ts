/**
 * firebaseConfig.ts
 * Firebase JS SDK konfigürasyonu
 * google-services.json dosyasından alınan değerler
 */

import { initializeApp, getApps } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyBXFw1wdwIhx6yEwhAapoLkc4tfwabiF84",
  authDomain: "widgyy-20.firebaseapp.com",
  projectId: "widgyy-20",
  storageBucket: "widgyy-20.firebasestorage.app",
  messagingSenderId: "143681440719",
  appId: "1:143681440719:android:900d4b9410faaef62ce0ba",
};

// Birden fazla initialize olmasını önle
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

export const db = getFirestore(app);
export const auth = getAuth(app);
export default app;
