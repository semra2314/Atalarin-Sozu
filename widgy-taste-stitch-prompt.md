# Widgy - "What's your style?" (taste picker) Stitch prompt

Matches the onboarding slides you already have: warm off-white, Fraunces headings, DM Sans body,
single coral accent, full-width coral pill button.

```
Design a single iOS onboarding screen (iPhone 393x852, light mode): a "What's your style?"
aesthetic picker, part of the Widgy onboarding, in a calm editorial style.

Design tokens (match exactly, no other vivid colors):
- Background #FDF8F8, card surface #FFFFFF, muted surface #F1EDEC
- Ink text #1D1D1F, secondary text #5E5E63, hairline border #E5E2E1
- Accent (only vivid color) #d44a33
- Headings: Fraunces (soft serif, bold), body/labels: DM Sans
- Buttons: fully rounded pill, height ~60; cards radius 24; soft shadow 0 10 30 rgba(0,0,0,0.04)
- Do not use any Tailwind default color.

Layout, top to bottom, comfortable margins (~28px):
- A large left-aligned two-line Fraunces headline "What's your style?" in ink.
- A DM Sans subtitle in secondary gray: "Pick a vibe or two. We'll tune your Discover feed."
- A 2x2 grid of four large selectable style cards (equal size, ~24px radius, generous gap).
  Each card previews its vibe with a small rounded-square widget thumbnail at the top plus the
  style name in Fraunces at the bottom-left:
    - "Minimal": off-white thumbnail with a single thin line of text, airy.
    - "Bold": deep ink thumbnail with big heavy type and a coral dot.
    - "Playful": soft purple gradient thumbnail with a rounded shape / sticker.
    - "Dark": near-black thumbnail with muted light text.
  Unselected cards: white surface with a 1px hairline border.
  Show ONE card selected: a 2px coral (#d44a33) border and a small coral filled check badge in
  the top-right corner (keep the card background white, not filled, so the previews stay readable).
- At the bottom, a full-width coral pill button "Continue".
Calm, lots of whitespace, single accent only, flat (no gradients except the Playful thumbnail).
```

---

## Note
When it looks right, send it back and I'll port it into the existing `TasteStep` in SwiftUI
(the selection logic + AppStorage are already wired; only the visuals change).
