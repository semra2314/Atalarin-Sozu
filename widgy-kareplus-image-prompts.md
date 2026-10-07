# Kare+ · GPT görsel promptları (Exhale, Countdown, Progress)

İki tür görsel var:

1. **Market görselleri (3 adet):** Discover'daki kartta ve detay sayfasında görünen parlak "ürün" çekimleri.
2. **Widget arka planları (14 adet):** Widget'ın kendi içinde, rakamların arkasında duran sanat. Aşamaya, temaya ya da mevsime göre değişiyor.

Kod hazır. Görseller asset catalog'a eklenene kadar widget'lar düz gradyan çiziyor, eklendiği anda görselleri kullanmaya başlıyor. Yani istediğin sırayla üretebilirsin.

---

## Nereye, hangi isimle

| Tür | Boyut (GPT) | Nereye |
|---|---|---|
| Market görseli | 1024×1024 | Sadece `Widgy/Assets.xcassets` |
| Arka plan (kare) | 1024×1024 | `Widgy/Assets.xcassets` **ve** `actual-widgets/Assets.xcassets` |
| Arka plan (`-wide`) | 1536×1024 | İkisine de, aynı isim + `-wide` |

İsimler **birebir** aşağıdaki gibi olmalı (köşeli parantez içindekiler). Kod bu isimleri arıyor.

Asset kataloglarını açmak için:

```bash
open ~/Projects/Swift/Widgy/Widgy/Assets.xcassets
open ~/Projects/Swift/Widgy/actual-widgets/Assets.xcassets
```

---

## Ortak kurallar (her arka plan promptunun sonunda zaten var)

- **Kesinlikle yazı, rakam, logo, arayüz, uygulama ikonu yok.** Rakamları widget kendisi basıyor.
- Sol alt ve orta kısım sakin kalsın. Yazılar ve ciğer oraya geliyor.
- Yumuşak, premium, sinematik. Kare'nin diğer widget'larıyla (Aurora, Focus, Daily) aynı ailede dursun.
- Kenarlara önemli detay koyma, widget kenarları kırpıyor.

---

# 1 · Market görselleri

Mevcut market görselleriyle aynı stil: gerçek bir iPhone ana ekranı, fotogerçekçi, sığ alan derinliği, 1:1.

### [exhale_widget]

```
A photorealistic close-up of an iPhone home screen held in a hand near an open window at soft
morning light. On the screen, a medium-size widget named "Nefes Al" (Exhale): on the left, a stylised pair of
lungs drawn as a clean glassy icon, filled about halfway from the bottom with a luminous mint-green
(#6EE7B7) glow, as if breath is rising inside them; on the right, elegant serif type reading
"9 days" with a small caption "smoke-free", a warm gold (#FDE68A) figure showing money saved, and a
row of five small progress dashes, three lit in mint. The widget background is a misty dawn forest
in deep teal (#0B1F1D to #124A42) with soft light rays. Hopeful, calm, healing, premium, correct
iOS continuous rounded corners, minimal wallpaper, shallow depth of field, no other app UI, 1:1.
```

### [countdown_widget]

```
A photorealistic iPhone home screen on a wooden desk next to a passport and a folded boarding pass,
warm afternoon light. On the screen, a medium-size "Countdown" widget: a small airplane emoji and
the title "Summer trip", a very large elegant serif number "23" with the caption "days to go", and
two neat rows of small white dots underneath, most of them filled and the rest faint, showing the
wait almost over. Behind the text, a dreamy turquoise sea and sky (#0E4C75 to #3FA7C9) seen from a
plane window. Joyful anticipation, premium travel feel, correct iOS rounded corners, shallow depth
of field, minimal wallpaper, no other app UI, 1:1.
```

### [progress_widget]

```
A photorealistic iPhone home screen lying on warm linen next to a coffee cup and a paper notebook,
soft autumn window light. On the screen, a medium-size "Progress" widget on warm paper tones
(#F6F1E7 to #EDE4D3) with a faint watercolour of autumn leaves in the background: a small caps
label "2026", a large heavy serif "74%", the caption "96 days left", and a row of twelve small
round dots, nine dark, one terracotta red (#D44A33) for the current month, two faint. Editorial,
calm, mindful about time, correct iOS rounded corners, shallow depth of field, no other app UI, 1:1.
```

---

# 2 · Exhale arka planları

Tek bir hikâye: dumanlı bir akşamdan açık dağ havasına yolculuk. **Dört görsel aynı dünyada geçsin**, sadece hava ve ışık değişsin. Widget, kullanıcının iyileşme seviyesine göre sıradakine geçiyor. Ciğer sol tarafta (orta boyda) ya da ortada duruyor; orası sade kalsın.

Her biri için önce kareyi, sonra `-wide` versiyonu üret. `-wide` için promptun başına şunu ekle: *"Wide panoramic 3:2 version of the same scene, "*

**[exhale-bg-haze]** · ilk 12 saat (iyileşme %0-12)
```
A soft, moody background, no text: a quiet valley at dusk seen through a veil of grey haze, muted
charcoal and ash tones (#2B2D31 to #4A4A4F), faint silhouettes of pine trees, the air thick and
still, a single very faint warm glow low on the horizon hinting that it will clear. Cinematic,
painterly, minimal, calm lower-left area, no people, no text, no numbers, no UI.
```

**[exhale-bg-dawn]** · ilk iki hafta (%12-40)
```
A soft, hopeful background, no text: the same pine valley at first light, the haze lifting in
layers, a dusty indigo sky (#1F2A44) warming to rose (#B5838D) at the horizon, the first sunbeams
touching the treetops, cool clean air beginning to appear. Cinematic, painterly, minimal, calm
lower-left area, no people, no text, no numbers, no UI.
```

**[exhale-bg-forest]** · dokuz aya kadar (%40-84)
```
A soft, fresh background, no text: the same valley now a lush green forest in deep teal and
emerald (#0B1F1D to #124A42), morning mist drifting between the trees, gentle god-rays, dew,
a feeling of cool breathable air. Cinematic, painterly, minimal, calm lower-left area, no people,
no text, no numbers, no UI.
```

**[exhale-bg-summit]** · dokuzuncu aydan sonra (%84-100)
```
A soft, triumphant background, no text: looking out from above the same valley to clear alpine
peaks under a crisp open sky, deep blue (#0E3B5C) to bright glacier cyan (#5FB3C9), a few light
clouds, sunlight, the sense of the freshest air on earth. Cinematic, painterly, minimal, calm
lower-left area, no people, no text, no numbers, no UI.
```

---

# 3 · Countdown arka planları

Kullanıcı geri sayım oluştururken "Ne için?" sorusuna cevap veriyor, arka plan ona göre geliyor. Büyük rakam sol altta, noktalar en altta duruyor.

**[countdown-bg-trip]** · Seyahat
```
A dreamy background, no text: a view from an airplane window over a turquoise sea and soft
clouds at golden hour, deep ocean blue (#0E4C75) to bright lagoon (#3FA7C9), a hint of a distant
island. Anticipation and escape, painterly, premium, calm lower-left area, no text, no numbers,
no UI.
```

**[countdown-bg-celebration]** · Kutlama
```
A festive background, no text: soft bokeh of warm string lights and gently falling confetti in
deep plum (#3A0F4F) and raspberry pink (#C2376B), a subtle glow, joyful but elegant, like the
moment before a party starts. Painterly, premium, calm lower-left area, no text, no numbers, no UI.
```

**[countdown-bg-love]** · Biri için
```
A tender background, no text: two warm lights glowing far apart across a dusky city at night,
deep wine (#4A0E24) to rose (#B8345A), soft bokeh, the feeling of counting down to seeing someone.
Romantic, painterly, understated, calm lower-left area, no people, no text, no numbers, no UI.
```

**[countdown-bg-study]** · Sınav
```
A focused background, no text: a calm desk by a window at night, a warm lamp glow, stacked
books and a notebook softly out of focus, deep slate blue (#1B2A3A to #3D5A73). Quiet
determination, painterly, premium, calm lower-left area, no text, no numbers, no UI.
```

**[countdown-bg-calm]** · Diğer
```
A calm neutral background, no text: a soft night sky with a few gentle stars and a slow
gradient from graphite (#1D1D1F) to deep charcoal (#3A3A3C), a very faint aurora shimmer at the
top. Minimal, premium, versatile, calm lower-left area, no text, no numbers, no UI.
```

---

# 4 · Progress arka planları

Ay ve yıl modunda mevsime göre değişiyor, "Hayatın" modunda gece gökyüzü. Gün modu mevcut Daily kâğıt arka planlarını kullanıyor, onlar için yeni görsel gerekmiyor. **Mevsim görselleri açık tonlu olmalı**, üstüne koyu yazı geliyor.

**[progress-bg-spring]**
```
A light, airy background, no text: warm off-white paper texture (#F6F1E7) with a delicate
watercolour of cherry blossom branches entering from the top right corner, soft pink and fresh
green, lots of empty cream space in the centre and lower left. Editorial, gentle, no text,
no numbers, no UI.
```

**[progress-bg-summer]**
```
A light, sunny background, no text: warm off-white paper texture (#F6F1E7) with a soft watercolour
of olive branches and a hint of a pale sea horizon at the top right, golden and sage tones, lots of
empty cream space in the centre and lower left. Editorial, gentle, no text, no numbers, no UI.
```

**[progress-bg-autumn]**
```
A light, warm background, no text: warm off-white paper texture (#F6F1E7) with a delicate
watercolour of falling maple and oak leaves in terracotta (#D44A33), ochre and rust, entering
from the top right, lots of empty cream space in the centre and lower left. Editorial, gentle,
no text, no numbers, no UI.
```

**[progress-bg-winter]**
```
A light, crisp background, no text: cool off-white paper texture with a delicate watercolour of
bare birch branches and a few soft snowflakes at the top right, pale grey-blue and silver tones,
lots of empty space in the centre and lower left. Editorial, quiet, no text, no numbers, no UI.
```

**[progress-bg-life]** · koyu, üstüne beyaz yazı gelir
```
A deep contemplative background, no text: a vast night sky full of fine stars and a soft band of
the Milky Way, deep navy (#0B1026) to indigo (#2A2358), a faint glow at the horizon, the feeling
of a whole life seen from far away. Calm, awe, painterly, premium, calm lower-left area, no text,
no numbers, no UI.
```

---

## Kontrol listesi

- [ ] 3 market görseli → sadece app asset'lerine
- [ ] 14 arka plan × 2 (kare + `-wide`) → app **ve** extension asset'lerine
- [ ] İsimler birebir aynı (küçük harf, tire)
- [ ] ⌘B, sonra Discover'da kartlara ve ana ekrandaki widget'lara bak
