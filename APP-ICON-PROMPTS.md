# Kare app icon — prompts

Brand colours, taken from `Theme.swift` so nothing drifts:

| | hex |
|---|---|
| accent (the only vivid colour) | `#D44A33` |
| ink | `#1D1D1F` |
| warm off-white | `#FDF8F8` |
| muted surface | `#F1EDEC` |

The name means "square" in Turkish, and a widget is literally a square you
place on a home screen. The icon should be that square. Resist the urge to add
a gradient, a sparkle or a magic wand: the App Store is full of widget apps
that all look like the same purple gradient, and the whole visual identity of
Kare is one warm coral against paper.

---

## Main prompt

> A minimalist iOS app icon, 1024x1024 pixels, flat vector style.
>
> A single solid square with softly rounded corners, coloured warm terracotta
> red `#D44A33`, centred on a plain warm off-white background `#FDF8F8`. The
> square occupies roughly 46% of the canvas width and is perfectly centred,
> with generous even margins on all four sides.
>
> Inside the terracotta square, in its upper-left area, sits one much smaller
> square in the same off-white as the background, about 22% the size of the
> large square, with the same softly rounded corners. It reads as a small
> window cut out of a larger one.
>
> Absolutely flat: no gradient, no gloss, no drop shadow, no inner shadow, no
> texture, no noise, no bevel, no outline, no highlights. Pure geometric shapes
> and two flat colours only. Crisp, precise edges. Perfectly symmetrical.
>
> No text, no letters, no numbers, no logos, no icons, no illustration, no
> people, no gadgets, no phone mockups. The background must fill the entire
> square canvas edge to edge with no rounded corners and no transparency.
>
> Style reference: Braun product design, Swiss graphic design, Dieter Rams.
> Calm, editorial, confident, expensive-looking. Museum poster, not app store.

---

## Two alternates worth trying

**A. Stacked squares** — says "a collection of widgets" rather than "one widget".

> ...three squares with softly rounded corners arranged in a loose overlapping
> stack, slightly offset from each other like cards on a table. The front
> square is terracotta `#D44A33` and fully opaque; the two behind it are the
> same shape in `#F1EDEC` and `#E5E2E1`, peeking out at the top-right. Flat
> vector, no shadows...

**B. The negative square** — quieter and more premium, and reads well tiny.

> ...one large terracotta `#D44A33` square with softly rounded corners filling
> most of the canvas, on a warm off-white `#FDF8F8` background. A smaller
> square is punched cleanly out of its centre, revealing the off-white
> background through it, like a frame or a window. Perfectly concentric...

---

## Append this to every prompt

> Square 1:1 composition, 1024x1024. The artwork must bleed to all four edges
> of the canvas with no rounded corners, no border, no transparency and no
> alpha channel: iOS applies its own corner mask. Do not draw a phone, a home
> screen, a device frame, or a picture of an app icon. Do not add a shadow
> under the shape. Render the icon itself, filling the frame.

---

## You need three files, not one

`AppIcon.appiconset` already expects the iOS 18 set:

| file | what changes |
|---|---|
| `AppIcon-light.png` | the main prompt as written |
| `AppIcon-dark.png` | background becomes near-black `#1D1D1F`; the small inner square becomes `#1D1D1F` too, so it still reads as a cut-out. Terracotta stays exactly `#D44A33`. |
| `AppIcon-tinted.png` | **greyscale only.** iOS tints this itself. Shape on mid-grey `#8A8A8A`, background black. Any colour here will fight the user's chosen tint. |

Generate the light one first, get the geometry right, then ask for the same
composition recoloured. Do not let it redraw from scratch each time or the
proportions will drift between the three and you will see it flicker as the
user switches appearance.

---

## Reject it if

- the corners of the canvas are rounded or transparent (it drew the mask for you)
- there is a shadow under the square
- there is any gradient, however subtle
- the terracotta is not `#D44A33` (check with a colour picker; models drift towards orange)
- it is not perfectly centred, or the two squares are not concentric/aligned
- it stops reading as anything at 29x29 — shrink it and look before you commit

---

## Direction: mascot

Worth doing, and not for the icon. You are launching on TikTok and Instagram,
and a character gives you something no logo can: a recurring face for short
video, stickers, reaction cuts, empty states, error screens. The logo cannot
be sad about a failed upload. A character can.

The trap is that mascots read cheap or childish when the character is a
creature *holding* a square. It has to **be** the square. Then it is still the
brand mark, just alive.

### A. Icon-safe version (silhouette stays a clean square)

> A minimalist iOS app icon, 1024x1024, flat vector style. A single warm
> terracotta `#D44A33` square with softly rounded corners, centred on a plain
> warm off-white `#FDF8F8` background, occupying about 52% of the canvas.
>
> The square is a character: it has exactly two small oval eyes in off-white
> `#FDF8F8`, placed in the upper third, evenly spaced, looking straight ahead.
> Calm and content, not excited. No mouth, no eyebrows, no cheeks, no blush,
> no nose, no arms, no legs, no outline.
>
> The outer silhouette must remain a perfect rounded square. Absolutely flat:
> no gradient, no shadow, no gloss, no texture, no highlight in the eyes.
> Two flat colours only. Crisp geometric edges.
>
> Style reference: Swiss graphic design meets minimal character design. Quiet,
> confident, a little deadpan. Not cartoonish, not kawaii, not 3D, not glossy.

### B. Full character, for social only

Same character, more freedom, because it will never be shown at 29 pixels.

> A flat vector character illustration on a warm off-white `#FDF8F8`
> background. The character is a warm terracotta `#D44A33` rounded square with
> two simple off-white oval eyes and short, thin, dark `#1D1D1F` stick arms and
> legs. It is standing calmly. Flat 2D, no gradient, no shadow, no outline,
> thick confident shapes, generous negative space. Deadpan and charming rather
> than cute. Full body, centred, plenty of margin.

Then ask for the same character in a set: waving, holding a small square,
sleeping, confused, celebrating. Those become your sticker pack and your empty
states. Ask for them **in one image as a sheet** so the model keeps the
character consistent; generating them one at a time is how a mascot ends up
with a different face in every post.

### Be honest with yourself about this one

A mascot is a commitment, not a decoration. If it only appears on the icon and
nowhere else it will look like an app that could not decide what it was. Use
it or drop it.

---

## Direction: wordmark (Fraunces)

Already rendered, from the real `Fraunces_72pt_Soft-Black.ttf` in this repo,
so the letterforms are genuinely ours rather than a model's impression of a
serif. See `sheet-wordmark.png` and `sheet-tiny.png`.

The 29x29 test settles it: **the full word "kare" turns to mush.** The letters
are 4 pixels tall in the Settings list and Spotlight. The single K survives
easily, and the K inside a coral square survives best of all, because it keeps
the square that the name actually means.

If you want a wordmark icon, `K-in-square` is the one. Say the word and I will
produce the light, dark and tinted variants at exactly 1024x1024, no alpha.

---

## If the generated ones come out wobbly

They probably will. This is pure geometry with two flat colours, which is the
one thing image models are worst at and code is best at. Ask me and I will
render all three variants exactly: true `#D44A33`, mathematically centred,
continuous corner curves matching iOS, correct pixel dimensions, no alpha.
Takes a minute and the edges will be perfect.
