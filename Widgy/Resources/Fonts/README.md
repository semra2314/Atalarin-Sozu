# Fonts

The design uses **Fraunces** (serif display/headings) and **DM Sans** (body/labels).

## Bundled now
- **Fraunces 72pt Soft** — Regular, SemiBold, Bold, Black (the four weights the UI uses).
  Registered at launch by `FontRegistrar.registerBundledFonts()` and picked up by
  `AppFont.serif(...)`, which maps each weight to the matching PostScript name.

## Optional: DM Sans
Body/labels currently render in SF Pro (very close to DM Sans). To use the real thing,
drop `DMSans-Regular.ttf` (and other weights) into this folder. `AppFont.sans(...)`
finds it automatically — no code change. If the PostScript name differs, add it to
`sansCandidates` in `DesignSystem/AppFont.swift`.

The Xcode target uses a file-system-synchronized group, so files added here are
included in the bundle automatically — no drag-into-Xcode, no Info.plist editing.
