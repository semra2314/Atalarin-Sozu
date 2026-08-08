# 🇹🇷 Ataların Sözü — Widget Marketplace MVP

> **Telefon ana ekranlarını ve dijital arayüzleri Türk kültürüne dayalı modern ve estetik widget'larla kişiselleştiren ekosistem.**  
> 400 adet TDK onaylı atasözü ve deyim, 5 farklı estetik tema ile Firebase Firestore altyapısı üzerinde hem mobil hem de web platformlarında sunulmaktadır.

---

## 📋 İçindekiler

- [📌 Proje Özellikleri](#-proje-özellikleri)
- [🛠️ Teknoloji Yığını (Tech Stack)](#️-teknoloji-yığını-tech-stack)
- [📂 Proje Dizin Yapısı](#-proje-dizin-yapısı)
- [📊 Firestore Veritabanı Şeması](#-firestore-veritabanı-şeması)
- [🚀 Kurulum ve Çalıştırma Rehberi](#-kurulum-ve-çalıştırma-rehberi)
  - [1️⃣ Backend & Firestore Yapılandırması](#1️⃣-backend--firestore-yapılandırması)
  - [2️⃣ Uygulamayı Çalıştırma (Web / Mobil / Emülatör)](#2️⃣-uygulamayı-çalıştırma-web--mobil--emülatör)
- [🧪 Test Etme & Doğrulama](#-test-etme--doğrulama)
- [❓ Sık Karşılaşılan Hatalar ve Çözümleri (Troubleshooting)](#-sık-karşılaşılan-hatalar-ve-çözümleri-troubleshooting)
- [👥 Takım Görev Dağılımı (MVP)](#-takım-görev-dağılımı-mvp)

---

## 📌 Proje Özellikleri

- 📖 **400 Atasözü ve Deyim Veri Seti:** TDK onaylı atasözleri, anlamları, örnek cümleleri ve kategorileriyle Firestore NoSQL veritabanında saklanır.
- 🎨 **5 Estetik Tema:** 
  - 🆓 **Minimalist Beyaz** (`minimalist_white`) — Ücretsiz
  - 🆓 **Retro Vintage** (`retro_vintage`) — Ücretsiz
  - 💎 **Neon Cyberpunk** (`neon_cyberpunk`) — Premium
  - 💎 **El Yazısı** (`el_yazisi`) — Premium
  - 💎 **Y2K Glitter** (`y2k_glitter`) — Premium
- 📅 **Dinamik Günün Atasözü:** Yılın gününe göre otomatik ve deterministik olarak değişen günün atasözü kartı.
- 🔄 **İnteraktif Test Butonları:** Kart üzerinde yer alan **"Sonraki Gün ➡️"** ve **"Önceki Gün ⬅️"** butonları ile 400 atasözünü canlı olarak deneyimleme imkanı.
- 🔥 **Canlı Firebase Entegrasyonu:** Gerçek zamanlı Firestore veritabanı okuma sorguları ve güvenli erişim kuralları.
- 🌐 **Çoklu Platform Desteği:** Web Tarayıcısı (Chrome/Edge/Safari), Android Telefon (Expo Go) ve Android Emülatör tam desteği.
- 📲 **Android Widget Desteği:** `react-native-android-widget` entegrasyonu ile cihaz ana ekranına eklenebilir native widget yapısı.

---

## 🛠️ Teknoloji Yığını (Tech Stack)

| Katman | Teknoloji / Kütüphane | Açıklama |
|---|---|---|
| **Mobil & Web (Frontend)** | React Native, Expo 54, TypeScript | Cross-platform uygulama geliştirme |
| **Yönlendirme & Sayfalar** | Expo Router | Dosya tabanlı sayfa yönlendirme (`app/`) |
| **Veritabanı (Backend)** | Firebase Cloud Firestore | Bulut NoSQL veritabanı |
| **Güvenlik** | Firestore Security Rules | Koleksiyon erişim kısıtlamaları |
| **Veri Yükleme & Test** | Node.js, Firebase Admin SDK | CSV ayrıştırma ve veri toplu aktarımı |
| **Native Widget** | `react-native-android-widget` | Android ana ekran widget desteği |

---

## 📂 Proje Dizin Yapısı

```text
Atalarin-Sozu/
├── Backend/                      # Firebase veritabanı & yükleme scriptleri
│   ├── scripts/
│   │   ├── importProverbs.js    # 400 atasözünü Firestore'a toplu yükler
│   │   ├── importThemes.js      # 5 temayı Firestore'a yükler
│   │   └── testConnection.js    # Firestore canlı bağlantı test scripti
│   ├── firestore.rules          # Firestore güvenlik ve erişim kuralları
│   ├── remoteconfig.json        # Remote Config varsayılan parametreleri
│   ├── package.json             # Backend bağımlılıkları ve komutları
│   └── firebase.json            # Firebase CLI konfigürasyonu
│
├── Widgy-Android/                # React Native / Expo Uygulaması (Android & Web)
│   ├── app/                     # Expo Router sayfaları ((tabs), index, market vb.)
│   ├── components/              # UI Bileşenleri (HeroCard, WidgetCanvas vb.)
│   ├── configs/                 # Firebase Yapılandırması ve Veri Servisi
│   │   ├── firebaseConfig.ts    # Firebase JS SDK istemci konfigürasyonu
│   │   └── proverbService.ts    # Firestore CRUD ve sorgu fonksiyonları
│   ├── widget/                  # Android Native Widget kodları ve task handler
│   └── package.json             # Frontend bağımlılıkları
│
└── deyim-ata - veri_seti.csv     # 400 satırlık orijinal TDK atasözü veri seti
```

---

## 📊 Firestore Veritabanı Şeması

### 1. `proverbs` Koleksiyonu (Doküman ID: `1`, `2`, ..., `400`)
```json
{
  "id": 1,
  "type": "Atasözü",
  "title": "Ağaç yaşken eğilir.",
  "meaning": "İnsanlar küçük yaşta kolayca eğitilirler.",
  "example_sentence": "Çocuğuna yabancı dili şimdi öğretmelisin, sonuçta ağaç yaşken eğilir.",
  "theme_tags": ["eğitim", "gençlik"],
  "created_at": "2026-08-07T14:00:00Z"
}
```

### 2. `themes` Koleksiyonu (Doküman ID: `minimalist_white`, `neon_cyberpunk`, vb.)
```json
{
  "id": "minimalist_white",
  "name": "Minimalist Beyaz",
  "is_premium": false,
  "colors": {
    "background": "#FFFFFF",
    "text": "#1A1A1A",
    "accent": "#3B82F6"
  },
  "font_family": "SF Pro Display",
  "layout_style": "centered",
  "sort_order": 1
}
```

---

## 🚀 Kurulum ve Çalıştırma Rehberi

### Ön Gereksinimler

- [Node.js](https://nodejs.org/) (v18 veya üzeri)
- Terminal (PowerShell, CMD veya Bash)
- *(İsteğe Bağlı)* Mobil test için [Expo Go](https://play.google.com/store/apps/details?id=host.exp.exponent) uygulaması

---

### 1️⃣ Backend & Firestore Yapılandırması

#### a) Bağımlılıkları Yükleme
```powershell
cd Backend
npm install
```

#### b) Doğrudan Bağlantı Testi Çalıştırma
Firebase Firestore veritabanındaki verileri doğrulamak için:
```powershell
node scripts/testConnection.js
```
*Beklenen Çıktı:* `400 atasözü ve 5 temanın erişilebilir olduğu doğrulanır.`

#### c) Verileri Sıfırdan Yüklemek İsterseniz (Opsiyonel)
```powershell
npm run import:themes     # 5 temayı aktarır
npm run import:proverbs    # 400 atasözünü aktarır
npx firebase-tools deploy --only firestore:rules --project widgyy-20  # Güvenlik kurallarını yükler
```

---

### 2️⃣ Uygulamayı Çalıştırma (Web / Mobil / Emülatör)

> ⚠️ **ÖNEMLİ:** Uygulama komutlarını çalıştırmadan önce **`Widgy-Android`** klasöründe olduğunuzdan emin olun.

```powershell
cd C:\Users\semra\Desktop\Atalarin-Sozu\Widgy-Android
```

İhtiyacınıza göre aşağıdaki 3 yöntemden birini seçebilirsiniz:

---

#### 🌐 Yöntem A: Web Tarayıcısında Çalıştırma (Önerilen - En Hızlı)

Telefona veya emülatöre ihtiyaç duymadan doğrudan tarayıcıda çalıştırmak için:

```powershell
npx expo start --web
```
*Uygulama derlendikten sonra otomatik olarak varsayılan tarayıcınızda (örn. `http://localhost:8081`) açılır.*

> 💡 **Alternatif:** Normal `npx expo start` çalışırken terminal ekranında klavyeden **`w`** tuşuna basarak da web arayüzünü açabilirsiniz.

---

#### 📱 Yöntem B: Android Telefonda Çalıştırma (Expo Go İle)

1. Telefonunuza **Expo Go** uygulamasını yükleyin.
2. Terminalde geliştirme sunucusunu başlatın:
   ```powershell
   npx expo start
   ```
3. Ekranınızda beliren **QR kodunu** Expo Go uygulamasındaki tarayıcı ile okutun.
4. *Not:* Telefon ve bilgisayarınız aynı Wi-Fi ağına bağlı olmalıdır. Farklı ağlardaysanız:
   ```powershell
   npx expo start --tunnel
   ```

---

#### 🤖 Yöntem C: Android Emülatörde Çalıştırma (Android Studio)

1. Android Studioüzerinden sanal bir cihaz (AVD) başlatın.
2. Terminalde uygulamayı başlatın:
   ```powershell
   npx expo start
   ```
3. Terminal aktifken klavyeden **`a`** tuşuna basın. Uygulama emülatöre otomatik olarak yüklenecektir.

---

## 🧪 Test Etme & Doğrulama

1. **Günün Atasözü Testi:**
   - Ana sayfadaki turuncu kartta bugünün atasözü gösterilir.
   - Kartın altındaki **"Sonraki Gün ➡️"** butonuna basarak `ID: #1` ile `#400` arasındaki tüm atasözlerinin Firestore'dan canlı olarak yüklenişini test edebilirsiniz.

2. **Tema Mağazası Testi:**
   - Alt menüden **"Market"** (Tema Mağazası) sekmesine geçin.
   - Firestore'da tanımlı olan 5 temanın (Minimalist Beyaz, Retro Vintage, Neon Cyberpunk vb.) kartlarını, özel arka plan renklerini ve `ÜCRETSİZ` / `PREMIUM` rozetlerini inceleyebilirsiniz.
   - Üstteki kategori butonları ile filtreleme yapabilirsiniz.

---

## ❓ Sık Karşılaşılan Hatalar ve Çözümleri (Troubleshooting)

### 1. `ConfigError: The expected package.json path ... does not exist`
- **Nedeni:** `npx expo start` komutunun projenin kök dizininde (`Atalarin-Sozu`) çalıştırılması.
- **Çözüm:** Klasör değiştirmelisiniz:
  ```powershell
  cd Widgy-Android
  npx expo start --web
  ```

### 2. `Error: Cannot find module 'firebase-admin'`
- **Nedeni:** Backend klasöründeki bağımlılıkların henüz yüklenmemiş olması.
- **Çözüm:**
  ```powershell
  cd Backend
  npm install
  ```

### 3. `PERMISSION_DENIED: Cloud Firestore API has not been used`
- **Nedeni:** Firestore veritabanının Firebase Console üzerinde henüz ilk kez başlatılmamış olması.
- **Çözüm:** [Firebase Console](https://console.firebase.google.com) -> `widgyy-20` projesi -> **Firestore Database** -> **Create Database** adımlarını izleyin.

---

## 👥 Takım Görev Dağılımı (MVP)

- **Semra (PM & Backend):** Firebase mimarisi, Firestore NoSQL veritabanı tasarımı, güvenlik kuralları, veri aktarım ve test scriptleri.
- **Joaquin (Frontend Developer):** Expo / React Native arayüzleri, tema şablonları, WidgetKit & Android Widget entegrasyonu.
- **Erden (UI/UX Tasarımcı):** Tema renk paletleri, görsel tasarımlar ve marka kimliği.

---

## 📄 Lisans

Bu proje Ataların Sözü Widget Marketplace MVP (Minimum Viable Product) kapsamında geliştirilmiştir.
