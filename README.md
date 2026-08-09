# Widgy Creator Portal

Next.js 14 (App Router) + Tailwind, converted from the Stitch.ai designs.
Same design tokens as the iOS app's `Theme.swift` — see `tailwind.config.ts`.

## Run locally

```bash
npm install
npm run dev
```

Open http://localhost:3000

## Deploy

Push this folder to a GitHub repo and import it in Vercel, or run:

```bash
npx vercel
```

## Pages

- `/` — landing page
- `/submit` — widget submission form
- `/agreement` — creator agreement / consent
- `/dashboard` — creator's own widgets + status

## Still TODO (not in scope of the visual conversion)

- **Auth** — dashboard and submit flow assume a logged-in creator; no auth
  provider is wired up yet (NextAuth, Clerk, Firebase Auth, etc. all fit).
- **Form submission** — the Submit and Agreement pages are UI only; nothing
  is persisted yet. Needs an API route + database (or Firebase, matching the
  app's `FirebaseWidgetRepository.swift`).
- **Image upload** — the drag-and-drop zone has no upload logic yet.
- **Commission rate** — `app/agreement/page.tsx` has a `COMMISSION_RATE`
  constant set to `"X%"`. Update it there once the business number is final.
- **Real widget previews** — the landing page showcase strip and dashboard
  thumbnails are placeholder tiles. Drop real exported PNGs from the app into
  `/public/widgets/` and swap in `<img>` tags once you have them.
- **Payments/payouts** — the Free/Paid toggle on the dashboard is visual only.
