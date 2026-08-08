# 🔥 Ataların Sözü — Backend Kurulum ve Kullanım Rehberi

## 📂 Klasör Yapısı

```
Backend/
├── firebase.json          ← Firebase CLI config
├── firestore.rules        ← Güvenlik kuralları
├── remoteconfig.json      ← Remote Config şablonu
├── package.json           ← Import scriptleri için bağımlılıklar
├── serviceAccountKey.json ← ⚠️ GİZLİ — Firebase'den indirilecek, git'e ekleme!
│
├── scripts/
│   ├── importProverbs.js  ← 400 atasözünü Firestore'a yükler
│   └── importThemes.js    ← 5 temayı Firestore'a yükler
│
└── functions/
    ├── package.json       ← Cloud Functions bağımlılıkları
    └── index.js           ← Tüm Cloud Functions (5 adet)
```

---

## 🚀 Kurulum Adımları (Sırayla Yap)

### Adım 1: Firebase CLI kur

```powershell
npm install -g firebase-tools
firebase login
```

### Adım 2: Projeyi Firebase'e bağla

```powershell
cd c:\Users\semra\Desktop\Atalarin-Sozu\Backend
firebase use --add
# "atalarin-sozu-mvp" projesini seç
```

### Adım 3: serviceAccountKey.json indir

1. [Firebase Console](https://console.firebase.google.com) → Proje Ayarları
2. **Hizmet Hesapları** sekmesi
3. **Yeni özel anahtar oluştur** → JSON indir
4. `Backend/serviceAccountKey.json` olarak kaydet
5. `.gitignore`'a eklediğinden emin ol!

### Adım 4: Bağımlılıkları kur

```powershell
# Backend/ klasöründeyken
npm install

# functions/ klasörü için
cd functions
npm install
cd ..
```

### Adım 5: Veriyi yükle

```powershell
# 400 atasözünü Firestore'a yükle
npm run import:proverbs

# 5 temayı Firestore'a yükle
npm run import:themes
```

### Adım 6: Güvenlik kurallarını deploy et

```powershell
firebase deploy --only firestore:rules
```

### Adım 7: Cloud Functions'ı deploy et

> ⚠️ Blaze Plan gerekli (Cloud Functions için)

```powershell
firebase deploy --only functions
```

### Adım 8: Remote Config'i deploy et

```powershell
firebase deploy --only remoteconfig
```

---

## ✅ Verify Adımları

### Firestore'da veri var mı kontrol et:
- Firebase Console → Firestore → `proverbs` collection → 400 belge olmalı
- Firebase Console → Firestore → `themes` collection → 5 belge olmalı

### Cloud Function URL'lerini al:
- Firebase Console → Functions → dashboard'da URL'ler görünür
- Joaquin'e bu URL'leri ver

### Daily proverb manuel test:
```powershell
# Function URL'ini al, tarayıcıda aç:
https://europe-west1-PROJE_ID.cloudfunctions.net/getDailyProverb
```

---

## ⚠️ Önemli Notlar

- `serviceAccountKey.json` asla git'e push etme! `.gitignore`'a ekli.
- Cloud Functions için Blaze Plan (kredi kartı) gerekiyor ama ilk 2M istek/ay ücretsiz.
- Scheduled function (günlük atasözü) ilk çalışması için Firebase Console → Functions → Manuel tetikle.

---

## 📋 Joaquin'e Verilecekler

Deploy tamamlanınca şunları Joaquin'e ilet:

| Bilgi | Nasıl Alınır |
|-------|-------------|
| `google-services.json` | Firebase Console → Proje Ayarları → Android uygulaması |
| `GoogleService-Info.plist` | Firebase Console → Proje Ayarları → iOS uygulaması |
| `getDailyProverb` URL | Firebase Console → Functions |
| `addFavorite` URL | Firebase Console → Functions |
| `removeFavorite` URL | Firebase Console → Functions |
| `getThemes` URL | Firebase Console → Functions |
| Firestore collection adları | Bu README |
| Analytics event listesi | `implementation_plan.md` |
