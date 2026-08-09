# Widgy - Profile & Settings page prompts

Same brand as the app: warm off-white, single coral accent, Fraunces headings, DM Sans body.
Paste a block into Stitch/GPT, then we translate the result into SwiftUI.

## Fixed design tokens (in every prompt)

```
Design tokens (match exactly, no other vivid colors):
- Background #FDF8F8, card surface #FFFFFF, muted surface #F1EDEC
- Primary/ink text #1D1D1F, secondary text #5E5E63, border #E5E2E1
- Accent (only vivid color) #d44a33, used only for CTAs, active states, ratings, the "i" dot
- Headings: Fraunces (serif, soft/wonky), body/labels: DM Sans
- Card radius 16-24px, buttons/chips fully rounded, soft shadow 0 10 30 rgba(0,0,0,0.04)
- Do not use any Tailwind default color.
```

## Fixed bottom navigation (identical on every screen)

```
Bottom tab bar, frosted white glass, 5 items evenly spaced, each an icon over a tiny
uppercase label: Discover (square.grid), Widgets (rectangle.stack), Profile (person),
Search (magnifier), Settings (gear). Active item uses accent #d44a33 with a filled icon;
inactive items are secondary gray. Profile sits in the middle.
```

---

## Prompt 1 - Profile

```
Design a single iOS screen (iPhone 393x852, light mode): the Profile page for "Widgy", a
widget marketplace, in a calm editorial App Store style.

[paste the fixed design tokens block]
[paste the fixed bottom navigation block, with Profile active]

Layout, top to bottom:
- Glass top app bar titled "Profile" (Fraunces), a small gear icon on the right.
- Centered avatar: a circle with a coral tinted fill and a serif monogram, white ring, soft shadow.
- Name in Fraunces, "@handle" in secondary DM Sans.
- A white rounded stats card with three columns divided by hairlines: Widgets, Made, Favorites,
  each a big Fraunces number over a tiny uppercase label.
- "My Widgets" section header (Fraunces) with a horizontal scroll of the user's widget tiles
  (rounded square previews with the widget name beneath).
- "Saved Collections" as a 2-column grid of rounded cards (optional).
Calm, generous whitespace, single accent only.
```

## Prompt 2 - Settings

```
Design a single iOS screen (iPhone 393x852, light mode): the Settings page for "Widgy" in a
calm editorial App Store style.

[paste the fixed design tokens block]
[paste the fixed bottom navigation block, with Settings active]

Layout:
- Glass top app bar titled "Settings" (Fraunces).
- Grouped white rounded cards, each group under a tiny uppercase section label:
  - Preferences: Notifications (toggle), iCloud Sync (toggle), Appearance (chevron row).
  - Account: Account, Purchases, Privacy (chevron rows).
  - Support: Help & Support, Rate Widgy, Terms & Privacy Policy (chevron rows).
- Each row: a small rounded square icon badge (muted surface), a DM Sans title, and either a
  coral toggle or a gray chevron. Hairline dividers between rows, indented past the icon.
- A muted "Widgy v1.0" line at the bottom.
Only the toggles and active states use the accent #d44a33.
```

---

## Notes
- The app already has working Profile and Settings screens in this style; these prompts are to
  push the polish (illustrations, collections grid, richer header). Bring the results back and
  I'll fold the good parts into the SwiftUI views.
- If you also want to redesign Search, reuse the same two blocks and describe a search field +
  category chips + results grid.
