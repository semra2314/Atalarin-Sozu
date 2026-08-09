# Live widgets (Aurora + Focus) - Xcode wiring

All the code is written. These steps connect it in Xcode (targets, assets, sounds).

## 1. Share the new files with the widget extension
Select each file, File inspector > Target Membership, tick **both** Widgy and the widget extension
(actual-widgetsExtension):
- `Core/Focus/FocusSession.swift`
- `Core/Focus/FocusIntents.swift`
(`SharedWidgetStore.swift`, `Color+Hex.swift`, `AppFont.swift`, `Theme.swift` should already be shared.)

App-only (leave on Widgy only): `Features/Focus/FocusView.swift`, `Features/Focus/FocusAudioPlayer.swift`.

Add the two widget files to the extension target (like the existing widget file):
- `WidgyWidget/AuroraWidget.swift`
- `WidgyWidget/FocusWidget.swift`

## 2. Share the background images with the extension
The widgets load images by name, so the asset catalog images must be in the extension too.
Easiest: select `Assets.xcassets`, and in Target Membership tick the widget extension as well
(makes all images available to both). The names must match exactly:
- Aurora: `aurora-bg-dawn`, `aurora-bg-morning`, `aurora-bg-midday`, `aurora-bg-sunset`, `aurora-bg-night`
- Focus: `focus-bg-ready`, `focus-bg-deep`, `focus-bg-night`

If your image sets have different names, rename them or update the `backgroundName` switch in
`AuroraWidget.swift` / `FocusWidget.swift`.

## 3. Focus sounds (optional)
Drop these mp3s into the app target (any royalty-free loop works):
`rain.mp3`, `cafe.mp3`, `waves.mp3`, `whitenoise.mp3`.
Missing files are a safe no-op - the picker still works silently.

## 4. Run
- Add the **Aurora** widget: shows the live time + date; the background changes by time of day.
- Add the **Focus Stack** widget: shows a Start button; tap it (or open Focus in the app) to begin a
  session, and it counts down live with a progress bar.
- In the app: Discover > Focus Stack > **Open Focus** to pick a duration + sound and start.

## How it works
- **Aurora**: a per-minute timeline renders the clock; `backgroundName` maps the hour to the right
  aurora image (dawn 5-8, morning 8-11, midday 11-16, sunset 16-20, night 20-5).
- **Focus**: the app (or the widget's Start button via `StartFocusIntent`) writes a `FocusSession`
  into the App Group. The widget uses `Text(endsAt, style: .timer)` and `ProgressView(timerInterval:)`
  to count down live with no polling. When the session ends, the timeline flips back to idle.
- **Friends focusing**: currently a static mock in the large Focus widget. Making it real needs the
  social/backend layer (CloudKit) - who's focusing right now - which we can add later.

## Notes
- Interactive widget buttons (`Button(intent:)`) need iOS 17+ (your target is fine).
- The "friends focusing" avatars are placeholders until the social layer exists.
