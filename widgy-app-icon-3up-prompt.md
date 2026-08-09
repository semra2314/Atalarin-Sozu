# Widgy - App icon: one prompt, 3 concepts

Paste this single block into Stitch/GPT. It returns one image with three iOS app icon
concepts side by side. Pick the winner, send it back, and I'll vectorize it clean and drop it
into the AppIcon set (light/dark/tinted), like before.

```
Create a single image, a clean 3-up comparison sheet showing THREE iOS app icon concepts for a
widget marketplace app called "Widgy", arranged in one horizontal row, equal size, each a
1:1 square with generous spacing on a plain light gray backdrop. Label each one underneath in
small text: "A", "B", "C".

Brand (use exactly, no other vivid colors):
- Warm off-white #FDF8F8, ink #1D1D1F, single coral accent #d44a33.
- Flat vector, no gradients, no shadows, no photographic texture. iOS app icon look: full-bleed,
  square, no pre-rounded corners, mark centered with ~15% safe margin, legible at small size.

Concept A - Monogram: off-white (#FDF8F8) background, a single lowercase letter "w" as a bold
modern geometric sans-serif in coral (#d44a33), centered.

Concept B - Bento widgets: off-white (#FDF8F8) background, an abstract cluster of rounded-square
widget tiles: one large ink (#1D1D1F) tile on the left and two smaller tiles stacked on the
right, the bottom-right tile in coral (#d44a33). Clean geometric spacing.

Concept C - Coral tile: solid coral (#d44a33) background, a single crisp off-white (#FDF8F8)
rounded-square glyph with a smaller square nested in its corner (a widget within a widget),
bold and high-contrast.

All three: flat solid colors only, no text besides the A/B/C labels, sharp vector edges,
instantly recognizable when shrunk to a home-screen icon.
```

---

## After you pick one
Send the winning concept (or the whole sheet, telling me which). I'll redraw it as a crisp
vector, export a 1024 master with no transparency, and generate the light / dark / tinted
variants straight into `AppIcon.appiconset` - same pipeline we used for the wordmark icon.
