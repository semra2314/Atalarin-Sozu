# Widgy — Marketplace preview imagery for Daily and Söz (GPT / DALL-E)

These are the glossy "in context" shots shown on each widget's card in the catalog and on its
detail page — the same treatment as the existing eight (`aurora_widget`, `focus_widget`,
`frame_widget`, `hush_widget`, …). They are **not** the widget's background art; that's a
separate set. Here the widget is rendered *inside* a photographed iPhone home screen.

Save as **`daily_widget`** and **`soz_widget`**, 1:1, high resolution.

## Shared style (already baked into each prompt)

Photorealistic 3D render, a real iPhone on a real surface, soft natural lighting, shallow depth
of field, a tasteful minimal wallpaper, correct iOS continuous-rounded widget corners, no text
watermarks, no other apps' branding. The widget's own colours must match exactly.

## The one thing to get right

Both of these widgets are **light** — dark ink on warm paper — unlike Aurora, Focus and Hush.
So the scene around them should be light too: a bright desk, morning light, pale surfaces. A
moody dark scene would make the widget look like a white rectangle punched out of the photo.

---

## Daily (t-daily) — a passage a day

```
A photorealistic close-up of an iPhone home screen resting on a pale oak desk beside an open
notebook, showing a single large "Daily" widget: a warm cream card (#FAF3E7 to #EBDCC4) with a
soft gold glow in the upper right, carrying a short serif quotation in deep espresso ink
(#2B2018), centred, with a small muted reference line beneath it. Bright morning light, calm and
contemplative, shallow depth of field, minimal light wallpaper, uncluttered surface. Premium,
editorial, 1:1. No other widgets, no app icons in focus, no watermarks.
```

**Alternative composition** (pick whichever renders better):
```
A photorealistic iPhone held loosely in one hand against a softly blurred bright interior,
showing a single large "Daily" widget: warm cream paper card with a gold light in the corner, a
short centred serif passage in dark ink and a small attribution line. Soft diffused daylight,
serene mood, shallow depth of field, 1:1. No other widgets, no watermarks.
```

---

## Söz (t-proverb) — a Turkish proverb every four hours

```
A photorealistic close-up of an iPhone home screen on a warm linen surface next to a small
glass of Turkish tea, showing a single large "Söz" widget: a warm handmade-paper card (#FBF4EA
to #F0E2CE) with a wheat-gold glow in the lower right, carrying a small terracotta (#C05A3E)
uppercase label, a short Turkish saying set in a bold serif in dark warm ink (#2A211C), a
smaller explanatory line beneath it, and a thin terracotta rule above a short italic example
sentence at the bottom. Late afternoon light, quiet and grounded, shallow depth of field,
minimal light wallpaper. Premium, editorial, 1:1. No other widgets, no watermarks.
```

**Alternative composition**:
```
A photorealistic iPhone lying on a stack of two hardcover books on a pale wooden table, showing
a single large "Söz" widget: a warm cream paper card with a small terracotta label, a bold serif
Turkish saying, an explanatory line, and a thin rule above a short italic sentence. Soft warm
window light, calm scholarly mood, shallow depth of field, 1:1. No other widgets, no watermarks.
```

---

## Deliberately avoided

For Söz I've kept the styling out of the folk-motif register — no kilim, no çini tiles, no
calligraphy, no ornamental borders. A glass of tea or a stack of books places it culturally
without turning it into a souvenir. The same reasoning as the background art: those patterns
crowd a small card and date the design fast, and the dignity of a proverb reads better through
restraint than decoration.

## Flow

1. Generate at 1:1, high resolution, pick the best per widget.
2. Add to `Widgy/Assets.xcassets` as `daily_widget` and `soz_widget` (the app target only —
   these are catalog images, the widget extension never draws them).
3. Tell me they're in and I'll wire them to the catalog entries, which currently have no
   `previewImageName` and so fall back to rendering their theme gradient in the Discover list.
