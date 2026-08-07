/**
 * importProverbs.js
 * ─────────────────────────────────────────────────────────────
 * CSV'deki 400 atasözünü Firestore "proverbs" collection'ına yükler.
 * Tek seferlik çalıştırılır.
 *
 * Kullanım:
 *   1. serviceAccountKey.json dosyasını Backend/ klasörüne koy
 *   2. node scripts/importProverbs.js
 * ─────────────────────────────────────────────────────────────
 */

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
const { parse } = require("csv-parse/sync");

// ─── Firebase Admin başlat ────────────────────────────────────
const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─── CSV oku ─────────────────────────────────────────────────
const csvPath = path.join(__dirname, "../../deyim-ata - veri_seti.csv");
const csvContent = fs.readFileSync(csvPath, "utf-8");

const records = parse(csvContent, {
  columns: true,         // ilk satır header olarak kullanılır
  skip_empty_lines: true,
  trim: true,
});

// ─── theme_tags otomatik etiketle ────────────────────────────
/**
 * Atasözünün başlığına ve anlamına göre basit keyword etiketleme.
 * Manuel olarak da güncellenebilir.
 */
function autoTag(record) {
  const text = `${record.title} ${record.meaning}`.toLowerCase();
  const tags = [];

  if (text.includes("aile") || text.includes("anne") || text.includes("baba") || text.includes("çocuk"))
    tags.push("aile");
  if (text.includes("para") || text.includes("zengin") || text.includes("fakir") || text.includes("para"))
    tags.push("para");
  if (text.includes("arkadaş") || text.includes("dost") || text.includes("komşu"))
    tags.push("dostluk");
  if (text.includes("iş") || text.includes("çalış") || text.includes("emek"))
    tags.push("çalışma");
  if (text.includes("zaman") || text.includes("sabır") || text.includes("bekle"))
    tags.push("sabır");
  if (text.includes("bilgi") || text.includes("öğren") || text.includes("okul") || text.includes("eğitim"))
    tags.push("eğitim");
  if (text.includes("acele") || text.includes("hız"))
    tags.push("acele");
  if (text.includes("doğru") || text.includes("yalan") || text.includes("dürüst"))
    tags.push("dürüstlük");

  return tags.length > 0 ? tags : ["genel"];
}

// ─── Firestore'a yükle ────────────────────────────────────────
async function importProverbs() {
  console.log(`\n📚 ${records.length} kayıt bulundu. Yükleniyor...\n`);

  const BATCH_SIZE = 499; // Firestore max 500/batch
  let batch = db.batch();
  let count = 0;
  let batchCount = 0;

  for (const record of records) {
    const docRef = db.collection("proverbs").doc(String(record.id));

    batch.set(docRef, {
      id: parseInt(record.id),
      type: record.type,               // "Atasözü" veya "Deyim"
      title: record.title,
      meaning: record.meaning,
      example_sentence: record.example_sentence || "",
      theme_tags: autoTag(record),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    count++;

    // Batch dolunca commit et
    if (count % BATCH_SIZE === 0) {
      await batch.commit();
      batchCount++;
      console.log(`  ✅ Batch ${batchCount} commit edildi (${count} kayıt)`);
      batch = db.batch();
    }
  }

  // Kalan kayıtları commit et
  if (count % BATCH_SIZE !== 0) {
    await batch.commit();
    console.log(`  ✅ Son batch commit edildi (toplam ${count} kayıt)`);
  }

  console.log(`\n🎉 Tamamlandı! ${count} atasözü Firestore'a yüklendi.\n`);
}

importProverbs().catch((err) => {
  console.error("❌ Hata:", err);
  process.exit(1);
});
