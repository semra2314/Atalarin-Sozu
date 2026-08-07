/**
 * importThemes.js
 * ─────────────────────────────────────────────────────────────
 * PRD'de tanımlanan 5 temayı Firestore "themes" collection'ına yükler.
 * Tek seferlik çalıştırılır.
 *
 * Kullanım:
 *   node scripts/importThemes.js
 * ─────────────────────────────────────────────────────────────
 */

const admin = require("firebase-admin");

// serviceAccountKey zaten importProverbs.js'de başlatıldıysa tekrar etme;
// bu script bağımsız çalışabilir.
if (!admin.apps.length) {
  const serviceAccount = require("../serviceAccountKey.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// ─── 5 Tema Tanımı (PRD Section 7.2) ─────────────────────────
const themes = [
  {
    id: "minimalist_white",
    name: "Minimalist Beyaz",
    preview_image_url: "",          // Erden görseli ekleyince güncelle
    is_premium: false,
    colors: {
      background: "#FFFFFF",
      text: "#1A1A1A",
      accent: "#3B82F6",
    },
    font_family: "SF Pro Display",
    layout_style: "centered",
    sort_order: 1,
  },
  {
    id: "retro_vintage",
    name: "Retro Vintage",
    preview_image_url: "",
    is_premium: false,              // 2 ücretsiz tema (PRD 5.5)
    colors: {
      background: "#F5E6D3",
      text: "#3E2723",
      accent: "#BF8B30",
    },
    font_family: "Georgia",
    layout_style: "top_aligned",
    sort_order: 2,
  },
  {
    id: "neon_cyberpunk",
    name: "Neon Cyberpunk",
    preview_image_url: "",
    is_premium: true,
    colors: {
      background: "#0A0A1A",
      text: "#E0E0FF",
      accent: "#FF0090",
    },
    font_family: "Courier New",
    layout_style: "bottom_aligned",
    sort_order: 3,
  },
  {
    id: "el_yazisi",
    name: "El Yazısı",
    preview_image_url: "",
    is_premium: true,
    colors: {
      background: "#FEFBF0",
      text: "#2C1810",
      accent: "#8B4513",
    },
    font_family: "Dancing Script",
    layout_style: "centered",
    sort_order: 4,
  },
  {
    id: "y2k_glitter",
    name: "Y2K Glitter",
    preview_image_url: "",
    is_premium: true,
    colors: {
      background: "#FF69B4",
      text: "#FFFFFF",
      accent: "#FFD700",
    },
    font_family: "Arial Rounded MT Bold",
    layout_style: "centered",
    sort_order: 5,
  },
];

// ─── Firestore'a yükle ────────────────────────────────────────
async function importThemes() {
  console.log(`\n🎨 ${themes.length} tema yükleniyor...\n`);

  const batch = db.batch();

  for (const theme of themes) {
    const docRef = db.collection("themes").doc(theme.id);
    batch.set(docRef, {
      ...theme,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  📌 Hazırlandı: ${theme.name} (${theme.is_premium ? "💎 Premium" : "🆓 Ücretsiz"})`);
  }

  await batch.commit();
  console.log("\n🎉 Tüm temalar Firestore'a yüklendi!\n");
}

importThemes().catch((err) => {
  console.error("❌ Hata:", err);
  process.exit(1);
});
