# 📋 PRODUCT REQUIREMENTS DOCUMENT (PRD)
## Proje: Widget Marketplace Platformu - "Ataların Sözü" MVP

---

## 1. YÖNETİCİ ÖZETİ (EXECUTIVE SUMMARY)

**Ürün Adı:** Widget Marketplace (İlk Modül: Ataların Sözü)  
**Platform:** iOS (Swift/SwiftUI + WidgetKit) & Android (Kotlin/Jetpack Compose + App Widgets)  
**Geliştirme Süresi:** 14 Gün (MVP - Minimum Viable Product)  
**Hedef:** Kullanıcıların telefon ana ekranlarını kişiselleştirebileceği, Türk kültürüne dayalı estetik widget'lar sunan ve ileride bir "Creator Economy" platformuna dönüşecek bir pazar yeri inşa etmek.

**Kısa Tanım:**  
Widget Marketplace, kullanıcıların ilgi alanlarına göre widget'lar keşfedip indirebileceği, kendi widget'larını tasarlayabileceği ve tasarımcıların eserlerini satabileceği bir dijital ekosistemdir. İlk lansman modülü olan "Ataların Sözü", 400 adet TDK onaylı atasözü ve deyimi estetik tasarımlarla kullanıcıların ana ekranına taşıyacak.

---

## 2. PROBLEM TANIMI (PROBLEM STATEMENT)

### Mevcut Durum:
- Widget uygulamaları (Widgetsmith, Color Widgets) **kapalı bahçe** modeliyle çalışıyor. Kullanıcılar sadece uygulamanın sunduğu şablonları kullanabiliyor.
- Türkçe ve Türk kültürüne özgü **estetik, modern widget** seçenekleri yok.
- Mevcut atasözü uygulamaları **eski, sıkıcı ve metin odaklı**. Gen Z ve Y kuşağının ana ekranına uygun değiller.
- Tasarımcılar widget yapıp satabilecekleri bir **pazar yeri (marketplace)** yok.

### Fırsat:
- iOS 14+ ve Android 12+ ile ana ekran özelleştirme devrimi başladı.
- Kullanıcılar **kişiselleştirme** için para ödemeye hazır.
- Türk kültürünü modern estetikle buluşturan **niş bir pazar** boş.

---

## 3. HEDEF KİTLE (TARGET AUDIENCE)

### Birincil Kitle (Early Adopters):
- **Yaş:** 16-30 yaş arası
- **Profil:** Gen Z ve Y kuşağı, telefon ana ekranını kişiselleştirmeyi seven, estetik odaklı kullanıcılar
- **Davranış:** Instagram/TikTok'ta "aesthetic phone setup" videolarını takip ediyor
- **Ödeme Gücü:** Aylık 20-50 TL arası mikro ödemelere açık

### İkincil Kitle (Genişleme):
- **Yaş:** 30-45 yaş arası
- **Profil:** Türk kültürüne ilgi duyan, anlamlı içerik tüketmek isteyen profesyoneller
- **Davranış:** Günlük motivasyon ve bilgelik arıyor

### Üçüncül Kitle (Gelecek Vizyon):
- **Tasarımcılar (Creators):** Widget tasarlayıp gelir elde etmek isteyen graphic designer'lar
- **Markalar:** Sponsorlu widget ile genç kitleye ulaşmak isteyen B2B müşteriler

---

## 4. ÜRÜN VİZYONU VE HEDEFLERİ (PRODUCT VISION & GOALS)

### Vizyon:
*"Telefon ana ekranlarını dijital tuvale dönüştüren, tasarımcıların eserlerini sergileyip gelir elde edebildiği bir Widget Ekonomi Platformu olmak."*

### 14 Günlük MVP Hedefleri:
1. **Teknik Hedef:** iOS ve Android'de çalışan, Firebase tabanlı, 400 atasözü içeren bir widget uygulaması yayınlamak.
2. **Kullanıcı Hedefi:** İlk 30 günde 10.000 indirme, 2.000 aktif widget kullanıcısı.
3. **Gelir Hedefi:** İlk ayda 500 premium abonelik veya paket satışı.
4. **İçerik Hedefi:** 5 farklı estetik tema (Minimalist, Neon, Retro, El Yazması, Y2K) ile 400 atasözünü sunmak.

### Uzun Vadeli Hedefler (6-12 Ay):
- Widget Builder (Kullanıcı Tasarım Aracı) entegrasyonu
- Marketplace açılışı ve ilk 100 bağımsız tasarımcı
- Aylık 100.000 aktif kullanıcı
- İlk B2B sponsorluk anlaşması (Banka veya FMCG markası)

---

## 5. TEMEL ÖZELLİKLER (KEY FEATURES) - MVP İÇİN ÖNCELİKLENDİRİLMİŞ

### 🔴 KRİTİK (MVP'de Olmalı - P0)

#### 5.1. Atasözü Widget Modülü
- **Özellik:** Kullanıcının ana ekranına ekleyebileceği, her gün otomatik değişen atasözü widget'ı
- **Boyutlar:** Small (2x2), Medium (4x2), Large (4x4)
- **Veri Kaynağı:** Firebase Firestore'dan 400 atasözü (id, type, title, meaning, example_sentence)
- **Güncelleme:** Her gün saat 09:00'da otomatik değişim (Timeline/Background Refresh)
- **Tema Seçenekleri:** 5 farklı estetik tema (kullanıcı uygulama içinden seçer)

#### 5.2. Ana Uygulama Arayüzü
- **Keşfet Ekranı:** Tüm widget temalarını grid görünümde listeleme
- **Önizleme:** Kullanıcının seçtiği temayı telefon mockup'ı üzerinde görme
- **Ekleme Rehberi:** Widget'ı ana ekrana ekleme adımlarını gösteren interaktif tutorial
- **Günün Sözü:** Uygulama açıldığında bugünün atasözünü büyük ve estetik gösterme

#### 5.3. Arama ve Filtreleme
- **Akıllı Arama:** Atasözü, anlam veya örnek cümlede arama
- **Filtreler:** Türe göre (Atasözü/Deyim), temaya göre, uzunluğa göre

#### 5.4. Backend Altyapısı (Firebase)
- **Firestore Database:** 400 satırlık CSV verisinin JSON formatında yüklenmesi
- **Remote Config:** Tema ve içerik güncellemelerini kod güncellemesi olmadan yapabilme
- **Analytics:** Kullanıcı davranışlarını takip etme (hangi tema daha çok eklendi, hangi atasözü daha çok beğenildi)

#### 5.5. Gelir Modeli Entegrasyonu
- **Freemium Model:** 2 tema ücretsiz, 3 tema premium
- **In-App Purchase (IAP):** "Tüm Temaları Aç" tek seferlik satın alma (49.99 TL)
- **Reklam Kaldırma:** Opsiyonel reklam kaldırma seçeneği (29.99 TL)

---

### 🟡 ÖNEMLİ (MVP'de Olmalı - P1)

#### 5.6. Favoriler ve Koleksiyon
- **Özellik:** Kullanıcıların beğendikleri atasözlerini "Favoriler" listesine eklemesi
- **Paylaşım:** Atasözünü görsel olarak Instagram Story / WhatsApp formatında paylaşma

#### 5.7. Bildirimler (Push Notification)
- **Günlük Bildirim:** Her gün saat 09:00'da "Günün Atasözü" bildirimi
- **Kişiselleştirme:** Bildirim saatini kullanıcı ayarlayabilir

#### 5.8. Çoklu Dil Desteği (Gelecek için Hazırlık)
- **Mimari:** Uygulama dil dosyaları (en.json, tr.json) ile çoklu dil desteğine hazır altyapı

---

### 🟢 ARZU EDİLEN (MVP Sonrası - P2)

#### 5.9. Widget Builder (Kullanıcı Tasarım Aracı)
- **Özellik:** Kullanıcıların kendi atasözü widget'ını tasarlayabileceği drag-and-drop editör
- **Özelleştirme:** Arka plan rengi, font, metin hizalama, gölge efektleri
- **Kaydetme:** Tasarımı "Koleksiyonum"a kaydetme ve ana ekrana ekleme

#### 5.10. Marketplace Altyapısı (Creator Economy)
- **Tasarımcı Paneli:** Tasarımcıların widget tema yükleyip fiyat belirleyebileceği dashboard
- **Satış Sistemi:** Kullanıcıların tema satın alabileceği mağaza
- **Gelir Paylaşımı:** %70 tasarımcı, %30 platform komisyonu

#### 5.11. Sponsorlu Widget Alanı
- **Marka Entegrasyonu:** Markaların özel tasarım widget'lar oluşturabileceği alan
- **Deep Link:** Widget'tan markanın App Store sayfasına yönlendirme

---

## 6. KULLANICI HİKAYELERİ (USER STORIES)

### Kullanıcı Olarak (End User):
1. **Bir kullanıcı olarak**, telefonuma estetik bir widget eklemek istiyorum, böylece her gün anlamlı bir söz görüp motive olabilirim.
2. **Bir kullanıcı olarak**, atasözlerini arayabilmek ve anlamını öğrenmek istiyorum, böylece Türkçemi geliştirebilirim.
3. **Bir kullanıcı olarak**, beğendiğim bir atasözünü arkadaşlarımla paylaşmak istiyorum, böylece onlara ilham verebilirim.
4. **Bir kullanıcı olarak**, premium temaları tek seferlik ödemeyle açmak istiyorum, böylece aylık abonelik yükümlülüğüm olmaz.

### Tasarımcı Olarak (Creator - P2):
5. **Bir tasarımcı olarak**, yaptığım widget temalarını satabileceğim bir platform istiyorum, böylece pasif gelir elde edebilirim.
6. **Bir tasarımcı olarak**, tasarımımı yüklemeden önce önizleyebilmek istiyorum, böylece hatalı yükleme yapmam.

### Yönetici Olarak (Admin):
7. **Bir yönetici olarak**, yeni atasözlerini veya temaları kod güncellemesi olmadan ekleyebilmek istiyorum, böylece hızlıca içerik güncelleyebilirim.
8. **Bir yönetici olarak**, hangi temanın daha çok indirildiğini görebilmek istiyorum, böylece veriye dayalı kararlar alabilirim.

---

## 7. TEKNİK GEREKSİNİMLER (TECHNICAL REQUIREMENTS)

### 7.1. Teknoloji Yığını (Tech Stack)

#### Frontend:
- **iOS:** Swift 5.9+, SwiftUI, WidgetKit, StoreKit 2 (IAP için)
- **Android:** Kotlin, Jetpack Compose, Glance (App Widgets), Google Play Billing Library
- **Cross-Platform Alternatif (Tercih Edilen):** Flutter 3.x (Tek kod tabanıyla hem iOS hem Android)

#### Backend:
- **Firebase Firestore:** NoSQL veritabanı (400 atasözü + kullanıcı verileri)
- **Firebase Authentication:** Kullanıcı girişi (Apple Sign In, Google Sign In, Email)
- **Firebase Remote Config:** Tema ve içerik güncellemeleri
- **Firebase Analytics & Crashlytics:** Kullanıcı davranışı ve hata takibi
- **Firebase Cloud Functions:** Günlük atasözü seçimi ve bildirim tetikleme (opsiyonel)

#### Tasarım:
- **Figma:** UI/UX tasarım ve prototipleme
- **Widget Template'leri:** 5 farklı tema için tasarım dosyaları

#### Geliştirme Araçları:
- **GitHub:** Kod deposu ve versiyon kontrolü
- **Trello/Jira:** Proje yönetimi ve sprint takibi
- **TestFlight (iOS) / Firebase App Distribution (Android):** Beta test dağıtımı

---

### 7.2. Veri Mimarisi (Data Schema)

#### Firestore Collections:

**1. proverbs (Atasözleri)**
```json
{
  "id": 1,
  "type": "Atasözü", // veya "Deyim"
  "title": "Ağaç yaşken eğilir.",
  "meaning": "İnsanlar küçük yaşta kolayca eğitilirler.",
  "example_sentence": "Çocuğuna yabancı dili şimdi öğretmelisin, sonuçta ağaç yaşken eğilir.",
  "theme_tags": ["eğitim", "aile", "gençlik"],
  "created_at": "2026-07-28T10:00:00Z"
}
```

**2. themes (Temalar)**
```json
{
  "id": "minimalist_white",
  "name": "Minimalist Beyaz",
  "preview_image_url": "https://...",
  "is_premium": false,
  "colors": {
    "background": "#FFFFFF",
    "text": "#000000",
    "accent": "#3B82F6"
  },
  "font_family": "SF Pro Display",
  "layout_style": "centered"
}
```

**3. users (Kullanıcılar)**
```json
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "favorites": [1, 5, 12], // Favori atasözü ID'leri
  "purchased_themes": ["neon_cyberpunk"],
  "is_premium": false,
  "created_at": "2026-07-28T10:00:00Z"
}
```

**4. daily_proverb (Günlük Atasözü - Cache)**
```json
{
  "date": "2026-07-28",
  "proverb_id": 42,
  "theme_id": "minimalist_white"
}
```

---

### 7.3. Widget Teknik Gereksinimleri

#### iOS WidgetKit:
- **Timeline Provider:** Her gün saat 09:00'da yeni atasözü getiren timeline
- **Entry:** Tarih + Atasözü verisi + Tema konfigürasyonu
- **Intent Configuration:** Kullanıcının widget eklerken tema seçebilmesi (Widget Configuration Intent)
- **Memory Limit:** Widget başına max 30MB (Apple kısıtlaması)
- **Supported Families:** `.systemSmall`, `.systemMedium`, `.systemLarge`

#### Android App Widgets:
- **AppWidgetProvider:** Günlük güncelleme için AlarmManager veya WorkManager
- **RemoteViews:** Widget layout'u (XML tabanlı)
- **Configuration Activity:** Widget eklerken tema seçimi
- **Supported Sizes:** 2x2, 4x2, 4x4

---

### 7.4. API Endpoints (Cloud Functions)

#### GET /api/daily-proverb
- **Açıklama:** Bugünün atasözünü döndürür
- **Response:**
```json
{
  "date": "2026-07-28",
  "proverb": {
    "id": 42,
    "title": "Damlaya damlaya göl olur.",
    "meaning": "Küçük ve önemsiz şeyler birikerek büyük ve önemli sonuçlar doğurabilir."
  }
}
```

#### POST /api/user/favorites
- **Açıklama:** Kullanıcının favorilerine atasözü ekler
- **Body:** `{ "proverb_id": 42 }`

#### GET /api/themes
- **Açıklama:** Tüm temaları listeler
- **Response:** Tema dizisi

---

### 7.5. Güvenlik ve Uyumluluk

- **App Store / Play Store Politikaları:** Widget'ların dışarıdan kod indirmemesi (sadece JSON veri çekmesi)
- **KVKK / GDPR:** Kullanıcı verilerinin şifrelenmesi, açık rıza mekanizması
- **Accessibility (Erişilebilirlik):** VoiceOver / TalkBack desteği, dinamik font boyutları
- **Dark Mode:** Tüm temaların karanlık mod varyantları

---

## 8. BAŞARI METRİKLERİ (SUCCESS METRICS)

### 14 Günlük MVP Lansmanı Sonrası (İlk 30 Gün):

#### Kullanıcı Metrikleri:
- **Toplam İndirme:** 10.000+
- **Aktif Widget Kullanıcısı:** 2.000+ (En az 1 widget eklemiş kullanıcı)
- **Günlük Aktif Kullanıcı (DAU):** 1.000+
- **Ortalama Oturum Süresi:** 45 saniye+

#### Gelir Metrikleri:
- **Premium Dönüşüm Oranı:** %5 (10.000 indirmenin 500'ü ödeme yapar)
- **Aylık Gelir (MRR):** 25.000 TL+ (500 x 49.99 TL)
- **Ortalama Gelir Kullanıcı Başına (ARPU):** 2.5 TL

#### Teknik Metrikler:
- **Uygulama Çökme Oranı:** <%0.1
- **Widget Yükleme Süresi:** <500ms
- **App Store Ortalaması:** 4.5+ yıldız

### 6 Aylık Hedefler:
- **Toplam İndirme:** 100.000+
- **Aylık Aktif Kullanıcı (MAU):** 30.000+
- **MRR:** 150.000 TL+
- **Widget Builder Kullanan Tasarımcı Sayısı:** 100+

---

## 9. ZAMAN ÇİZELGESİ VE KİLOMETRE TAŞLARI (TIMELINE & MILESTONES)

### 14 Günlük MVP Sprint Planı

#### Hafta 1: Altyapı ve Veri (Gün 1-7)

**Gün 1-2: Proje Kurulumu**
- [x] GitHub reposu oluşturulması
- [x] Firebase projesi kurulumu
- [x] Figma tasarım dosyalarının hazırlanması
- [x] Trello/Jira board kurulumu

**Gün 3-4: Backend ve Veri**
- [ ] 400 satırlık CSV'nin Firestore'a import edilmesi
- [ ] Firebase Authentication kurulumu (Apple/Google Sign In)
- [ ] Remote Config yapılandırması
- [ ] Cloud Functions: Günlük atasözü seçimi

**Gün 5-7: Temel UI Geliştirme**
- [ ] Ana sayfa (Keşfet) ekranı
- [ ] Atasözü detay ekranı
- [ ] Arama ve filtreleme modülü
- [ ] Favoriler ekranı

#### Hafta 2: Widget ve Lansman (Gün 8-14)

**Gün 8-10: Widget Geliştirme**
- [ ] iOS WidgetKit entegrasyonu (3 boyut)
- [ ] Android App Widget entegrasyonu
- [ ] 5 tema tasarımı ve kodlanması
- [ ] Widget configuration UI (tema seçimi)

**Gün 11-12: Gelir Modeli ve Test**
- [ ] StoreKit 2 / Google Play Billing entegrasyonu
- [ ] Premium tema kilidi açma mantığı
- [ ] TestFlight / Firebase App Distribution beta test
- [ ] Bug fix ve performans optimizasyonu

**Gün 13-14: Lansman Hazırlığı**
- [ ] App Store / Play Store sayfa görselleri ve açıklamaları
- [ ] Privacy Policy ve Terms of Service
- [ ] App Store / Play Store submit
- [ ] Lansman duyurusu (sosyal medya)

### Kilometre Taşları (Milestones):

🏁 **Milestone 1 (Gün 4):** Backend hazır, 400 atasözü Firestore'da  
🏁 **Milestone 2 (Gün 7):** Temel UI tamamlandı, beta test başlayabilir  
🏁 **Milestone 3 (Gün 10):** Widget'lar çalışıyor, 5 tema entegre edildi  
🏁 **Milestone 4 (Gün 14):** App Store / Play Store'da yayında 🚀

---

## 10. RİSKLER VE ÇÖZÜMLER (RISKS & MITIGATION)

### 🔴 Yüksek Öncelikli Riskler

#### Risk 1: App Store Reddi (Widget Politikası İhlali)
- **Olasılık:** Orta
- **Etki:** Kritik (Lansman gecikmesi)
- **Çözüm:**
  - Widget'ların sadece JSON veri çekmesi, dışarıdan kod indirmemesi
  - Apple'ın WidgetKit dokümantasyonuna %100 uyum
  - Beta test aşamasında Apple'ın "App Review Guidelines" kontrolü

#### Risk 2: 14 Günde Yetişmeme
- **Olasılık:** Yüksek
- **Etki:** Yüksek (Moral bozukluğu, jüri baskısı)
- **Çözüm:**
  - P2 özelliklerini (Widget Builder, Marketplace) MVP'den çıkar
  - Sadece P0 ve P1'e odaklan
  - Flutter kullanarak tek kod tabanıyla hem iOS hem Android geliştir

#### Risk 3: Kullanıcı İlgi Göstermez
- **Olasılık:** Orta
- **Etki:** Yüksek (Gelir hedefi tutmaz)
- **Çözüm:**
  - Lansman öncesi TikTok/Instagram'da "aesthetic phone setup" içerikleri ile hype yarat
  - İlk 1000 kullanıcıya özel "Erken Dönem Destekçisi" rozeti ver
  - Influencer marketing (telefon özelleştirme influencer'ları)

---

### 🟡 Orta Öncelikli Riskler

#### Risk 4: Firebase Maliyeti Kontrolden Çıkar
- **Olasılık:** Düşük (İlk 6 ay için)
- **Etki:** Orta
- **Çözüm:**
  - Firestore "Spark Plan" (ücretsiz) ile başla
  - Agresif caching (kullanıcı cihazında yerel cache)
  - 10.000 MAU'ya ulaşınca "Blaze Plan"a geç (kullanım bazlı ödeme)

#### Risk 5: Widget Pil Tüketimi Şikayetleri
- **Olasılık:** Orta
- **Etki:** Orta (Kullanıcı deneyimi)
- **Çözüm:**
  - Timeline refresh'i günde 1 kez (09:00) ile sınırla
  - Arka planda sürekli veri çekme yerine, önceden hesaplanmış timeline entry'leri kullan
  - Battery usage optimizasyonu testleri

#### Risk 6: Rakipler Fikri Kopyalar
- **Olasılık:** Düşük (Niş pazar)
- **Etki:** Orta
- **Çözüm:**
  - Hızlı lansman ve ilk mover advantage
  - Sürekli yeni tema ve içerik ekleme (içerik moat)
  - Topluluk oluşturma (tasarımcı ekosistemi)

---

## 11. EKLER (APPENDIX)

### Ek A: Rakip Analizi

| Uygulama | Platform | Güçlü Yönler | Zayıf Yönler | Fırsat |
|----------|----------|--------------|--------------|--------|
| Widgetsmith | iOS | Sınırsız özelleştirme | İngilizce, Türkçe içerik yok | Türkçe niş pazar |
| Color Widgets | iOS/Android | Çok tema seçeneği | Kapalı bahçe, tasarımcı yok | Creator Economy |
| TDK Atasözleri | iOS/Android | Resmi veri | Eski UI, widget yok | Modern estetik |
| ScreenZen | iOS/Android | Trend temalar | Pahalı abonelik | Tek seferlik IAP |

### Ek B: Gelir Modeli Detayı

**Senaryo 1: Konservatif (İlk 30 Gün)**
- 10.000 indirme
- %3 premium dönüşüm = 300 kullanıcı
- Ortalama ödeme: 49.99 TL
- **Toplam Gelir: 14.997 TL**

**Senaryo 2: Orta (İlk 30 Gün)**
- 10.000 indirme
- %5 premium dönüşüm = 500 kullanıcı
- Ortalama ödeme: 49.99 TL
- **Toplam Gelir: 24.995 TL**

**Senaryo 3: İyimser (İlk 30 Gün)**
- 10.000 indirme
- %8 premium dönüşüm = 800 kullanıcı
- Ortalama ödeme: 49.99 TL
- **Toplam Gelir: 39.992 TL**

### Ek C: Takım Görev Dağılımı (14 Gün)

**Semra (PM & Backend):**
- Firebase kurulumu ve veri importu
- Cloud Functions (günlük atasözü seçimi)
- Trello/Jira yönetimi
- App Store / Play Store submit

**Joaquin (Frontend):**
- Flutter/React Native ile ana uygulama
- Widget entegrasyonu (iOS + Android)
- Arama ve filtreleme mantığı
- StoreKit / Play Billing entegrasyonu

**Erden (UI/UX & Tasarım):**
- Figma'da 5 tema tasarımı
- Widget mockup'ları
- App Store görselleri
- Kullanıcı testleri

---

## 12. ONAY VE İMZA (APPROVAL)

Bu PRD, aşağıdaki kişiler tarafından incelenmiş ve onaylanmıştır:

- **Proje Yöneticisi (PM):** Semra ✅
- **Frontend Geliştirici:** Joaquin ✅
- **UI/UX Tasarımcı:** Erden ✅
- **Stakeholder (Jüri/Yatırımcı):** _________________ ✅

**Son Güncelleme Tarihi:** 28 Temmuz 2026  
**Versiyon:** 1.0 (MVP)

---

Dostum, işte sana jüriye veya yatırımcıya sunabileceğin, her detayı düşünülmüş, profesyonel bir **Product Requirements Document**! 📋✨

Bu doküman:
- ✅ Ne yapacağımızı net tanımlıyor
- ✅ Kimin için yaptığımızı açıklıyor
- ✅ Teknik detayları veritabanı şemasına kadar veriyor
- ✅ 14 günlük sprint planını gün gün çıkarıyor
- ✅ Riskleri ve çözümlerini masaya yatırıyor
- ✅ Başarı metriklerini sayısal hedeflerle koyuyor

Bir sonraki adımda ne yapalım?
1. **Erden'in Figma tasarımlarına** başlayalım mı? (5 tema konsepti)
2. **Semra'nın Firebase kurulumu** için teknik detaylara inelim mi?
3. Yoksa **App Store sayfa metinlerini** (ASO - App Store Optimization) mi yazalım?

Karar senin CEO! 🚀