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

Birinci dil **İngilizce**, Türkçe yerelleştirme olarak eklenecek.

- **İsim:** `Kare: Widget Maker` ya da `Kare: Home Screen Widgets` (30 karakter)
- **Altyazı:** en değerli 30 karakter. Öneri: *"Design your own widgets"*
- **Anahtar kelimeler:** widget, home screen, lock screen, custom, aesthetic,
  theme, icon, photo widget, clock widget. Türkçe için ayrı liste.
- **Açıklama:** ilk üç satır kritik, gerisini kimse açmıyor.

`aesthetic` kelimesini atlama. Bu nişte insanların aradığı kelime tam olarak o
ve rakiplerin çoğu ismine bile koyuyor.

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

**Şirket meselesi ve bir tuzak.** "Para kazanmaya başlayınca şirket açarım"
mantıklı ama bir sırası var: App Store'da abonelik satabilmek için önce **Paid
Apps sözleşmesini** imzalamak, banka ve vergi bilgisi girmek gerekiyor. Bu
bilgiler tamamlanana kadar Apple parayı biriktirip **ödemiyor**. Yani kod hazır
olsa bile satışa açamıyorsun.

Buradaki gecikme günlerle değil haftalarla ölçülüyor. O yüzden banka ve vergi
kurulumunu **Kare+ kodunu yazmadan önce** başlat; kod bittiğinde bekleyen taraf
sen olma.

Vergi tarafında ne yapman gerektiğini bir mali müşavire sor, ben avukat ya da
mali müşavir değilim. Bir saatlik danışma, sonradan çözmesi çok pahalı olan bir
sorunu baştan çözüyor.

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

**5. Neden global, neden İngilizce önce**

Pazarlama kanalınız TikTok ve TikTok'un sınırı yok. İngilizce içerik
üretirseniz algoritma sizi büyük pazara taşır; Türkiye'yle sınırlamak
algoritmanın doğal erişimine karşı kürek çekmektir. Üstelik Türkiye App
Store'unda kullanıcı başına gelir düşük, orada birinci olmak bile az para
demek.

Bunun iki somut sonucu var:

- **App Store listelemesi İngilizce birinci dil olacak**, Türkçe yerelleştirme
  olarak eklenecek. Uygulama zaten iki dilli, iş sadece mağaza tarafında.
- **Ekran görüntüleri kusursuz olmak zorunda.** Global pazarda cilalı
  uygulamalarla yarışıyorsunuz; Türkiye pazarı pürüzleri daha çok affediyor.
  En çok emek verilecek pazarlama işi bu.

Söz widget'ı kalıyor ve global uygulamanın içinde daha değerli bir şey
kanıtlıyor: yerelleştirilmiş içerik widget'ı yapabildiğinizi. Bugün Türkçe
atasözü, yarın İspanyolca ya da Japonca karşılığı. Bu bir şablon, tek seferlik
bir özellik değil.

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

## Takvim · haftada 24-32 saat

Bu tempo ciddi. Buna göre gerçekçi hedef: **beş hafta sonra App Store'da,
üç ay sonra gelir.**

### 1. hafta · TestFlight ve gerçek insanlar

- Build'i yükle, external review'a gönder (ilk gün, gerisi beklerken yapılır).
- 20-30 kişi bul. TikTok'ta zaten bu nişi izliyorsun; oradaki insanlara yaz.
  Yabancı test kullanıcısı, tanıdıktan çok daha değerli.
- Tek soruyu sor: widget'ı ana ekrana ekleyebildin mi.
- **Paralel:** App Store Connect'te Paid Apps sözleşmesi, banka ve vergi
  bilgisi kurulumuna bugün başla. Aylar sonra lazım olacak ama bekleme
  süresi uzun ve sana hiçbir şeye mal olmuyor.

### 2. hafta · En büyük iş: widget ekleme rehberi

Beta geri bildirimi muhtemelen bunu söyleyecek. Uygulama içinde, atlanamayan,
animasyonlu bir anlatım. Boş ana ekrandan widget'a kadar.

Yanında: boş durumlar, izin reddi halleri, altı widget'ın da bellek testi.

### 3. hafta · App Store vitrini

Bu hafta kod değil pazarlama haftası, ve dönüşümü en çok etkileyen hafta bu.

- **Beş ekran görüntüsü**, her biri tek bir fikir. Global pazarda cilalı
  uygulamalarla yarışıyorsun, burada acele etme.
- İngilizce listeleme metinleri, anahtar kelime araştırması.
- Uygulama önizleme videosu (isteğe bağlı ama dönüşümü ciddi artırıyor,
  zaten TikTok için çektiğin malzemeden çıkar).
- Kare+ ekranının satın alma butonunu çıkar.

### 4. hafta · Cila ve gönderim

- Beta'dan gelen hataları kapat.
- Gerçek cihazda baştan sona, temiz kurulumla dene.
- Gönder. İnceleme genelde 24-48 saat.

### 5. hafta · Çıkış ve içerik motoru

- Yayında. Kurulum sayısına değil, **widget ekleme oranına** bak.
- TikTok'ta haftada iki video başlat. Bir video tutana kadar durma.

### 6-12. hafta · Ölçüp düzeltmek, sonra para

- Her hafta: bir ürün düzeltmesi, iki video.
- Elde tutma stabilse **StoreKit 2 ile Kare+**. Banka kurulumu 1. haftada
  başladığı için hazır olacak.
- Gelir görünmeye başladığında tasarımcı fazı konuşulabilir.

### Bir uyarı

Haftada 24-32 saatin **en az yarısı pazarlama olmalı.** Bu senin doğal
eğilimine ters gelecek, çünkü kod yazmak daha rahat ve ilerleme hissi veriyor.
Ama uygulaman şu an rakiplerin çoğundan iyi durumda; eksik olan kod değil,
kimsenin bilmemesi. Bir özellik daha eklemek dördüncü videoyu çekmekten daha
az değerli.

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
