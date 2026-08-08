/**
 * proverbService.ts
 * Firestore'dan atasözü ve tema verilerini çeken servis
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  orderBy,
  updateDoc,
  arrayUnion,
  arrayRemove,
} from "firebase/firestore";
import { db } from "@/configs/firebaseConfig";

// ─── Tipler ──────────────────────────────────────────────────
export interface Proverb {
  id: number;
  type: "Atasözü" | "Deyim";
  title: string;
  meaning: string;
  example_sentence: string;
  theme_tags: string[];
}

export interface Theme {
  id: string;
  name: string;
  preview_image_url: string;
  is_premium: boolean;
  colors: {
    background: string;
    text: string;
    accent: string;
  };
  font_family: string;
  layout_style: string;
  sort_order: number;
}

// ─── Günlük Atasözü (tarih bazlı, sunucu gerektirmez) ────────
/**
 * Bugünün tarihine göre deterministik olarak bir atasözü ID'si hesaplar.
 * Aynı gün tüm kullanıcılara aynı atasözü gösterilir.
 * 400 atasözü döngüsel olarak gösterilir (~1.1 yılda tekrar eder).
 */
export function getDailyProverbId(): number {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 0);
  const diff = now.getTime() - start.getTime();
  const oneDay = 1000 * 60 * 60 * 24;
  const dayOfYear = Math.floor(diff / oneDay);
  return (dayOfYear % 400) + 1;
}

// ─── Tek atasözü getir ────────────────────────────────────────
export async function getProverbById(id: number): Promise<Proverb | null> {
  const docRef = doc(db, "proverbs", String(id));
  const docSnap = await getDoc(docRef);

  if (!docSnap.exists()) return null;
  return docSnap.data() as Proverb;
}

// ─── Günün atasözünü getir ────────────────────────────────────
export async function getDailyProverb(): Promise<Proverb | null> {
  const id = getDailyProverbId();
  return getProverbById(id);
}

// ─── Tüm atasözlerini getir ───────────────────────────────────
export async function getAllProverbs(): Promise<Proverb[]> {
  const q = query(collection(db, "proverbs"));
  const snapshot = await getDocs(q);
  return snapshot.docs.map((d) => d.data() as Proverb);
}

// ─── Atasözü ara ──────────────────────────────────────────────
export async function searchProverbs(searchText: string): Promise<Proverb[]> {
  const all = await getAllProverbs();
  const lower = searchText.toLowerCase();
  return all.filter(
    (p) =>
      p.title.toLowerCase().includes(lower) ||
      p.meaning.toLowerCase().includes(lower) ||
      p.example_sentence.toLowerCase().includes(lower)
  );
}

// ─── Tüm temaları getir ───────────────────────────────────────
export async function getAllThemes(): Promise<Theme[]> {
  const q = query(collection(db, "themes"), orderBy("sort_order"));
  const snapshot = await getDocs(q);
  return snapshot.docs.map((d) => d.data() as Theme);
}

// ─── Favorilere ekle / çıkar (Auth gerekli) ──────────────────
export async function addToFavorites(userId: string, proverbId: number): Promise<void> {
  const userRef = doc(db, "users", userId);
  await updateDoc(userRef, {
    favorites: arrayUnion(proverbId),
  });
}

export async function removeFromFavorites(userId: string, proverbId: number): Promise<void> {
  const userRef = doc(db, "users", userId);
  await updateDoc(userRef, {
    favorites: arrayRemove(proverbId),
  });
}
