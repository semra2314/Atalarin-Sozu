# Widgy - Mentor Notes & Feature Roadmap

Captured from the mentor conversation. These are the features to build toward.
Each maps to hooks that already exist in the codebase, so most are additive.

---

## 1. Canva-style custom widget editor  (first widget to ship)

A widget users build themselves inside the app:
- Place **text** and **stickers** on a canvas.
- Choose **widget size**, **text size**, **color**, and **font**.
- Save it as a real widget they can add to their home screen.

Why it fits now:
- `WidgetTheme` is already a plain, serializable "visual recipe" (Codable). An editor
  is essentially a UI that produces a `WidgetTheme` (+ a new content model for
  text/stickers). ARCHITECTURE.md already lists the editor as the planned phase.

To add:
- Extend the model: a `WidgetContent` type (text blocks, sticker items, positions,
  font, size, color) alongside `WidgetTheme`.
- An `EditorView` feature folder producing that content.
- Save into the library via `LibraryStore` (already the single write path).

This is the flagship "make your own" widget and a strong first launch item.

---

## 2. Creator marketplace  (upload + sell + commission)

- Any user can **upload their own widget** to the marketplace.
- Widgets can be **sold for money**.
- The platform takes a **set commission** per sale; the **creator earns per purchase**.

Why it fits now:
- `WidgetTemplate.Price` already models `.free` and `.paid(amount, currencyCode)`.
- Repository pattern means the catalog can move to a real backend (Firebase is the
  planned swap, one line in `AppEnvironment`).

To add:
- Creator upload flow (submit a template + theme + content).
- **StoreKit** for purchases (ARCHITECTURE.md already flags this).
- Commission logic + payout accounting (server side).
- Creator accounts / auth (Firebase Auth, already anticipated).
- Decide the commission split (e.g. platform X percent, creator the rest) — open question.

---

## 3. Ratings & reviews

- Star rating other people's widgets.
- Leave written comments/reviews.

Why it fits now:
- `WidgetTemplate` already has `rating` and `ratingCount`.

To add:
- A `Review` model (author, stars, text, date) tied to a template.
- Write path + moderation basics.
- Reviews section on the detail screen (there is already a stats row to build on).

---

## 4. Profiles

- A profile shows widgets the user **made** and/or **uses**.
- Public creator profiles (ties into the marketplace and reviews).

Why it fits now:
- `Author` model + `AppRoute.author` route already exist; `AuthorView` is a stub to grow.

To add:
- "Created" vs "Using/Installed" tabs on the profile.
- Follower/creator stats if we want the social layer.

---

## Suggested build order (for a 4-week club project)

1. **Custom widget editor** (#1) — the flagship, mostly local, no backend needed. Highest demo value.
2. **Ratings & reviews** (#3) — small model, big perceived polish.
3. **Profiles** (#4) — surfaces created + used widgets.
4. **Marketplace upload + sell** (#2) — needs backend + StoreKit; heaviest, do last or scope to a demo.

Open questions to settle with the team:
- Commission percentage and payout model.
- Do paid widgets need Apple IAP (StoreKit) vs external payment (App Store rules).
- Moderation for user-uploaded content and reviews.
