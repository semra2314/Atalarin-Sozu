# Widgy — Custom Widget Editor, all five tabs (Stitch.ai)

The editor is one screen with two fixed zones: a canvas on top that never scrolls away, and a
tabbed control panel below. Only the panel scrolls. These five prompts are the same screen with
a different tab active — generate all five so the set is consistent.

Every control listed below **already exists in the app**. Nothing here is aspirational, so
whatever Stitch returns can be implemented as-is. Don't add controls that aren't listed; if a
design invents one, we'd have to either build it or drop it, and both cost us.

---

## Block A — Design tokens (paste into every prompt)

```
Design tokens (match exactly, no other vivid colors):
- Background #FDF8F8, card surface #FFFFFF, muted surface #F1EDEC
- Primary/ink text #1D1D1F, secondary text #5E5E63, border/hairline #E5E2E1
- Accent (the ONLY vivid color) #D44A33 — active tab, selected states, slider fills, Save
- Headings: Fraunces (serif). All controls, labels and body: DM Sans
- Card radius 20px, sheet top radius 24px, chips/buttons fully rounded, swatch chips 12px
- Soft shadow 0 10 30 rgba(0,0,0,0.04)
- Do not use any Tailwind default color: blue-*, purple-*, emerald-*, rose-*, indigo-*
- iPhone 393x852, light mode only
```

## Block B — The shell (identical in all five, paste into every prompt)

```
TOP BAR (h 64): a back chevron in a white circle on the left, "Editor" centred in Fraunces
semibold, and "Save" on the right in accent #D44A33, medium weight, no button fill.

CANVAS ZONE (45% of the screen height, directly under the top bar): a full-bleed warm grey
gradient from #EFE9E7 at the top to #E2DAD8 at the bottom. Centred in it, a single square
widget preview card (155x155) with an iOS continuous corner radius of 22px and a soft drop
shadow. Inside the card: a short serif headline in white on a warm gradient, one small photo
placed off-centre with rounded corners, and one small coral star glyph in the top right — so
text, photos and stickers are all visibly on the same canvas. The photo carries a thin 2px
coral selection outline with four small white round handles at its corners.
Along the bottom of the canvas zone, three fully-rounded size chips in a row: Small (filled
coral, white text), Medium and Large (white fill, hairline border, secondary text).

CONTROL PANEL (the remaining 55%): a white sheet with a 24px top radius and a soft upward
shadow. At its top, a centred grey drag handle (48x5, fully rounded). Under that, a
horizontally scrollable tab row with five items: Text, Style, Background, Photos, Stickers.
The active tab is accent #D44A33, bold, with a 2px accent underline directly beneath it; the
others are secondary grey, medium weight, no underline. A hairline sits under the whole tab
row. Panel content below scrolls.

SLIDERS (used in several tabs) all share one row layout: a small grey glyph on the left, then
a column containing a top line with the control's name on the left and its current value on
the right (both 12px DM Sans, secondary grey), and beneath it the track — 6px tall, fully
rounded, unfilled part #F1EDEC, filled part accent #D44A33, with a white circular knob that
has a 2px accent border and a soft shadow.
```

---

## Prompt 1 — Text tab

```
[paste Block A]
[paste Block B, with the "Text" tab active]

The Text panel contains, top to bottom, with 24px between groups:

1. A tiny uppercase letter-spaced label "YOUR WORDS" in secondary grey, then a multi-line text
   field on the muted surface #F1EDEC with 20px radius and comfortable padding, showing two
   lines of sample text in ink.

2. A tiny uppercase label "TEXT COLOUR", then a single horizontally scrolling row of ten round
   colour swatches (34px), each with a hairline ring. Colours in order: white, near-black,
   coral, grey, off-white, warm cream, sky blue, mint green, amber, lilac. The selected one
   (white) has a 3px coral ring around it.

3. A single toggle row on a white surface: a small half-filled-circle glyph, the label
   "Shade behind text" in ink, and an iOS-style toggle on the right, switched on and coral.

Nothing else in this tab.
```

## Prompt 2 — Style tab

```
[paste Block A]
[paste Block B, with the "Style" tab active]

The Style panel contains, top to bottom, with 20px between controls:

1. A tiny uppercase label "STYLE".

2. A full-width iOS segmented control with four equal options: Serif, Rounded, Mono, Sans.
   "Serif" is selected — selected segment is a white pill with a soft shadow on a #F1EDEC track.

3. A second full-width segmented control, four options: Light, Medium, Bold, Heavy.
   "Bold" selected, same styling.

4. Two smaller segmented controls side by side on one row, each taking half the width:
   - left: three text-alignment glyphs (align left, align centre, align right), centre selected
   - right: three vertical-position glyphs (arrow to top line, up-and-down arrow, arrow to
     bottom line), the first selected

5. A slider row labelled "Size", value "22", with a small "smaller A" glyph on the left end and
   a "larger A" glyph on the right end of the row.

6. A slider row labelled "Line spacing", value "4", with a minus glyph on the left and an
   up-and-down arrow glyph on the right.

Nothing else in this tab.
```

## Prompt 3 — Background tab

```
[paste Block A]
[paste Block B, with the "Background" tab active]

The Background panel contains, top to bottom:

1. A full-width button (h 48) on the muted surface #F1EDEC with 20px radius: a photo glyph and
   the text "Use a photo" in ink, centred.

2. Three groups of gradient swatches. Each group is a tiny uppercase secondary-grey label
   followed by a horizontally scrolling row of five rounded-square gradient chips (44x44,
   12px radius):
   - NEUTRAL: charcoal-to-grey, near-black, off-white-to-warm-grey, dark grey, light warm grey
   - WARM: coral-to-rust, amber-to-ochre, blush-to-terracotta, deep brown, cream-to-tan
   - COOL: indigo-to-pink, charcoal-navy, deep violet, forest green, pale sky blue
   The first NEUTRAL chip is selected and carries a 3px coral ring.

3. A tiny uppercase label "DIRECTION", then a full-width segmented control with four options,
   each a small arrow glyph: down-right diagonal, straight down, down-left diagonal, and
   straight right. The first is selected.

Nothing else in this tab.
```

## Prompt 4 — Photos tab

```
[paste Block A]
[paste Block B, with the "Photos" tab active]

The Photos panel contains, top to bottom:

1. A row starting with a square "Add" button (64x64, 16px radius, muted surface, hairline
   border) containing a small add-photo glyph over the tiny word "Add"; then, to its right, a
   horizontally scrolling strip of three 64x64 rounded photo thumbnails. The first thumbnail is
   selected and ringed in 2px coral.

2. Four slider rows in the shared slider style, in this order:
   - "Size", value "100%", glyph: photo-size
   - "Rotation", value "0°", glyph: rotate-right
   - "Corners", value "12px", glyph: rounded-corner
   - "Opacity", value "100%", glyph: opacity droplet

3. Pinned to the very bottom of the panel above the home indicator, a sticky action bar
   separated by a hairline: two equal-width fully-rounded buttons side by side —
   "Duplicate" with a copy glyph on the muted surface in ink, and "Delete" with a trash glyph
   on a soft coral tint (#D44A33 at 12% opacity) in coral text.

Nothing else in this tab.
```

## Prompt 5 — Stickers tab

```
[paste Block A]
[paste Block B, with the "Stickers" tab active]

The Stickers panel contains, top to bottom:

1. Three groups of glyphs. Each is a tiny uppercase secondary-grey label followed by a
   horizontally scrolling row of eight 44x44 rounded-square tiles (12px radius, muted surface
   #F1EDEC), each holding one thin black glyph:
   - NATURE: sun, moon, cloud, snowflake, leaf, flame, water drop, wind
   - FEELING: heart, star, sparkles, smiling face, clapping hands, party popper, quote mark,
     peace sign
   - DAILY: check seal, lightning bolt, music note, book, coffee cup, walking figure, clock,
     calendar

2. A hairline divider, then a tiny uppercase label "SELECTED STICKER", then:
   - a horizontally scrolling row of ten round colour swatches (34px), the coral one selected
     with a 3px coral ring
   - a slider row "Size", value "1.0x", magnifier-minus and magnifier-plus glyphs at the ends
   - a slider row "Rotation", value "0°", rotate-left and rotate-right glyphs
   - a slider row "Opacity", value "100%", dotted-circle and filled-circle glyphs

3. The same sticky Duplicate / Delete action bar as the Photos tab, pinned to the bottom.

Nothing else in this tab.
```

---

## Implementation notes (for us, not for Stitch)

- **Slider value readouts** — the approved Photos design shows the current value on the right of
  each slider label ("100%", "0°", "12px"). Our sliders don't show values yet; that's being
  added so the build matches.
- **The sticky action bar only appears when something is selected.** An always-visible
  Duplicate/Delete with nothing to act on is dead weight, and Stitch won't know that from a
  static mock.
- **Tab row scrolls horizontally** rather than compressing five labels to fit. It'll grow.
- Colours and radii above come from `Theme.swift`. If that file changes, change Block A too.
