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

## Pazarlama · dört kanal, tek içerik

Bütçe yok, o yüzden kanallar emek karşılığı çalışmalı. Dördü birden var ve
**farklı işler yapıyorlar**, birbirinin kopyası değiller.

### 1 · App Store'un kendisi

En yüksek niyetli trafik. Uygulamayı arayan insan zaten indirmeye hazır.
Altyazı, anahtar kelimeler ve ekran görüntüleri üzerinde çalışmak herhangi bir
reklamdan çok kurulum getirir. Ayda bir gözden geçir; hangi kelimeden
geldiklerini App Store Connect söylüyor.

### 2 · Docs sitesi

Bunun asıl işi dokümantasyon değil, **arama trafiği.**

Kimse "Kare docs" diye aramıyor. Ama şunları arıyorlar, hem de çok:

- *how to add a widget on iphone*
- *aesthetic home screen ideas*
- *custom widget with my own photo*
- *lock screen widget ios*

Bu soruların cevabını yazarsan Google, uygulamanın varlığından haberi olmayan
insanları sana getirir. Ve bu trafik bitmiyor; bir video iki gün yaşıyor, iyi
bir rehber iki yıl.

Üstelik **App Store zaten bir destek URL'si zorunlu tutuyor**, yani bu sayfayı
yapmak seçenek değil. Madem yapılacak, arama için yazılsın.

İlk altı yazı:

1. iPhone'da ana ekrana widget nasıl eklenir (adım adım, ekran görüntülü)
2. Kilit ekranına widget ekleme
3. Kendi fotoğrafınla widget yapma
4. Sticker'ın arka planını kesme
5. Widget'ım güncellenmiyor, ne yapmalıyım
6. Kare nedir, ne değildir

İlk beşi Kare'den bağımsız sorular, yani seni tanımayan insanı getiriyor.
Altıncısı onları kullanıcıya çeviriyor.

Site zaten Next.js ve Vercel'de; `/help` altına statik sayfalar olarak eklenir.

**Bir de alan adı meselesi.** `widgy-creators.vercel.app` bir marka değil ve
arama motorunda ciddiye alınmıyor. Global çıkıyorsan gerçek bir alan adı al:
`kare.app`, `getkare.app`, `karewidgets.com` gibi. Yılda birkaç yüz lira ve
docs sitesinin arama değerini bu belirliyor.

### 3 · TikTok

İşi **keşif**: seni tanımayan insana ulaşmak. Algoritma takipçi sayına
bakmadan gösteriyor, o yüzden sıfırdan başlayan için en adil mecra.

Ürün zaten görsel. On beş saniyede boş ana ekrandan tasarlanmış ana ekrana
geçiş, anlatım bile gerektirmiyor.

### 4 · Instagram

İşi TikTok'tan **farklı**: itibar ve tasarımcı ilişkileri.

Instagram'da keşif zayıf ama **tasarımcılar orada yaşıyor.** Faz 3'te
tasarımcılara yazacaksın ve ilk yapacakları şey profiline bakmak olacak.
Düzgün bir Instagram, "bu ciddi bir iş" demenin en ucuz yolu.

Söz widget'ı burada içerik kaynağı: her gün bir söz, Kare'nin tipografisiyle.
Uygulamayı satmıyor, hesabı büyütüyor.

### 5 · Topluluk

Reddit'te r/iphone ve ana ekran düzenleme toplulukları. Reklam gibi girme,
kendi ana ekranını paylaş. İnsanlar "bu widget ne" diye sorar, o zaman
söylersin.

### Kanalları tek içerikle beslemek

Dört kanal için dört içerik planı yaparsan üç hafta içinde tükenirsin. Doğrusu
**tek çekim, dört çıktı**:

Haftada bir kez, bir widget'ı sıfırdan yaparken ekranı kaydet. O tek kayıttan:

- **TikTok:** 15 saniyelik hızlandırılmış hâli
- **Instagram:** aynı video Reels olarak + sonucun tek karelik görseli
- **Docs:** aynı akışın ekran görüntülü yazılı rehberi
- **App Store:** aynı kareler tanıtım görseli olarak

Bir saatlik çekim, dört kanal. Sürdürülebilir olan tek yöntem bu.

### Neden global, neden İngilizce önce

Kanalların hiçbirinin sınırı yok. İngilizce üretirsen algoritma da arama da
seni büyük pazara taşır; Türkiye'yle sınırlamak doğal erişime karşı kürek
çekmek olur. Üstelik Türkiye App Store'unda kullanıcı başına gelir düşük,
orada birinci olmak bile az para demek.

İki somut sonucu var:

- **App Store listelemesi ve docs sitesi İngilizce birinci dil olacak**, Türkçe
  yerelleştirme olarak eklenecek. Uygulama zaten iki dilli.
- **Ekran görüntüleri kusursuz olmak zorunda.** Global mağazada cilalı
  uygulamalarla yarışıyorsun; Türkiye pazarı pürüzleri daha çok affederdi.

Söz widget'ı kalıyor ve global uygulamanın içinde daha değerli bir şey
kanıtlıyor: yerelleştirilmiş içerik widget'ı yapabildiğini. Bugün Türkçe
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
- **Paralel iki iş, ikisi de bekleme süresi yüzünden erken başlamalı:**
  - App Store Connect'te Paid Apps sözleşmesi, banka ve vergi bilgisi.
  - **Alan adını al** ve siteyi oraya taşı. Arama motorunun bir alan adına
    güvenmesi zaman alıyor; ne kadar erken alırsan o kadar iyi.

### 2. hafta · En büyük iş: widget ekleme rehberi

Beta geri bildirimi muhtemelen bunu söyleyecek. Uygulama içinde, atlanamayan,
animasyonlu bir anlatım. Boş ana ekrandan widget'a kadar.

Yanında: boş durumlar, izin reddi halleri, altı widget'ın da bellek testi.

### 3. hafta · App Store vitrini ve docs

Bu hafta kod değil pazarlama haftası, ve dönüşümü en çok etkileyen hafta bu.

- **Beş ekran görüntüsü**, her biri tek bir fikir. Global pazarda cilalı
  uygulamalarla yarışıyorsun, burada acele etme.
- İngilizce listeleme metinleri, anahtar kelime araştırması.
- **Docs sitesinin ilk üç yazısı.** Bunlar aynı zamanda App Store'un istediği
  destek URL'sini karşılıyor, yani zaten yapman gereken işi arama trafiğine
  çeviriyorsun.
- Uygulama önizleme videosu, zaten çektiğin malzemeden çıkar.
- Kare+ ekranının satın alma butonunu çıkar.

### 4. hafta · Cila ve gönderim

- Beta'dan gelen hataları kapat.
- Gerçek cihazda baştan sona, temiz kurulumla dene.
- Gönder. İnceleme genelde 24-48 saat.

### 5. hafta · Çıkış ve içerik motoru

- Yayında. Kurulum sayısına değil, **widget ekleme oranına** bak.
- Haftalık ritmi kur: **bir çekim, dört çıktı.** Bir widget'ı sıfırdan
  yaparken ekranı kaydet; TikTok videosu, Reels, docs yazısı ve App Store
  görseli aynı kayıttan çıksın.
- Kalan üç docs yazısını tamamla.

### 6-12. hafta · Ölçüp düzeltmek, sonra para

- Her hafta: bir ürün düzeltmesi, bir çekim ve ondan çıkan dört içerik.
- Ayda bir: hangi docs yazısının arama getirdiğine bak, kazananın etrafına
  iki yazı daha yaz.
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
