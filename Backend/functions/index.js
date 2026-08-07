/**
 * Cloud Functions — Ataların Sözü Backend
 * ─────────────────────────────────────────────────────────────
 * PRD Section 7.4'te tanımlanan tüm API endpoint'leri
 *
 * Fonksiyonlar:
 *  1. selectDailyProverb  — Scheduled: her gün 09:00 TR saatinde
 *  2. getDailyProverb     — GET  /api/daily-proverb
 *  3. addFavorite         — POST /api/user/favorites
 *  4. removeFavorite      — DELETE /api/user/favorites
 *  5. getThemes           — GET  /api/themes
 *  6. createUserProfile   — Trigger: Auth yeni kullanıcı oluşturunca
 * ─────────────────────────────────────────────────────────────
 */

const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { beforeUserCreated } = require("firebase-functions/v2/identity");

const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// ─── Yardımcı: Auth token doğrula ─────────────────────────────
async function verifyAuth(req, res) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({ error: "Yetkisiz erişim. Token gerekli." });
    return null;
  }
  const idToken = authHeader.split("Bearer ")[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded;
  } catch {
    res.status(401).json({ error: "Geçersiz token." });
    return null;
  }
}

// ─── Yardımcı: Bugünün tarihini YYYY-MM-DD formatında al ──────
function todayStr() {
  return new Date().toISOString().split("T")[0];
}

// ═══════════════════════════════════════════════════════════════
// 1. SCHEDULED: Günlük Atasözü Seçimi
//    Her gün saat 06:00 UTC = 09:00 Türkiye
// ═══════════════════════════════════════════════════════════════
exports.selectDailyProverb = onSchedule(
  {
    schedule: "0 6 * * *",   // Cron: her gün 06:00 UTC
    timeZone: "UTC",
    region: "europe-west1",
  },
  async () => {
    const today = todayStr();

    // 1. Zaten bugün için seçilmiş mi kontrol et
    const existingDoc = await db.collection("daily_proverb").doc(today).get();
    if (existingDoc.exists) {
      console.log(`[selectDailyProverb] ${today} için zaten seçim yapılmış.`);
      return;
    }

    // 2. Son 7 günde kullanılan atasözü ID'lerini topla
    const usedIds = [];
    for (let i = 1; i <= 7; i++) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split("T")[0];
      const doc = await db.collection("daily_proverb").doc(dateStr).get();
      if (doc.exists) usedIds.push(doc.data().proverb_id);
    }

    // 3. Toplam atasözü sayısını öğren
    const snapshot = await db.collection("proverbs").get();
    const total = snapshot.size;

    // 4. Daha önce kullanılmamış rastgele bir ID seç
    let selectedId;
    let attempts = 0;
    do {
      selectedId = Math.floor(Math.random() * total) + 1;
      attempts++;
      if (attempts > 50) break; // Sonsuz döngü önlemi
    } while (usedIds.includes(selectedId));

    // 5. daily_proverb collection'ına yaz
    await db.collection("daily_proverb").doc(today).set({
      date: today,
      proverb_id: selectedId,
      selected_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[selectDailyProverb] ${today} için #${selectedId} seçildi.`);
  }
);

// ═══════════════════════════════════════════════════════════════
// 2. GET /api/daily-proverb
//    Bugünün atasözünü döndürür
// ═══════════════════════════════════════════════════════════════
exports.getDailyProverb = onRequest(
  { region: "europe-west1", cors: true },
  async (req, res) => {
    if (req.method !== "GET") {
      return res.status(405).json({ error: "Sadece GET desteklenir." });
    }

    const today = todayStr();

    // 1. Günlük seçimi al
    const dailyDoc = await db.collection("daily_proverb").doc(today).get();

    if (!dailyDoc.exists) {
      return res.status(404).json({
        error: "Bugün için henüz atasözü seçilmemiş. Scheduled function çalıştırılıyor olabilir.",
      });
    }

    const { proverb_id } = dailyDoc.data();

    // 2. Atasözü detayını al
    const proverbDoc = await db.collection("proverbs").doc(String(proverb_id)).get();

    if (!proverbDoc.exists) {
      return res.status(404).json({ error: "Atasözü bulunamadı." });
    }

    return res.status(200).json({
      date: today,
      proverb: proverbDoc.data(),
    });
  }
);

// ═══════════════════════════════════════════════════════════════
// 3. POST /api/user/favorites
//    Kullanıcının favorilerine atasözü ekler
// ═══════════════════════════════════════════════════════════════
exports.addFavorite = onRequest(
  { region: "europe-west1", cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Sadece POST desteklenir." });
    }

    // Auth kontrol
    const user = await verifyAuth(req, res);
    if (!user) return;

    const { proverb_id } = req.body;
    if (!proverb_id || typeof proverb_id !== "number") {
      return res.status(400).json({ error: "Geçerli bir proverb_id gerekli (number)." });
    }

    // Atasözünün var olduğunu kontrol et
    const proverbDoc = await db.collection("proverbs").doc(String(proverb_id)).get();
    if (!proverbDoc.exists) {
      return res.status(404).json({ error: `#${proverb_id} ID'li atasözü bulunamadı.` });
    }

    // Favorilere ekle (arrayUnion → mükerrer eklemeyi önler)
    await db.collection("users").doc(user.uid).update({
      favorites: admin.firestore.FieldValue.arrayUnion(proverb_id),
    });

    return res.status(200).json({ success: true, message: "Favorilere eklendi." });
  }
);

// ═══════════════════════════════════════════════════════════════
// 4. DELETE /api/user/favorites
//    Kullanıcının favorilerinden atasözü çıkarır
// ═══════════════════════════════════════════════════════════════
exports.removeFavorite = onRequest(
  { region: "europe-west1", cors: true },
  async (req, res) => {
    if (req.method !== "DELETE") {
      return res.status(405).json({ error: "Sadece DELETE desteklenir." });
    }

    const user = await verifyAuth(req, res);
    if (!user) return;

    const { proverb_id } = req.body;
    if (!proverb_id || typeof proverb_id !== "number") {
      return res.status(400).json({ error: "Geçerli bir proverb_id gerekli (number)." });
    }

    await db.collection("users").doc(user.uid).update({
      favorites: admin.firestore.FieldValue.arrayRemove(proverb_id),
    });

    return res.status(200).json({ success: true, message: "Favorilerden çıkarıldı." });
  }
);

// ═══════════════════════════════════════════════════════════════
// 5. GET /api/themes
//    Tüm temaları listeler (kullanıcının satın aldıklarını işaretler)
// ═══════════════════════════════════════════════════════════════
exports.getThemes = onRequest(
  { region: "europe-west1", cors: true },
  async (req, res) => {
    if (req.method !== "GET") {
      return res.status(405).json({ error: "Sadece GET desteklenir." });
    }

    // Temaları çek
    const snapshot = await db.collection("themes").orderBy("sort_order").get();
    const themes = snapshot.docs.map((doc) => doc.data());

    // Auth varsa kullanıcının satın aldıklarını işaretle
    let purchasedThemes = [];
    let isPremium = false;

    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith("Bearer ")) {
      try {
        const idToken = authHeader.split("Bearer ")[1];
        const decoded = await admin.auth().verifyIdToken(idToken);
        const userDoc = await db.collection("users").doc(decoded.uid).get();
        if (userDoc.exists) {
          purchasedThemes = userDoc.data().purchased_themes || [];
          isPremium = userDoc.data().is_premium || false;
        }
      } catch {
        // Token geçersizse sessizce devam et (guest gibi davran)
      }
    }

    // Her temaya "is_unlocked" alanı ekle
    const enriched = themes.map((theme) => ({
      ...theme,
      is_unlocked: !theme.is_premium
        || isPremium
        || purchasedThemes.includes(theme.id),
    }));

    return res.status(200).json({ themes: enriched });
  }
);

// ═══════════════════════════════════════════════════════════════
// 6. AUTH TRIGGER: Yeni kullanıcı profili oluştur
//    Kullanıcı ilk kez kayıt olunca users collection'a ekle
// ═══════════════════════════════════════════════════════════════
exports.createUserProfile = beforeUserCreated(
  { region: "europe-west1" },
  async (event) => {
    const user = event.data;

    await db.collection("users").doc(user.uid).set({
      uid: user.uid,
      email: user.email || "",
      favorites: [],
      purchased_themes: [],
      is_premium: false,
      notification_hour: 9,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[createUserProfile] Yeni kullanıcı profili oluşturuldu: ${user.uid}`);
  }
);
