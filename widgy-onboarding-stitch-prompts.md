# Widgy - Onboarding Stitch Prompts

Brand (already saved in Stitch): warm off-white `#FDF8F8`, single coral accent `#d44a33`,
ink `#1D1D1F`, secondary `#5E5E63`, Fraunces (soft serif) headings, DM Sans body.
Generate each screen, bring it back, and we translate to SwiftUI.

## Fixed token block (paste at the top of each prompt)

```
Design tokens (match exactly, no other vivid colors):
- Background #FDF8F8, card surface #FFFFFF, muted surface #F1EDEC
- Ink text #1D1D1F, secondary text #5E5E63, border #E5E2E1
- Accent (only vivid color) #d44a33, used only for CTAs, active states, the "i" dot
- Headings: Fraunces (serif, soft/wonky), body/labels: DM Sans
- Buttons: fully rounded (pill), height ~54; card radius 20-24; soft shadow 0 10 30 rgba(0,0,0,0.04)
- Do not use any Tailwind default color.
```

---

## 1. Splash

```
Design a single iOS launch screen (iPhone 393x852). Background #FDF8F8, perfectly centered.
The lowercase wordmark "widgy" in bold soft-serif Fraunces, ink #1D1D1F, with the tittle over
the "i" replaced by a small coral (#d44a33) rounded-square tile. Nothing else. Calm, premium,
lots of negative space.
[paste token block]
```

## 2. Value slides (carousel)

```
Design a single iOS onboarding slide (iPhone 393x852), the first of a 3-slide swipeable set.
[paste token block]
Layout: a "Skip" text button top-right in secondary gray. Center: a hero visual of two
ready-made widget previews (rounded squares, real-looking content like a serif "Good morning"
on a purple gradient and a rounded "Deep work." on a dark card) floating at slight angles with
soft shadows. Below: a big two-line Fraunces headline "Ready-made widgets, beautifully done"
and a DM Sans subtitle. Bottom: three page dots (first active in coral) and a full-width coral
pill button "Next". Generous whitespace.
```

## 3. Taste picker

```
Design a single iOS screen (iPhone 393x852): "What's your style?" taste selection.
[paste token block]
Layout: a big two-line Fraunces headline "What's your style?" and a DM Sans subtitle
"Pick a vibe or two." Then a 2x2 grid of selectable cards: Minimal, Bold, Playful, Dark. Each
card is white with a hairline border, an icon top-left and the label bottom-left in Fraunces.
Show one card selected: filled coral #d44a33 background with white icon and label. Bottom: a
full-width coral pill button "Continue".
```

## 4. Sign in with Apple

```
Design a single iOS screen (iPhone 393x852): create-account / sign-in.
[paste token block]
Layout: centered. The "widgy" wordmark (Fraunces, coral "i" tile) near the middle. Under it a
Fraunces heading "Create your account" and a DM Sans line "Sign in once so your widgets follow
you everywhere." Near the bottom: a black full-width pill "Sign in with Apple" button with the
Apple logo, and beneath it a small secondary-gray text button "Continue without account".
Calm and trustworthy.
```

---

## Notes
- These are pure visual mocks; the flow logic is already built in SwiftUI. Bring back whatever
  looks best and I'll fold the visuals (hero compositions, spacing, illustration ideas) into the
  existing OnboardingView.
- The 3 slides share one layout; only the hero visual + copy change per slide, so generate slide
  1 well and I'll adapt 2 ("Make them yours" - editing chips) and 3 ("On your home screen" - a
  phone with a widget) from it.
```
