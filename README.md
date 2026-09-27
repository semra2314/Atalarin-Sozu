# Ataların Sözü

Ataların Sözü, Türk atasözlerini ve deyimlerini kullanıcıya sunan, mobil uygulama ve Android widget deneyimiyle desteklenen bir projedir. Proje iki ana bileşenden oluşur:

- Android uygulaması: Expo + React Native tabanlı mobil arayüz
- Backend: Firebase tabanlı veri yönetimi ve veri içe aktarma scriptleri

Amaç, kullanıcıya günlük Türkçe atasözleri ve temalar aracılığıyla eğlenceli, anlamlı ve kısa bir deneyim sunmaktır.

## Özellikler

- Günlük atasözleri ve deyimler
- Android ana ekran widget desteği
- Firebase ile veri ve yapılandırma yönetimi
- CSV tabanlı veri aktarım scriptleri
- Genişletilebilir ve modüler proje yapısı

## Teknoloji Yığını

### Mobil Uygulama
- React Native
- Expo
- Expo Router
- Android Widget desteği
- TypeScript

### Backend
- Firebase Firestore
- Firebase Remote Config
- Node.js
- CSV import scriptleri

## Proje Yapısı

```text
Atalarin-Sozu/
├── Backend/
│   ├── functions/
│   ├── scripts/
│   ├── firebase.json
│   ├── firestore.rules
│   ├── package.json
│   ├── package-lock.json
│   └── remoteconfig.json
├── Widgy-Android/
│   ├── app/
│   ├── assets/
│   ├── components/
│   ├── configs/
│   ├── widget/
│   ├── app.json
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
├── deyim-ata - veri_seti.csv
├── benzer uygulamalar.pptx
├── .gitignore
└── README.md
```

## Backend Kurulumu

1. Gerekli bağımlılıkları kurun:

```bash
cd Backend
npm install
```

2. Veri aktarım scriptlerini çalıştırın:

```bash
npm run import:proverbs
npm run import:themes
```

3. Firestore kurallarını dağıtın:

```bash
npm run deploy:rules
```

> Backend için Firebase projesi yapılandırması yapılmış olmalıdır.

## Mobil Uygulama Kurulumu

1. Klasöre geçin:

```bash
cd Widgy-Android
npm install
```

2. Uygulamayı başlatın:

```bash
npx expo start
```

3. Android cihaz/emülatör için:

```bash
npm run android
```

## Veri Seti

Projenin veri kaynakları arasında `deyim-ata - veri_seti.csv` dosyası yer almaktadır. Bu dosya, atasözleri ve ilgili içeriklerin içe aktarılması için kullanılmaktadır.

## Katkı Sağlama

Katkı yapmak isterseniz:

1. Repoyu forklayın
2. Yeni bir branch oluşturun
3. Değişikliklerinizi yapın
4. Pull request oluşturun

## Lisans

Bu proje için özel lisans durumu belirtilmemiştir. Kullanım ve dağıtım için repository sahibinin tercihlerini kontrol edin.

## Geliştirici Notu

Proje, Türk kültüründeki atasözlerini dijital ortamda erişilebilir hale getirmeyi hedefleyerek hem mobil deneyim hem de veritabanı tabanlı içerik yönetimi sunar.
