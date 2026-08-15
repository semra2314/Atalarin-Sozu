# Kare · sunumdan sonrası

Sunum bitti, elinizde çalışan bir uygulama var. Bundan sonrası tamamen farklı
bir iş: jüriyi etkilemek değil, yabancıları elde tutmak.

---

## Önce en önemli karar: sırayı ters kurmayın

Kare iki taraflı bir pazar yeri. Bir tarafta tasarımcılar, diğerinde
kullanıcılar. Bu tür işlerin en yaygın ölüm sebebi, arz tarafını inşa edip
talebin gelmesini beklemek.

Şu an kullanıcınız yok. Kullanıcı yoksa hiçbir tasarımcının Kare'ye widget
koymak için sebebi yok, çünkü kimse görmeyecek. Yani **çalışan bir creator
portalı bugün hiçbir işe yaramaz.** Onu yapmak, önümüzdeki üç ayı kimsenin
kullanmadığı bir gönderim sistemine harcamak olur.

Doğru sıra şu:

1. **Tek taraflı iyi bir ürün** olarak çıkın. Altı widget, editör, ücretsiz.
2. Kullanıcı toplayın. Hedef: birkaç bin kurulum, ölçülebilir bir elde tutma.
3. **Sonra** tasarımcılara gidin ve şunu söyleyin: "burada beş bin kişi var."
   Bu cümle olmadan kimse gelmez. Bu cümleyle çoğu gelir.

Ve ilk tasarımcıları portaldan değil **elle** alın. Beş on kişiyi kendiniz
bulun, widget'larını WhatsApp'tan isteyin, katalogla elle ekleyin. Portal
ancak bu süreç sizi yorduğunda yazılır. Otomatikleştirmeden önce elle yürüt:
elle yürütürken öğrendikleriniz portalın nasıl olması gerektiğini de söyler.

---

## Faz 0 · Bu hafta: TestFlight'ı bitirin

Zaten yolun yarısındasınız. `TESTFLIGHT.md` adım adım anlatıyor.

- Build'i yükleyin, external review'a gönderin.
- **20-30 gerçek kişi** bulun. Arkadaş değil, tanımadığınız insanlar da olsun;
  arkadaşlar kırılan yerleri söylemekten çekiniyor.
- Tek bir soru sorun: *"Widget'ı ana ekranına ekleyebildin mi?"* Cevap
  hayırsa, sebebi ürünün en kritik hatası demektir.

**Bu fazın tek çıktısı:** ilk açılıştan ana ekrandaki widget'a kadar geçen
yolda kaç kişinin kaybolduğunu bilmek.

---

## Faz 1 · App Store'a çıkış

İlk sürümde **olmayacaklar**: creator portalı, Kare+ satın alma, ücretli
widget. İlk sürümde ölçmeniz gereken şey para değil, insanların kalıp
kalmadığı.

### Çıkmadan önce kapatılması gerekenler

| Konu | Neden |
|---|---|
| **Widget ekleme rehberi** | Widget uygulamalarında kullanıcıların çoğu burada kayboluyor. iOS'ta widget eklemek sezgisel değil. Uygulama içinde birinci sınıf, atlanamayan bir anlatım gerekiyor. |
| **Boş durumlar** | Kütüphane boşken, fotoğraf izni reddedilmişken, sticker çıkarılamadığında ne görünüyor? Her biri elle test edilmeli. |
| **Widget bellek sınırı** | Uzantılara ~30MB veriliyor. Aurora'da bunu bir kez yaşadınız ve widget bembeyaz kaldı. Her widget'ı büyük fotoğrafla, üç boyutta, birkaç saat bekleterek test edin. |
| **Çökme takibi** | Şu an bir kullanıcı çökme yaşarsa haberiniz olmuyor. Xcode Organizer'daki çökme raporları ücretsiz ve SDK gerektirmiyor, oradan başlayın. |
| **App Store görselleri** | Dönüşümü en çok etkileyen şey bu. Metin değil, ekran görüntüleri. Beş kare, her biri tek bir fikir anlatsın. |

### App Store listeleme

- **İsim:** `Kare: Widget Marketplace` (30 karakter sınırı)
- **Altyazı:** en değerli 30 karakter. Öneri: *"Ana ekranını sen tasarla"*
- **Anahtar kelimeler:** widget, ana ekran, kilit ekranı, özelleştirme, tema,
  atasözü, saat, fotoğraf. Türkçe ve İngilizce ayrı ayrı.
- **Açıklama:** ilk üç satır kritik, gerisini kimse açmıyor.

**Reddedilme ihtimali olan yerler:** Kare+ ekranı StoreKit'siz duruyor. İlk
sürümde ya tamamen kaldırın ya da satın alma butonunu çıkarıp sadece "yakında"
bırakın. Çalışmayan bir satın alma akışı Apple'ın klasik ret sebeplerinden.

---

## Faz 2 · Para

Sırası geldiğinde, ve ancak Faz 1'de insanlar kaldıysa.

- **StoreKit 2** ile Kare+ aboneliği. Ekran zaten hazır, arkasına gerçek satın
  alma bağlanacak.
- Fiyatlar sözleşmeyle aynı kalsın: aylık ve yıllık, `KarePlusView.swift` ile
  `lib/terms.ts` birbirini takip ediyor.
- **Önce abonelik, sonra komisyon.** Komisyon tasarımcı gerektiriyor,
  abonelik gerektirmiyor.

**Şirket meselesi:** App Store'dan gelir alabilmek için şahıs firması ya da
şirket gerekiyor, vergi bilgisi giriliyor. Tasarımcılara ödeme yapmak ise ayrı
ve daha ağır bir iş: sözleşme, fatura, stopaj, ödeme sağlayıcısı. Faz 3'e
başlamadan önce bir mali müşavirle bir saat konuşun, sonradan çözmesi çok
pahalı.

---

## Faz 3 · Tasarımcılar

1. **Elle başlayın.** Instagram'da, Behance'ta, Dribbble'da iOS widget/ikon
   teması yapan on kişi bulun. Tek tek yazın. Widget'ı sizin editörünüzde ya
   da tasarım dosyası olarak alın, katalogla elle ekleyin.
2. İlk beş tasarımcıya **ne kazandıklarını gösterin.** Kurulum sayısı, ekran
   görüntüsü, teşekkür. Bu beş kişi sonraki ellisini getirir.
3. **Portalı ancak burada yazın.** O zaman neye ihtiyaç olduğunu biliyor
   olacaksınız: hangi alanlar, hangi dosya formatları, inceleme akışı nasıl.

Portal zaten ayakta ve sözleşme yazılı. Eksik olan sadece arka uç, ve o da
ihtiyaç netleştiğinde bir haftalık iş.

---

## Pazarlama

Bütçeniz yok, o yüzden para gerektirmeyen kanallar önemli. Sırayla:

**1. App Store'un kendisi (en yüksek getiri, sıfır maliyet)**

İnsanların çoğu uygulamayı App Store'da arayarak bulur. Altyazı, anahtar
kelimeler ve ekran görüntüleri üzerinde çalışmak, herhangi bir reklamdan daha
çok kurulum getirir. Ayda bir gözden geçirin, hangi kelimeden geldiklerini App
Store Connect gösteriyor.

**2. Kısa video (widget uygulamaları için doğal mecra)**

TikTok ve Instagram Reels'te "ana ekran düzenleme" içeriği çok izleniyor.
Sizin avantajınız: ürün zaten görsel. On beş saniyede boş ana ekrandan
tasarlanmış ana ekrana geçiş, anlatım gerektirmiyor.

Haftada iki video, üç ay. Biri tutarsa hepsini karşılıyor.

**3. Söz widget'ı, içerik olarak**

Elinizde 400 sözlük bir veri seti var ve bu bir içerik kaynağı. Her gün bir
atasözü, anlamıyla, Kare'nin tipografisiyle paylaşın. Uygulamayı satmıyor,
hesabı büyütüyor; uygulama arkadan geliyor. Türkiye'de bu içerik türünün
karşılığı yüksek.

**4. Topluluk**

Reddit'te r/iphone ve ana ekran düzenleme toplulukları, Türkiye'de Ekşi ve
Donanım Haber. Reklam gibi girmeyin, kendi ana ekranınızı paylaşın. İnsanlar
"bu widget ne" diye sorar, o zaman söylersiniz.

**5. Neden önce Türkiye**

Söz widget'ı rakiplerde yok ve olamaz da, çünkü 400 sözlük bir veri seti
hazırlamak zahmetli. Küçük bir pazarda ilk sıraya çıkmak, büyük bir pazarda
yüzüncü olmaktan iyidir. Global açılış, Türkiye'de tuttuktan sonra.

---

## Teknik borç

Aciliyet sırasına göre:

1. **Katalog hâlâ uygulamanın içinde.** Yeni bir widget eklemek için App Store
   güncellemesi gerekiyor, o da her seferinde inceleme demek. CloudKit kodu
   yazılı ama devrede değil (`AppEnvironment.live` mock'u kullanıyor).
   Katalogu sunucuya taşımak, tasarımcı eklemeye başladığınızda zorunlu hale
   gelecek.
2. **Çökme görünürlüğü.** Xcode Organizer yeter, üçüncü parti SDK gerekmiyor.
3. **Widget bellek ve yenileme davranışı.** Sistem widget'ları istediği zaman
   yeniliyor, sizin istediğiniz zaman değil. Söz ve Aurora'yı bir gün boyunca
   telefonda bırakıp gerçekten değiştiklerini doğrulayın.
4. **Bundle ID hâlâ `com.erdendereli.Widgy`.** Kullanıcı görmüyor, acele yok.
   Ama değiştirilecekse App Store'a çıkmadan önce değişmeli; sonrasında
   imkânsız.

### Analitik konusunda bir gerilim var

Uygulamanın gizlilik vaadi şu an çok güçlü: hiçbir veri toplanmıyor, privacy
manifest'te toplanan veri listesi boş, ağ çağrısı bile yok. Bu, rakiplere
karşı gerçek bir üstünlük ve TestFlight incelemesini de kolaylaştırdı.

Üçüncü parti bir analitik SDK'sı eklerseniz bu vaat biter ve manifest değişir.

Çözüm: **Apple'ın kendi App Analytics'i.** App Store Connect içinde, kod
gerektirmiyor, SDK gerektirmiyor, kullanıcıyı takip etmiyor. Kurulum, elde
tutma, çökme ve dönüşüm oranlarını veriyor. Başlangıç için fazlasıyla yeterli.
Daha fazlası gerekene kadar gizlilik vaadinizi bozmayın.

---

## Neye bakacaksınız

Kurulum sayısı gurur okşuyor ama hiçbir şey söylemiyor. Bakılacak üç şey:

| Ölçü | Neden önemli | İyi sayı |
|---|---|---|
| **Widget ekleme oranı** | Uygulamayı açıp ana ekrana widget koyanların oranı. Ürününüzün gerçek dönüşümü bu. | %40 üstü iyi |
| **7 günlük elde tutma** | Bir hafta sonra hâlâ açanlar. Widget uygulamalarında düşüktür, çünkü widget çalışırken uygulamayı açmaya gerek yok. | %20 üstü iyi |
| **Ana ekranda kalma** | Kurdukları widget bir hafta sonra hâlâ duruyor mu. Asıl başarı ölçüsü bu ve uygulama açılışından daha anlamlı. | ölçmesi zor ama düşünmeye değer |

---

## Önümüzdeki iki hafta, somut

1. TestFlight external onayını alın, 20-30 kişiye dağıtın.
2. Tek soruyu sorun: widget'ı ana ekrana ekleyebildin mi.
3. Cevaba göre widget ekleme rehberini yazın. Muhtemelen en büyük iş bu olacak.
4. App Store ekran görüntülerini hazırlayın, beş kare.
5. Kare+ ekranının satın alma butonunu ilk sürümden çıkarın.
6. Çıkın.

Mükemmel olmasını beklemeyin. Şu an elinizdeki şey, çoğu insanın altı ayda
yapamadığı bir yerde. Eksikleri kullanıcılar söyleyecek, tahmin ederek
bulamazsınız.
