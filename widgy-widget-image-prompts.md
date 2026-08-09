# Widgy - Realistic imagery for the 8 ready-made widgets (GPT / DALL-E)

Use these to generate premium marketplace preview imagery for each catalog widget (the kind of
"in context" / hero shot you'd show on a widget's detail page). Each prompt targets a clean,
photoreal 3D-render look on a real iOS home screen, in the widget's own colours.

Shared style (already in each prompt): photorealistic, soft studio lighting, shallow depth of
field, a real iPhone home screen with a tasteful minimal wallpaper, the widget rendered crisply
with the correct iOS continuous-rounded corners, no text watermarks, no UI chrome from other apps,
1:1 square, high detail. Keep the widget's colours exactly as specified.

---

## 1. Aurora Clock (t-aurora) - minimal
```
A photorealistic close-up of an iPhone home screen on a soft neutral desk, showing a single
"Aurora" clock widget with a smooth aurora gradient from deep indigo (#2C1E5C) through violet
(#7B3FA0) to warm pink (#E0639A), a small warm-cream sun accent, elegant light typography reading
"Good morning". Soft morning light, shallow depth of field, premium, minimal wallpaper, 1:1.
```

## 2. Focus Stack (t-focus) - productivity
```
A photorealistic iPhone home screen widget called "Focus Stack": a deep charcoal-navy card
(#10151F to #1E2B3C) with crisp white rounded type reading "Deep work", a small cyan (#4CC9F0)
status dot and a thin progress bar. Clean desk with a laptop blurred behind, cool focused lighting,
shallow depth of field, minimal, 1:1.
```

## 3. Pulse Rings (t-pulse) - health
```
A photorealistic iPhone home screen showing a "Pulse" health widget on a deep green gradient
(#06231C to #0E5C43) with three glowing activity rings in vivid green (#4ADE80) and a small heart
glyph, reading "Move today". Bright airy morning light, fitness lifestyle vibe, shallow depth of
field, minimal wallpaper, 1:1.
```

## 4. Ledger (t-ledger) - finance
```
A photorealistic iPhone home screen with a sleek "Ledger" finance widget on a dark graphite card
(#1B1B1F to #343440) with a warm amber (#F4A261) upward trend line and calm typography reading
"Stay steady". Sophisticated desk setup, soft directional light, premium fintech feel, shallow
depth of field, 1:1.
```

## 5. Drift (t-drift) - weather
```
A photorealistic iPhone home screen showing a soft "Drift" weather widget as a gentle pastel colour
field (sky blue #7DB9E8, pale cyan #C2E9FB, soft pink #FDEFF9) with a subtle sun-behind-cloud glyph
and dark slate text reading "hello sunshine". Bright diffused daylight, calm and airy, minimal
wallpaper, shallow depth of field, 1:1.
```

## 6. Frame (t-frame) - photos
```
A photorealistic iPhone home screen with a "Frame" photo widget: a warm brown gradient card
(#241C1C to #5B4038) framing a single tasteful lifestyle photo, cream accent type reading
"make it yours". Cozy golden-hour light, editorial, shallow depth of field, minimal wallpaper, 1:1.
```

## 7. Hush (t-hush) - minimal
```
A photorealistic iPhone home screen showing a minimalist "Hush" widget: a near-black card
(#0A0A0A to #1A1A1A) with a single soft gray word "breathe" centered in an elegant serif. Moody
low-key lighting, extreme minimalism, lots of negative space, calm, shallow depth of field, 1:1.
```

## 8. Orbit (t-orbit) - social
```
A photorealistic iPhone home screen with a playful "Orbit" social widget on a deep violet gradient
(#17153B, #2E236C, #433D8B) with soft lilac (#C8ACD6) accents, small floating contact bubbles like
a tiny solar system, and type reading "keep in touch". Playful yet premium, soft glow, shallow
depth of field, minimal wallpaper, 1:1.
```

---

## How to use them
- Generate at 1:1, high resolution. Pick the best per widget.
- Two good uses in the app:
  1. **Detail "In Context" strip** - show the render on the widget detail page.
  2. **Discover hero** - swap the gradient hero for the real render on featured widgets.
- Send the winners back and I'll add an `previewImageURL` (or a bundled asset) to `WidgetTemplate`
  and show it in the catalog. The editable `WidgetContent` stays as-is for the live/editable render;
  these images are just the glossy marketing shots.
```
