# Widgy app icon - light / dark / tinted (Stitch, one prompt)

Locked logo: the word "widgy" in the Fraunces serif typeface, with the dot (tittle) over the
letter "i" replaced by a coral (#d44a33) rounded square. This prompt renders the three iOS
appearance variants in one image.

```
Create a single image: a clean 3-up sheet of ONE iOS app icon in its three appearance modes,
arranged in a horizontal row of equal 1:1 squares on a plain neutral backdrop, labelled
underneath "Light", "Dark", "Tinted".

The icon is a wordmark: the lowercase word "widgy" set in the Fraunces serif typeface (soft,
slightly wonky optical style), bold, centered on a single line, filling the width within a ~16%
safe margin. The dot over the letter "i" is replaced by a small rounded-square tile in coral
(#d44a33). Flat vector, no gradients, no shadows, no texture; full-bleed square, no pre-rounded
corners (iOS masks them).

Render the SAME wordmark three times, changing only the colours:
1. Light: background warm off-white #FDF8F8, the word "widgy" in ink #1D1D1F, the "i" square coral #d44a33.
2. Dark: background ink #1D1D1F, the word "widgy" in off-white #FDF8F8, the "i" square stays coral #d44a33.
3. Tinted (monochrome for iOS tinting): background pure black #000000, the word "widgy" in light
   gray #B8B8B8, the "i" square in white #FFFFFF (brightest element). No colour in this one.

Identical letterforms, layout and proportions across all three; only colours differ. Sharp
vector edges, no extra text besides the Light/Dark/Tinted labels.
```

---

## Notes
- Heads up: a full wordmark gets small on a 60x60 home-screen icon. If it feels too tight, we can
  also make a compact icon (just a Fraunces "w" + the coral square) for small sizes later.
- When Stitch gives you the sheet, send it back. I'll cut the three tiles, redraw them crisp at
  1024 (no transparency), and drop Light/Dark/Tinted straight into `AppIcon.appiconset` - same
  pipeline as before. I can also regenerate the `WidgyWordmark` asset in Fraunces so the in-app
  logo matches this exactly.
```
