# Widgy — Backgrounds for the Daily widget (GPT / DALL-E)

Same rules as the other background sets: **backgrounds only — no text, no letters, no symbols,
no UI.** The widget draws the passage and its reference on top.

Generate **1:1 (square)**, high resolution. I'll downscale to 720×720 and cut the wide (2.13:1)
medium crops automatically.

## Palette: warm cream and gold — light, not dark

Unlike Aurora, Focus and Hush, this widget is **light**. Think aged paper in late afternoon sun:
cream (#FAF3E7), warm sand (#EBDCC4), soft gold light (#E8C88A). The passage is set in deep
espresso ink (#2B2018) on top, so the artwork must stay **light and low-contrast** — anywhere it
goes dark or busy, the text stops being readable.

## Three rules that matter here

**1. Keep it bright.** Mid-to-high key throughout. No deep shadows, no dark corners. If the
image reads as "moody", it's wrong for this one.

**2. Keep the left two-thirds calm.** The passage is left-aligned and can run several lines.
Texture and gold light belong at the edges and toward the top-right.

**3. Stay neutral — no religious or cultural signalling.** This one widget carries scripture for
some people, Stoic philosophy or poetry for others. No crescents, no crosses, no columns, no
calligraphy, no gilded ornament, no manuscript illumination, no mandala, no stained glass.
Abstract paper, light and warmth only. It should feel like a beautifully made book, not like any
particular tradition's book.

---

**[daily-bg-morning]** (approx 5:00–11:00)
```
A 1:1 abstract background, no text and no symbols: soft cream paper #FAF6EE with a gentle pale
gold #F0DCB4 light washing in from the upper right, like early sun across a blank page. Fine
paper-fibre texture, delicate visible grain, very soft tonal gradients. Bright, airy, high key.
The left two-thirds stays clean, light and uncluttered. Minimal, editorial, premium, serene.
No objects, no ornament, no religious imagery, no UI, no words.
```

**[daily-bg-day]** (approx 11:00–19:00)
```
A 1:1 abstract background, no text and no symbols: warm cream-to-sand gradient, #FAF3E7 through
#EBDCC4, with a soft golden #E8C88A glow pooling in the top-right corner and dissolving softly
toward the centre. Subtle paper texture, gentle visible gradients, calm mid-to-high key
lighting. Left side remains light and undisturbed. Minimal, editorial, premium, peaceful.
No objects, no ornament, no religious imagery, no UI, no words.
```

**[daily-bg-evening]** (approx 19:00–5:00)
```
A 1:1 abstract background, no text and no symbols: warm sand paper #F2E4CB deepening slightly to
#E0CBA8 at the lower left, with a honey-gold #DDB77A light low on the right, like the last warm
light of the day on a page. Still bright overall — soft and warm, never dark. Fine grain,
visible smooth gradients. Minimal, editorial, premium, restful. No objects, no ornament,
no religious imagery, no UI, no words.
```

---

## Flow

1. Generate at 1:1, pick the best per name.
2. Drop them into **both** `actual-widgets/Assets.xcassets` and `Widgy/Assets.xcassets` using the
   exact bracketed names. (The widget extension has its own catalog — art only in the app target
   won't reach the widget.)
3. Tell me they're in and I'll resize to 720×720, generate the `-wide` crops, and wire the
   hour-based switching. The widget already falls back to a code-drawn cream/gold gradient, so
   nothing breaks while the art is being made.

## Reminders from earlier rounds

- **Don't ask for "pure" anything or "empty".** That's how `hush-bg-night` came back as a flat
  rectangle. Always describe something visible — grain, a light sweep, tonal variation.
- **Watch the contrast.** The text here is dark on light, the opposite of every other widget. If
  a background comes back with a dark region on the left, it'll swallow the passage — regenerate
  rather than keeping it.
- **Keep source images modest.** Widget extensions have a ~30MB memory budget; oversized art is
  what blanked Aurora entirely. Everything gets downscaled to 720×720 on the way in.
