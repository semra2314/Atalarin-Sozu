# Widgy — Backgrounds for Frame & Hush (GPT / DALL-E)

Same rules as the Aurora/Focus background set: **backgrounds only — NO text, no numbers, no UI,
no app icons, no photos of people.** The live widget draws all type on top.

Generate **1:1 (square)**, high resolution, smooth gradients, no hard edges or busy detail.
I'll auto-generate the wide (2.13:1) medium-size crops from these, so keep the composition
tolerant of a centre horizontal crop.

## The one rule that matters

Each widget reserves space for live type. If the background is busy there, the widget becomes
unreadable — this is exactly what we just fixed on Aurora. So:

- **Frame**: the **left half must stay calm and dark** (the serif caption sits there). All
  interest belongs in the right half, behind/around the framed photo.
- **Hush**: the **centre must stay near-black and empty** (the word sits there). Any glow
  belongs at the edges, very faint.

---

## Frame — 3 warm backgrounds

A warm, editorial, golden-hour world. Deep browns, cream light. Think a sunlit room at 5pm,
abstracted — no objects, no windows, just light and shadow.

**[frame-bg-warm]** (default)
```
A 1:1 abstract background, no text: a warm dark brown gradient from #3A2C26 at the top-left to
#241C1C at the bottom-right, with a soft golden-cream #E8C9A0 glow diffusing gently from the
right edge only. The entire left half stays deep, calm and almost flat. Smooth, editorial,
premium, film-grain softness, no objects, no UI, no words.
```

**[frame-bg-dusk]** (evening)
```
A 1:1 abstract background, no text: a deep cocoa-to-plum gradient, #2E2320 through #3B2A2E, with
a muted amber #C98A4B haze low on the right side. The left half remains dark and undisturbed.
Quiet, warm, cinematic, soft grain, no objects, no UI, no words.
```

**[frame-bg-morning]** (light)
```
A 1:1 abstract background, no text: a soft warm taupe gradient, #4A3B33 to #2A211E, with a pale
cream #F0E3D5 light bleeding in from the upper right corner like early sun through a curtain.
Left half stays calm and shadowed. Airy, editorial, premium, no objects, no UI, no words.
```

---

## Hush — 3 dark backgrounds

⚠️ **The first version of these prompts produced flat black images.** Image generators need
something to actually draw: words like "pure black", "empty", "nothing", "extreme minimalism"
give you a black rectangle. So these prompts describe **visible** structure — soft smoke, a
light sweep, grain — in a dark key. On the device it still reads as near-black, because the
word sits on top and the widget is small, but the image has real depth in it.

Rules for this set: aim for **charcoal, not black** (#141414–#262626 range). Ask for visible
tonal variation. Never say "empty" or "pure black".

**[hush-bg-still]** (default)
```
A 1:1 abstract dark background, no text: soft charcoal smoke drifting slowly through a dark
room, tones ranging from #101010 in the centre to #2A2A2A at the corners, with a gentle
diffused grey light sweeping in from the upper left. Visible soft gradients and fine film
grain throughout. Moody, matte, premium, photographic depth. No objects, no people, no UI,
no words.
```

**[hush-bg-dawn]** (morning hours)
```
A 1:1 abstract dark background, no text: a dark charcoal field with a soft cool blue-grey
#39404E mist rising from the bottom edge and fading upward into #121316, like the first light
seeping under a closed door. Smooth visible gradient, fine grain, gentle depth. The upper
centre stays darkest. Moody, matte, premium. No objects, no people, no UI, no words.
```

**[hush-bg-night]** (late hours)
```
A 1:1 abstract dark background, no text: deep charcoal #121011 with slow warm smoke in muted
brown-grey #2E2620 curling in from the top two corners and dissolving toward the centre, lit
by a single very dim warm light far off frame. Rich shadow detail, visible soft gradients,
fine film grain. Moody, cinematic, matte, premium. No objects, no people, no UI, no words.
```

If one still comes out flat: add "**high shadow detail, clearly visible tonal variation, not a
solid colour**" to the end, and nudge the hex values one step lighter.

---

## How I'll wire these up

- **Frame** currently paints a flat brown gradient. I'll swap it for `frame-bg-warm`, and can
  make it shift by time of day (morning / warm / dusk) exactly like Aurora does — say the word.
- **Hush** currently paints a flat near-black gradient. Same deal: `hush-bg-still` by default,
  with dawn/night variants by hour.

## Flow

1. Generate at 1:1, high resolution, pick the best per name.
2. Drop them into `actual-widgets/Assets.xcassets` **and** `Widgy/Assets.xcassets` using the exact
   bracketed names.
3. Tell me they're in, and I'll resize them to 720×720, auto-generate the `-wide` crops for the
   medium widget, and wire the hour-based switching.

## Two things learned the hard way (keep them in mind)

- **Keep source images modest.** Widget extensions run on a ~30MB memory budget. Our first
  1254×1254 backgrounds blanked the widget entirely. I downscale everything to 720×720 on the
  way in — no visible quality loss on gradients, a quarter of the memory.
- **Square art gets badly cropped on the medium widget** (2.13:1). That's why every background
  also gets a purpose-made `-wide` centre crop rather than being squeezed.
