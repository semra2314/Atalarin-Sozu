# Widgy - Time-of-day backgrounds (GPT / DALL-E) for Aurora & Focus

Generate these as **backgrounds only — NO text, no numbers, no UI, no app icons**. The live widget
overlays the time/date/progress on top. High resolution, smooth gradients, continuous soft shapes.

Aspect: generate 1:1 (square). The widget aspect-fills them for Small/Medium/Large, so keep the
important detail (sun/moon, horizon) roughly centered / lower third, not at the very edges.

Save each with the exact asset name in brackets so I can map it to the clock by hour.

---

## Aurora - 5 time-of-day backgrounds

Consistent world across all five: soft rolling hills at the bottom third, a smooth aurora sky,
one celestial body (sun or moon). Same art style, only the light/colour and sun position change.

**[aurora-bg-dawn]** (approx 5:00-8:00)
```
A serene 1:1 gradient landscape background, no text: a pre-dawn sky shifting from deep indigo
#1E1A4A at the top to soft rose #E58BA0 near the horizon, gentle dark violet rolling hills at the
bottom third, a small pale sun just rising at the horizon with a soft glow. Smooth, minimal,
premium, no UI, no words.
```

**[aurora-bg-morning]** (approx 8:00-11:00)
```
A serene 1:1 gradient landscape background, no text: a fresh morning aurora sky from indigo
#2C1E5C through violet #7B3FA0 to warm pink #E0639A, soft violet hills at the bottom, a glowing
cream sun #FFE0A8 low on the right. Smooth, minimal, premium, no UI, no words.
```

**[aurora-bg-midday]** (approx 11:00-16:00)
```
A serene 1:1 gradient landscape background, no text: a bright airy midday sky, lavender #8E7BD6
to soft peach #FBD9B8, pale distant hills, a high bright cream sun. Light, open, premium, no UI,
no words.
```

**[aurora-bg-sunset]** (approx 16:00-20:00)
```
A serene 1:1 gradient landscape background, no text: a warm sunset aurora, deep magenta #7B2E6B
to burnt orange #E86A3A to gold near the horizon, silhouetted violet hills, a large soft sun
setting behind the hills. Rich, calm, premium, no UI, no words.
```

**[aurora-bg-night]** (approx 20:00-5:00)
```
A serene 1:1 gradient landscape background, no text: a deep night sky, near-black indigo #0E0B2A
to muted violet #3A2A6B, dark rolling hills, a soft glowing moon and a scatter of faint stars.
Quiet, premium, no UI, no words.
```

---

## Focus - 3 mood backgrounds (by session state / time)

Deep charcoal-navy world, cyan energy. Same style, only intensity changes. No text.

**[focus-bg-ready]** (idle / before a session)
```
A 1:1 dark background, no text: deep charcoal navy #10151F to #1E2B3C, a very subtle soft cyan
#4CC9F0 glow low and faint, calm and still. Minimal, premium, no UI, no words.
```

**[focus-bg-deep]** (session in progress)
```
A 1:1 dark background, no text: deep charcoal navy #0C111B, a focused cyan #4CC9F0 radial glow
concentrated in the center-right, quiet energy, subtle depth. Minimal, premium, no UI, no words.
```

**[focus-bg-night]** (late / evening focus)
```
A 1:1 dark background, no text: near-black #07090F with a cool muted cyan-teal haze low in the
frame, deep and calm for late-night focus. Minimal, premium, no UI, no words.
```

---

## How I'll wire it (once you add the assets)
- **Aurora**: the widget picks the background by the current hour — dawn 5-8, morning 8-11,
  midday 11-16, sunset 16-20, night 20-5 — and overlays the live time + date. Updates each minute.
- **Focus**: the widget uses `focus-bg-ready` when no session, `focus-bg-deep` while a session
  runs, and `focus-bg-night` after ~20:00, overlaying the live remaining time + progress.

## Flow
1. Generate these in GPT/DALL-E (backgrounds only), add to the asset catalog with the bracketed names.
2. Optionally feed one into Stitch to design the S/M/L text overlay layout (from the earlier prompt).
3. Send them back / confirm the names, and I'll build the live Aurora + Focus widgets that swap
   backgrounds automatically.
