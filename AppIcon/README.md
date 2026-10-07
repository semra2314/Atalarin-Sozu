# Kare app icon — Icon Composer layers

## Why these are SVGs and not a picture of glass

The glassmorphic icon is not artwork you draw. Since iOS 26 you hand Xcode a
layered `.icon` file and the system applies the glass material, the blur, the
specular highlight and the edge refraction **at render time**, against whatever
is behind the icon. It also derives the Clear and Tinted appearances itself.

So asking an image model for a "glassmorphic app icon" produces a flat picture
of glass, which iOS then puts real glass on top of. Two layers of glass, one of
them fake and lit from the wrong angle. It looks worse than no glass at all,
and it is the fastest way to make a new app look like a template.

What the system needs from us is separation: a background it can refract, and a
foreground it can float above. That is what these files are.

## The files

| file | layer | used for |
|---|---|---|
| `background-default.svg` | background | Default |
| `background-dark.svg` | background | Dark |
| `foreground.svg` | foreground | Default and Dark |
| `foreground-mono.svg` | foreground | Mono, from which Tinted is derived |

Vector, not PNG: Icon Composer accepts both but prefers SVG because it scales
without resampling, and because the glass effect samples the shape rather than
the pixels.

The wordmark is the real `Fraunces_72pt_Soft-Black.ttf` from `Widgy/Resources/
Fonts/`, converted to outlines with its actual kerning, sized so the word fills
76% of the canvas. It was checked against the installed PNG and matches to
within 1.4/255 per channel, which is antialiasing and nothing else. There is no
live text and no font dependency in the output.

## Assembling it

1. Open **Icon Composer** (ships with Xcode 26).
2. New icon, name it `Kare`.
3. Drag `background-default.svg` in as the bottom layer, `foreground.svg` above it.
4. Switch to the **Dark** appearance and swap the background for `background-dark.svg`.
5. Switch to **Mono** and use `foreground-mono.svg`.
6. Leave the glass properties alone on the first pass. Look at it on a real
   device against a photo wallpaper before you touch specular or blur, because
   they are tuned for the default and every change you make is a change you
   have to justify on six appearances, not one.
7. Save the `.icon` into the project and set it as the app icon in the target's
   build settings.

## Keep the PNGs for now

`Widgy/Assets.xcassets/AppIcon.appiconset` still holds the flat 1024x1024
light/dark/tinted set. Do not delete it until you have confirmed in Xcode which
one your deployment target actually uses. If Kare supports anything older than
iOS 26, those PNGs are what those devices show.

## If you want to change the design

Rerun the generator rather than editing the SVG by hand, so the PNG set and the
vector layers never drift apart:

- word size: the `TARGET` fraction
- colours: the hexes in `files`
- the word itself: `text`

Both outputs come from the same font file and the same measurements, which is
the only reason they agree.
