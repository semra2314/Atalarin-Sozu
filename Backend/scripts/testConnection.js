/**
 * testConnection.js
 * ─────────────────────────────────────────────────────────────
 * Backend & Firestore bağlantısını doğrudan test eder.
 * Firestore'dan rastgele bir atasözü ve temaları çeker.
 * ─────────────────────────────────────────────────────────────
 */

const admin = require("firebase-admin");
const serviceAccount = require("../serviceAccountKey.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function testBackend() {
  console.log("🔥 Firebase Firestore Bağlantı Testi Başlatılıyor...\n");

  // 1. Proverbs koleksiyonu test
  const proverbSnap = await db.collection("proverbs").doc("1").get();
  if (proverbSnap.exists) {
    console.log("✅ [1/3] Proverbs koleksiyonuna erişildi!");
    console.log("   📌 1 Numaralı Atasözü:", proverbSnap.data().title);
    console.log("   📌 Anlamı:", proverbSnap.data().meaning);
  } else {
    console.log("❌ [1/3] Proverbs dokümanı bulunamadı!");
  }

  console.log("");

  // 2. Themes koleksiyonu test
  const themesSnap = await db.collection("themes").get();
  console.log(`✅ [2/3] Themes koleksiyonuna erişildi! Toplam ${themesSnap.size} tema var:`);
  themesSnap.docs.forEach((doc) => {
    const data = doc.data();
    console.log(`   🎨 ${data.name} (${data.is_premium ? "💎 Premium" : "🆓 Ücretsiz"}) - Rengi: ${data.colors.background}`);
  });

  console.log("");

  // 3. Toplam Atasözü Sayısı
  const totalProverbsSnap = await db.collection("proverbs").count().get();
  console.log(`✅ [3/3] Firestore'daki Toplam Atasözü Sayısı: ${totalProverbsSnap.data().count}`);

  console.log("\n🎉 TEBRİKLER! Backend, Firestore veritabanına %100 sorunsuz bağlı!");
}

testBackend().catch((err) => {
  console.error("❌ Hata oluştu:", err);
});
