# Kare → TestFlight (external) · Çarşamba'dan Cuma'ya

Sunum **Cuma**. External TestFlight, Apple'ın **Beta App Review**'undan geçmek
zorunda ve bu genelde 24-48 saat sürüyor. Yani build'in **bugün** yukarı
çıkması lazım. Bir gün kaybedersen Cuma'ya yetişmez.

Kritik ayrım:

- **Internal testing** — review yok, yükleme biter bitmez kurulabilir. Ama
  sadece App Store Connect'te rolü olan 100 kişiye kadar, ve herkesin senin
  ekibine eklenmesi gerekiyor. Jüriye bunu dağıtamazsın.
- **External testing** — herkese açık link (`testflight.apple.com/join/XXXX`),
  10.000 kişiye kadar. Jürinin okutacağı QR bu. **Review şart.**

---

## 0 · Bugün, ilk yarım saat: kod tarafı

Bu üç şeyi hallettim, senin sadece build alman lazım:

- `Widgy/PrivacyInfo.xcprivacy` ve `actual-widgets/PrivacyInfo.xcprivacy`
  eklendi. Uygulama `@AppStorage`/`UserDefaults` kullanıyor, bu "required
  reason API" — manifest olmadan App Store Connect yüklemeyi uyarıyla
  karşılıyor, bazen reddediyor. Sebep kodu `CA92.1` (kendi uygulamanın ve
  kendi app group'unun defaults'una erişim), ki bizim durumumuz tam bu.
  Uzantının kendi manifesti olmak zorunda — uygulamanınki onu kapsamıyor.
- Uzantının görünen adı `actual-widgets` idi, `Kare` yaptım.
- `ITSAppUsesNonExemptEncryption = NO` eklendi. Bu olmadan her yüklemeden
  sonra App Store Connect sana ihracat uyumluluğu sorusunu soruyor ve
  cevaplayana kadar build "İşleniyor"da bekliyor. Kare'de HTTPS bile yok,
  cevap net biçimde hayır.

**Xcode'da yapman gerekenler:**

1. Projeyi aç. Sol panelde `PrivacyInfo.xcprivacy` dosyalarının göründüğünü
   doğrula (klasör senkronize gruplar kullanıyor, otomatik gelmeli).
2. Her iki dosyayı da seç → sağ panelde **Target Membership**: uygulamanınki
   `Widgy`, uzantınınki `actual-widgetsExtension` işaretli olmalı. Bu adımı
   atlarsan manifest pakete girmez ve hiçbir işe yaramaz.
3. **Product → Clean Build Folder**, sonra bir kez cihazda çalıştır. Widget'lar
   hâlâ görünüyor mu, editör açılıyor mu — beş dakikalık kontrol.

---

## 1 · Sürüm numaraları

`MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`. İlk yükleme için
doğru. Tek kural: **aynı build numarasını iki kez yükleyemezsin.** Bir şeyi
düzeltip yeniden yollarsan `CURRENT_PROJECT_VERSION`'ı 2, 3 diye artır.
`MARKETING_VERSION` 1.0 kalabilir.

---

## 2 · App Store Connect'te uygulamayı oluştur

<https://appstoreconnect.apple.com> → **Apps** → **+** → **New App**

| Alan | Değer |
|---|---|
| Platforms | iOS |
| Name | `Kare: Widget Marketplace` — App Store'daki isim benzersiz olmak zorunda. Tutmazsa sırayla `Kare Widgets`, `Kare: Widget Stüdyosu` dene. Telefonda ikonun altında yazan isim ayrı bir alan ve zaten sadece **Kare**. |
| Primary Language | Turkish (ya da English — sonra değişir) |
| Bundle ID | `com.erdendereli.Widgy` |
| SKU | `widgy-ios-001` (sana özel, kullanıcı görmez) |
| User Access | Full Access |

Bundle ID listede çıkmıyorsa: Xcode'da bir kez arşiv alıp yüklediğinde
otomatik oluşuyor; ya da developer.apple.com → Identifiers'tan elle
oluştur. Uzantının bundle ID'si (`com.erdendereli.Widgy.actual-widgets`)
ayrı bir uygulama değil, onu App Store Connect'te oluşturmayacaksın.

**Neden hâlâ Widgy yazıyor:** bundle ID, App Group, hedef ve şema adları kullanıcının görmediği teknik kimlikler. Marka Kare oldu ama bunlara dokunmadık; değiştirmek App Group'u ve provisioning'i baştan kurmayı gerektirir ve iki gün kala widget'ları kırma riski taşır. Hiçbir kazancı yok, kullanıcı hiçbirini görmüyor.

**App Groups uyarısı:** `group.com.zeddy.Widgy` hem uygulama hem uzantı
profilinde tanımlı olmalı. Automatic signing bunu hallediyor ama arşiv
sırasında imza hatası alırsan ilk bakacağın yer burası.

---

## 3 · Arşivle ve yükle

1. Xcode'da şema **Widgy**, cihaz hedefi **Any iOS Device (arm64)**.
   (Simülatör seçiliyken Archive menüsü gri kalır.)
2. **Product → Archive**. Birkaç dakika.
3. Organizer açılınca **Distribute App → App Store Connect → Upload**.
4. "Manage Version and Build Number" işaretini **kaldır** — numaraları sen
   kontrol et, Xcode karıştırmasın.
5. Yükleme bitince App Store Connect → TestFlight sekmesinde build birkaç
   dakika **Processing** görünür. E-posta ile haber gelir.

**Sık çıkan hatalar:**

| Hata | Sebep |
|---|---|
| "Invalid Bundle. Missing Info.plist value CFBundleIconName" | Asset catalog'da AppIcon adı yanlış. `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` zaten doğru. |
| "Missing privacy manifest" uyarısı | Adım 0.2'yi atlamışsın, target membership işaretli değil. |
| "Invalid Provisioning Profile" | App Group entitlement profile'da yok. Xcode → Signing & Capabilities'ten bir kez kaldırıp geri ekle. |
| Build "Processing"da takılı | Genelde 10-30 dk. 2 saati geçerse yeni build numarasıyla tekrar yolla. |

---

## 4 · TestFlight bilgilerini doldur

Build işlenince TestFlight sekmesinde:

**Test Information** (external için zorunlu, eksikse review'a gönderemezsin):

- **Beta App Description** — kullanılabilecek metin:

  > Kare, iOS ana ekranınız için bir widget pazar yeridir. Hazır ve canlı
  > widget'ları katalogdan ekleyebilir, ya da kendi widget'ınızı fotoğraf,
  > metin ve sticker'larla kendiniz tasarlayabilirsiniz. Tüm widget'lar kilit
  > ekranında da çalışır. Uygulama tamamen cihaz üzerinde çalışır; hiçbir veri
  > toplanmaz veya sunucuya gönderilmez.

- **Feedback Email** — senin adresin.
- **Beta App Review Information** — İletişim adı, soyadı, telefon, e-posta.
- **Sign-in required?** — **Hayır.** Giriş yok, bu iyi haber: review'cı
  hesap beklemeden test eder, süreç kısalır.
- **Notes** — review'cının işini kolaylaştıran şey bu, boş bırakma:

  > Uygulama açıldığında dil sorusu gelir, sonra ana ekran görünür. Widget'ları
  > görmek için: ana ekranda boş alana uzun basın → sol üstteki + → listeden
  > "Kare" seçin. Altı hazır widget ve kendi tasarımlarınız burada listelenir.
  > Kendi widget'ınızı yapmak için uygulama içinde Widgets sekmesi → + → Editör.
  > Uygulama ağ bağlantısı kullanmaz, hesap gerektirmez.

- **What to Test** (her build için ayrı) —

  > İlk TestFlight sürümü. Test edilecekler: altı hazır widget'ın ana ekrana ve
  > kilit ekranına eklenmesi, Söz widget'ının dört saatte bir değişmesi,
  > editörle özel widget oluşturma (metin, fotoğraf, kırpma, sticker), Türkçe
  > ve İngilizce arayüz.

---

## 5 · External grup ve review

1. TestFlight → **External Testing** altında **+** → grup adı: `Jüri ve
   davetliler`.
2. Build'i gruba ekle.
3. **Enable Public Link** — QR'ın göstereceği adres bu.
   `https://testflight.apple.com/join/XXXXXXXX`
4. **Submit for Review**.

Review kuyruğa girer. Genelde 24 saat, bazen daha hızlı, bazen 48. **Cuma
sabahına kadar dönmezse plan B devrede** (aşağıda).

Onaylandıktan sonra: aynı **build** için yaptığın küçük değişikliklerde
tekrar review gerekmez, ama **yeni build** yüklersen o build yeniden review'a
girer. Yani Perşembe akşamı "şunu da düzelteyim" deme. Bugün yolladığın build
Cuma'nın build'i olsun.

---

## 6 · QR kodları

Public link geldiğinde:

```bash
cd <sunum klasörü>/deck
# links.json içine iki adresi yaz, sonra:
python3 make-qr.py
node build.js
```

`links.json`:

```json
{
  "testflight": "https://testflight.apple.com/join/XXXXXXXX",
  "portal": "https://<vercel-adresin>.vercel.app"
}
```

Bu, sunuma 15. slaytı ekliyor: iki QR yan yana, altlarında adresler yazılı
(salonun arkasından kod okunmazsa kimse mahcup olmasın). Adresi girilmeyen
taraf slayta hiç çizilmiyor — yarım kalmış bir yer tutucu görünmüyor.

**Sunumdan önce iki kodu da kendi telefonunla okut. Bir kez. Yeter.**
QR üretici kendi çıktısını bir tarayıcı gibi geri okuyup doğruluyor, ama o
sadece kodun kendi içinde tutarlı olduğunu gösterir — doğru adrese gittiğini
senin görmen lazım.

---

## Plan B: review Cuma sabahına yetişmezse

Panik yok, sunumun buna bağlı değil.

1. **Portal QR'ı kalır.** Site Vercel'de, review'a tabi değil. Tek QR'lı
   slayt otomatik olarak ortalanıyor, düzen bozulmuyor.
2. **Demo zaten canlı.** Sunumun en güçlü 2,5 dakikası senin telefonunda,
   TestFlight'a ihtiyacı yok.
3. **Söyleyeceğin cümle:** *"Uygulama şu anda Apple'ın beta incelemesinde;
   onay gelir gelmez indirme linkini paylaşacağım."* Bu, "yapamadık"tan çok
   farklı bir cümle — jüriye süreci bildiğini gösterir.
4. İstersen jüriden e-posta topla, link gelince kendin yolla. Bu aslında
   QR'dan daha iyi bir takip aracı.

---

## Zaman çizelgesi

| Ne zaman | Ne |
|---|---|
| **Çarşamba (bugün)** | Target membership kontrolü → temiz build → arşiv → yükle. Metadata'yı doldur. Review'a gönder. |
| **Çarşamba akşamı** | Portal'ı Vercel'e deploy et, adresi not al. |
| **Perşembe** | Review'ı bekle. **Yeni build yollama.** Prova yap (5 kez, kronometreyle). |
| **Perşembe akşamı** | Link geldiyse QR'ları üret, iki kodu da telefonla okut. |
| **Cuma sabahı** | Telefonu Uçak Modu + Wi-Fi, Rahatsız Etmeyin. Demo ekran kaydı yedekte. Sun. |

En kritik satır ilki. Bugün yüklemezsen Cuma'da external TestFlight yok.
