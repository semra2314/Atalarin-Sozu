# Widgy - Live widgets, all sizes (Stitch) - Batch 1: Aurora + Focus

Design each widget at its three iOS sizes (Small 1:1, Medium ~2.1:1, Large ~1:1.05) as one
3-up sheet, labelled "Small / Medium / Large". These are references for the live SwiftUI widgets
I'll build. Keep the exact colours; the dynamic values (time, date, progress) are placeholders
that will be wired to real data.

Shared: iOS home-screen widget look, continuous-rounded corners, no app chrome, flat premium,
readable at small size. Match the reference renders already in the asset catalog.

---

## 1. Aurora - clock & date (LIVE: system time + date)

Colours: aurora gradient indigo #2C1E5C -> violet #7B3FA0 -> warm pink #E0639A; text warm-cream
#FFF3E0 / white; small cream sun #FFE0A8.

```
Design one image: three iOS widget sizes side by side for an "Aurora" clock widget, labelled
Small / Medium / Large, on a light backdrop.

All three share a smooth aurora gradient background (deep indigo #2C1E5C to violet #7B3FA0 to
warm pink #E0639A) with soft rolling hills at the bottom and a small glowing cream sun (#FFE0A8),
continuous-rounded corners.

- Small (1:1): a large time "09:41" in an elegant light serif, with a short weekday+date line
  "Tue 22" beneath. Minimal, just time + date, the sun peeking in a corner.
- Medium (2.1:1): left side has a light-serif greeting "Good morning", a large time "09:41", and
  a date "Tue, 22 July"; right side shows the sun over the hills. (Matches the Aurora render.)
- Large (1:1.05): the full aurora scene taller, greeting + big time + date top-left, the sun arc
  and hills filling the lower half, plenty of atmosphere.

Text is warm cream/white, softly legible. No app icons, no status bar. Premium and calm.
```

## 2. Focus Stack - focus timer (LIVE: app-driven session via App Group)

Colours: deep charcoal-navy card #10151F -> #1E2B3C; white text; cyan accent #4CC9F0; muted
secondary #8A93A3.

```
Design one image: three iOS widget sizes side by side for a "Focus Stack" timer widget, labelled
Small / Medium / Large, on a light backdrop.

All three use a deep charcoal-navy card (#10151F to #1E2B3C), white type, a cyan (#4CC9F0) accent,
continuous-rounded corners.

- Small (1:1): a circular cyan progress ring around a big remaining time "45m", tiny label
  "Deep work" beneath. Compact.
- Medium (2.1:1): title "Deep work" top-left, a small cyan status dot with "In progress", a thin
  cyan progress bar, "45 min / 90 min" below it, and a muted "Stay focused." line. (Matches the
  Focus Stack render.)
- Large (1:1.05): same as medium but taller, with an added row of small session dots or a simple
  list ("Session 3 of 4") and a bigger progress ring on the right.

Clean, focused, cool lighting. No app icons, no status bar.
```

---

## What I'll build from these
- Each becomes a real WidgetKit widget kind supporting `.systemSmall/.systemMedium/.systemLarge`.
- **Aurora**: reads the live system clock + calendar (updates every minute via a timeline).
- **Focus**: the app starts/stops a focus session; state is shared through the App Group and the
  widget renders live remaining time + progress.
- Both need zero extra permissions or APIs, so they're fully working for the demo.

## Next batches (after these two)
- Hush (daily quote) - easy, no deps.
- Drift (weather) - needs WeatherKit. Pulse (health) - HealthKit. Ledger (finance) - a market API.
  Frame (photo) - Photos picker. Orbit (social) - contacts/social layer.
Tell me which batch to prep next and I'll write those prompts + wire the data.
