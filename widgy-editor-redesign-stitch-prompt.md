# Widgy — Custom Widget Editor redesign (Stitch.ai)

## Why we're redesigning

The editor grew feature by feature and now it's one long scroll of stacked control groups —
text, style, colour, background, photos, stickers, and the selected-element sliders all pile up
vertically. On a phone you scroll a lot and lose sight of the canvas, which is the one thing you
actually need to watch while designing.

The goal isn't more controls. It's **the canvas staying visible while you work**, with controls
grouped into a bottom panel you switch between — the way Instagram, Canva and iOS's own photo
editor do it.

## Fixed design tokens (paste into every prompt)

```
Design tokens (match exactly, no other vivid colors):
- Background #FDF8F8, card surface #FFFFFF, muted surface #F1EDEC
- Primary/ink text #1D1D1F, secondary text #5E5E63, border #E5E2E1
- Accent (only vivid color) #D44A33 — CTAs, active tabs, selected states, slider fills
- Headings: Fraunces (serif), body/labels/controls: DM Sans
- Card radius 16-24px, chips and buttons fully rounded, soft shadow 0 10 30 rgba(0,0,0,0.04)
- Do not use any Tailwind default color: blue-*, purple-*, emerald-*, rose-*, indigo-*
```

## What the editor has to support (don't drop any of these)

- **Canvas** — a live widget preview on a home-screen-like backdrop, at Small / Medium / Large.
- **Text** — the words, font family (Serif / Rounded / Mono / Sans), weight (Light / Medium /
  Bold / Heavy), size, line spacing, horizontal align, vertical align, colour, and a
  "shade behind text" toggle for legibility.
- **Background** — a photo, or a gradient from a grouped palette (Neutral / Warm / Cool), plus
  gradient direction.
- **Photos** — photos placed *on* the canvas: add, drag to position, then size, rotation, corner
  radius, opacity, duplicate, delete.
- **Stickers** — SF Symbol glyphs grouped by theme (Nature / Feeling / Daily): add, drag, then
  colour, size, rotation, opacity, duplicate, delete.
- **Selection** — tapping an element on the canvas selects it; its controls appear.

---

## Prompt 1 — Editor, main screen

```
Design a single iOS screen (iPhone 393x852, light mode): the widget editor for "Widgy", a widget
marketplace app, in a calm editorial App Store style.

[paste fixed design tokens block]

The screen is split into two fixed zones — the canvas must never scroll out of view:

TOP ZONE (about 45% of the height):
- A soft rounded rectangle "home screen" backdrop in a warm grey gradient (#EFE9E7 to #E2DAD8),
  filling the width with generous margins.
- Centred on it, a single widget preview card with a realistic iOS continuous corner radius and
  a soft drop shadow. Inside it: a short serif headline over a warm gradient, one small photo
  placed off-centre with rounded corners, and one small coral star glyph — showing that text,
  photos and stickers all live on the same canvas.
- The selected element (the photo) has a thin coral selection outline with small round handles
  at its corners.
- Directly under the canvas, a row of three fully-rounded size chips: Small / Medium / Large,
  with Small active in coral.

BOTTOM ZONE (the control panel, about 55%):
- A white sheet with a 24px top radius and a soft shadow, sitting flush to the bottom.
- Along its top edge, a horizontally scrollable tab bar of 5 icon+label tabs:
  Text (textformat), Style (paintbrush), Background (square.on.square), Photos (photo),
  Stickers (face.smiling). The active tab ("Photos") is coral with a small coral underline;
  the rest are secondary grey.
- Below the tabs, the Photos panel: a full-width muted "Add a photo" button with a plus icon,
  then a horizontal strip of already-added photo thumbnails (rounded squares, the selected one
  ringed in coral), then four labelled sliders — Size, Rotation, Corners, Opacity — each with a
  small grey icon on either end and a coral filled track.
- At the very bottom of the panel, two text buttons: "Duplicate" on the left with a copy icon,
  "Delete" on the right in coral with a trash icon.

Top app bar: a back chevron in a white circle on the left, "Editor" centred in Fraunces, and a
coral "Save" pill button on the right.

Calm, generous whitespace, single accent colour, nothing decorative.
```

---

## Prompt 2 — The Text panel (same screen, different tab)

```
[paste fixed design tokens block]

Design the same iOS widget editor screen, but with the "Text" tab active in the bottom panel.

The top canvas zone is unchanged (widget preview on a warm grey home-screen backdrop, size chips
underneath).

The Text panel contains, top to bottom:
- A multi-line text field on a muted surface with rounded corners, showing a two-line sample.
- "Font" as a segmented control with four options: Serif, Rounded, Mono, Sans.
- "Weight" as a segmented control: Light, Medium, Bold, Heavy.
- Two small segmented controls side by side: horizontal alignment (left/centre/right icons) and
  vertical position (top/middle/bottom arrow icons).
- Two labelled sliders with icons on each end: Size and Line spacing.
- A horizontally scrolling row of round colour swatches, the selected one ringed in coral.
- A single toggle row: "Shade behind text" with a small icon, coral when on.

Same calm editorial style, same tab bar across the top of the panel.
```

---

## Prompt 3 — The Background panel

```
[paste fixed design tokens block]

Design the same iOS widget editor screen with the "Background" tab active.

The Background panel contains:
- A full-width "Use a photo" button with a photo icon on a muted surface.
- Three labelled groups of gradient swatches, each a horizontally scrolling row of rounded
  square gradient chips (44x44), with a tiny uppercase group label above:
  Neutral, Warm, Cool. The selected chip has a 3px coral ring.
- A segmented control for gradient direction, showing four small arrow icons
  (diagonal, down, other diagonal, right).

Same canvas on top, same tab bar, same calm editorial style.
```

---

## Notes for whoever wires this up

- The tabbed bottom panel is the whole point: the current build stacks every group in one long
  scroll, so the canvas disappears the moment you adjust anything below the fold.
- Keep the canvas fixed and only let the panel scroll. Element selection has to feel direct —
  tap something on the canvas, its controls appear in the matching tab.
- The panel's tab bar should scroll horizontally rather than squeezing five labels into the
  width; it will grow as more element types are added.
- Sizes and colours in the prompts follow `Theme.swift`; keep them in sync if that file changes.
