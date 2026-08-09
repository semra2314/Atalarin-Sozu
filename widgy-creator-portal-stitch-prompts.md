# Widgy Creator Portal — Stitch.ai prompts

Goal: a website where widget creators submit their work, sign an agreement, and after
approval publish it as free or paid inside the Widgy app (built with Next.js + Vercel —
here we're only generating the design in Stitch). Same brand as the app: warm off-white
background, single coral accent, Fraunces headings + DM Sans body — the exact editorial
App Store feel, carried over to the web.

Paste the two fixed blocks below at the top of every prompt.

## Fixed design tokens (add to every prompt)

```
Design tokens (match exactly, no other vivid colors):
- Background #FDF8F8, card surface #FFFFFF, muted surface #F1EDEC
- Primary/ink text #1D1D1F, secondary text #5E5E63, border #E5E2E1
- Accent (only vivid color) #D44A33, used only for CTAs, active states, links, focus rings
- Headings: Fraunces (serif, soft/wonky, warm), body/labels: DM Sans
- Card radius 16-24px, buttons fully rounded or 12px, soft shadow 0 10 30 rgba(0,0,0,0.04)
- Generous whitespace, editorial/calm feel, not corporate-SaaS-blue
- Do not use any Tailwind default color: blue-*, purple-*, emerald-*, rose-*, indigo-*
- Exception: small status badges may use muted semantic tints only (soft amber for "pending",
  soft sage green for "approved", soft gray for "draft") — never as a primary UI color
```

## Fixed top navigation (identical on every page)

```
Sticky top nav, white/frosted background, hairline bottom border, desktop 1440px wide:
left = "Widgy" wordmark in Fraunces + small coral square logomark; center-right = text links
"How It Works", "Agreement", "FAQ"; far right = a filled coral rounded button "Submit a Widget"
(or if logged in: a rounded avatar + "My Dashboard" link).
```

---

## Prompt 1 — Landing page (convinces creators to submit)

```
Design a marketing landing page (desktop, 1440x1024, light mode) for "Widgy Creator Portal" —
a platform where independent designers submit custom iOS home-screen widgets to be sold or
shared for free inside the Widgy app, in a calm editorial App Store style.

[paste fixed design tokens block]
[paste fixed top nav block]

Layout, top to bottom:
- Hero: big Fraunces headline ("Design your widget. Share it with the world."), a secondary
  DM Sans subheadline about creators keeping ownership and choosing free or paid, a coral
  rounded primary CTA button "Submit a Widget" + a ghost secondary button "How It Works".
  Right side of hero: a soft mockup collage of 2-3 phone widget previews on a warm off-white
  card, tilted slightly, soft shadow.
- A widget showcase strip: a horizontally scrollable row of 5-6 small rounded preview cards,
  each showing one real widget mockup (weather, calendar, photo stack, focus timer style)
  with its name in small Fraunces caps beneath — labelled "Aurora", "Drift", "Focus", "Frame",
  "Hush", "Ledger" — a subtle "Made by our creators" DM Sans caption above the row. This
  replaces any fake stats; it should feel like proof through the actual product, not numbers.
- A 3-step "How it works" section: three white rounded cards side by side, each with a small
  coral numbered badge (1/2/3), a Fraunces mini-title, and a DM Sans description:
  "1. Submit" (name, description, preview images), "2. Review & Approve" (sign the agreement,
  our team reviews it), "3. Publish" (choose free or paid, go live inside Widgy).
- A trust/reassurance band: centered Fraunces line ("Your work stays yours.") with a short
  DM Sans paragraph about the ownership agreement, and a small "Read the Agreement" text link
  in accent color.
- Footer: simple, warm off-white, wordmark left, small links right, muted text.
Calm, generous whitespace, warm and inviting, not corporate.
```

---

## Prompt 2 — Submit a Widget (application form)

```
Design a submission form page (desktop, 1440x1200, light mode) titled "Submit a Widget" for
Widgy Creator Portal, calm editorial App Store style.

[paste fixed design tokens block]
[paste fixed top nav block]

Layout: a centered single-column form card (max-width ~640px) on the warm off-white
background, white surface, generous padding, soft shadow, radius 24px.

Inside the card, top to bottom:
- Fraunces page title "Tell Us About Your Widget" + small DM Sans helper line ("Review
  usually takes 2-3 business days.").
- A step indicator at the top: 3 small pill segments ("Details" active in coral, "Images",
  "Agreement" muted/upcoming).
- Form fields, each with a small uppercase DM Sans label above a rounded input
  (border #E5E2E1, focus ring coral):
  - "Widget Name" (text input)
  - "Category" (a row of selectable rounded chips: Focus, Time, Mood, Productivity, Other —
    selected chip filled coral, rest outlined)
  - "Description" (textarea, ~4 lines, placeholder about what the widget does and why it's
    useful)
  - "Sizes" (small/medium/large as checkboxes styled as rounded chips)
- A drag-and-drop image upload zone: dashed border #E5E2E1, rounded 16px, muted surface fill,
  a small upload icon, "Drag images here or browse" text, beneath it 3 small rounded
  thumbnail placeholders showing already-added preview images with a delete "x" on hover.
- A soft-disabled "Free / Paid" toggle row, grayed out, with a small lock icon and a caption:
  "You'll choose this after approval."
- Primary coral rounded button "Continue to Agreement" full width at the bottom of the card.
Calm, focused, no visual noise, single accent used sparingly.
```

---

## Prompt 3 — Agreement page

```
Design a legal agreement / consent page (desktop, 1440x1100, light mode) titled "Creator
Agreement" for Widgy Creator Portal, calm editorial style — should feel reassuring and
transparent, not like fine print.

[paste fixed design tokens block]
[paste fixed top nav block]

Layout: centered content column (max-width ~720px).
- Fraunces headline "Your work stays yours." + a warm DM Sans intro paragraph reassuring the
  creator that Widgy does not claim ownership of their design, only a license to distribute
  it in-app, that they can remove it anytime, and that Widgy takes a small, clearly stated
  commission only on paid sales (free widgets cost the creator nothing).
- A small highlighted callout row right under the intro, muted surface, rounded, with a coral
  percentage badge "X%" and DM Sans text "Widgy's commission on paid widget sales. You keep
  the rest — paid out [monthly/on your terms]." This should stand out as the one number
  creators care about most, not buried in the document below.
- A scrollable white rounded card (looks like a document), radius 20px, soft shadow,
  containing the agreement text as clean DM Sans paragraphs with Fraunces mini-headers per
  section: "1. Ownership", "2. License", "3. Revenue Share & Commission" (states the X%
  platform commission on paid sales, payout schedule, and that free widgets are commission-free),
  "4. Right to Remove", "5. Content Guidelines". Comfortable line height, muted hairline
  dividers between sections.
- Below the document card: a bordered white row with a custom coral checkbox and DM Sans
  label "I have read and agree to the terms above."
- Two buttons side by side at the bottom: a ghost/secondary "Back" button and a primary
  coral rounded "Accept & Submit" button (visually disabled/lighter until the checkbox
  is checked).
Warm, trustworthy, editorial — like reading a well-designed letter, not a EULA.
```

---

## Prompt 4 — My Dashboard (creator dashboard / submission status)

```
Design a creator dashboard page (desktop, 1440x1024, light mode) titled "My Widgets" for
Widgy Creator Portal, calm editorial App Store style.

[paste fixed design tokens block]
[paste fixed top nav block, logged-in state]

Layout:
- Page header: Fraunces "My Widgets" title left, coral rounded "+ New Widget" button right.
- A row of 3 small summary stat cards (muted surface, rounded): "Live" count, "In Review"
  count, "Total Views" count — each a big Fraunces number over a tiny uppercase label.
- A list of submission cards stacked vertically, each a white rounded row (radius 16px, soft
  shadow, padding):
  - Left: a small rounded square widget preview thumbnail.
  - Middle: widget name in Fraunces-medium, category + submission date in small secondary
    DM Sans text underneath.
  - A status badge: soft amber pill "In Review", soft sage green pill "Approved", or soft
    gray pill "Changes Requested" — small, rounded, uppercase tiny label.
  - Right: for approved widgets, a small coral/outline segmented control "Free | Paid"
    already interactive; for pending ones, a muted "Edit" text link.
- Empty state variant (small note in the corner of the frame): a centered illustration-style
  icon in a muted circle, Fraunces "No widgets yet", DM Sans caption, coral button
  "Submit Your First Widget".
Calm, organized, scannable at a glance.
```

---

## Notes
- Designing for web (desktop first), but if you also want a mobile version (390px, single
  column, sticky bottom CTA), add "also generate a mobile 390px version, single column,
  sticky bottom CTA" to any of the prompts above.
- When turning the Stitch output into Next.js + Tailwind, define this token block as custom
  colors in `tailwind.config` — the exact same hex values as `Theme.swift` on the SwiftUI side.
- The legal content of the agreement (revenue share percentage, IP clauses, etc.) still needs
  to be nailed down separately — this prompt only produces the page's *look*; the real
  agreement text needs a lawyer or a template.
