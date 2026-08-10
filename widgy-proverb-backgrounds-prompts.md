# Widgy — Backgrounds for the Ataların Sözü widget (GPT / DALL-E)

Same rules as the other background sets: **backgrounds only — no text, no letters, no symbols,
no UI.** The widget draws the saying, its meaning and an example on top.

Generate **1:1 (square)**, high resolution. I'll downscale to 720×720 and cut the wide (2.13:1)
medium crops automatically.

## Palette: warm handmade paper — light, like Daily but warmer

Cream paper (#FBF4EA), warm sand (#F0E2CE), soft wheat light (#E3C49B), with a terracotta
accent (#C05A3E) used only by the type. The saying is set in deep warm ink (#2A211C) on top, so
the artwork must stay **light and low-contrast**.

## Three rules that matter here

**1. Keep it bright.** Mid-to-high key throughout. No deep shadows or dark corners — the text is
dark on light, the opposite of Aurora and Focus.

**2. Keep the top-left two-thirds calm.** Unlike Daily, this widget's text is *left-aligned and
top-anchored*, and the large size carries three blocks (saying, meaning, example). Texture and
warmth belong along the bottom and right edges.

**3. No folk motifs.** No kilim patterns, no çini tiles, no Ottoman calligraphy, no ornament, no
borders. It's the obvious idea and the wrong one: those patterns fight the typography, crowd a
small card, and date the design badly. Abstract paper, fibre and light only — the dignity should
come from restraint, the way a well-set book page carries a proverb.

---

**[proverb-bg-morning]** (approx 5:00–11:00)
```
A 1:1 abstract background, no text and no symbols: pale cream handmade paper #FBF6EE with
visible soft fibre texture and gentle deckled grain, lit by a soft warm wheat #EFDCC0 light
entering from the lower right. Bright, airy, high key, very low contrast. The upper-left two
thirds stays clean and almost flat. Minimal, editorial, premium, quiet. No objects, no pattern,
no ornament, no UI, no words.
```

**[proverb-bg-day]** (approx 11:00–19:00)
```
A 1:1 abstract background, no text and no symbols: warm cream-to-sand gradient, #FBF4EA through
#F0E2CE, with a soft wheat-gold #E3C49B glow pooling in the bottom-right corner and dissolving
toward the centre. Fine handmade-paper fibre texture, gentle visible gradients, calm mid-to-high
key. The top-left remains light and undisturbed. Minimal, editorial, premium. No objects, no
pattern, no ornament, no UI, no words.
```

**[proverb-bg-evening]** (approx 19:00–5:00)
```
A 1:1 abstract background, no text and no symbols: warm sand paper #F4E7D2 deepening gently to
#E6D2B4 along the bottom edge, with a low amber #D9B487 warmth on the right, like lamplight
falling across a page. Still bright overall — warm and soft, never dark. Fine paper grain,
smooth visible gradients. Minimal, editorial, premium, restful. No objects, no pattern, no
ornament, no UI, no words.
```

---

## Flow

1. Generate at 1:1, pick the best per name.
2. Drop them into **both** `actual-widgets/Assets.xcassets` and `Widgy/Assets.xcassets` using the
   exact bracketed names. (The widget extension has its own catalog — art only in the app target
   won't reach the widget.)
3. Tell me they're in and I'll resize to 720×720, generate the `-wide` crops, and check the
   contrast in the region where the text sits. The widget already falls back to a code-drawn
   paper gradient, so nothing breaks while the art is being made.

## Reminders from earlier rounds

- **Don't ask for "pure" anything or "empty".** That's how `hush-bg-night` came back as a flat
  rectangle. Always describe something visible — fibre, grain, a light sweep.
- **Watch the contrast.** Dark text on light paper here. Any dark region in the top-left will
  swallow the saying; regenerate rather than keeping it. I measure this before wiring them up.
- **Keep source images modest.** Widget extensions have a ~30MB memory budget; oversized art is
  what blanked Aurora entirely. Everything gets downscaled to 720×720 on the way in.
