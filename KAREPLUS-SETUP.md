# Kare+ — what is done, and what only you can do

The code is finished. Kare+ now asks the App Store who this person is instead
of remembering it, which is the difference between a paywall and a demo: the
old flag never took money and, worse, never *stopped*. Nothing revoked it on
cancellation or refund, so a widget unlocked once stayed unlocked forever.

---

## Part 1 — the app icon (5 minutes)

1. In Icon Composer, save the icon as **`Kare.icon`** into the project folder.
2. Drag `Kare.icon` into the Xcode **Project navigator**. Not into the asset
   catalog: it is a file, not an asset.
3. Target → **General** → *App Icons and Launch Screen* → set **App Icon** to
   `Kare` (the filename, no extension).
   Or Build Settings → *Primary App Icon Set Name* (`ASSETCATALOG_COMPILER_APPICON_NAME`) → `Kare`.
4. Build. Xcode generates every variant and platform size from that one file.

Leave `AppIcon.appiconset` where it is until you have confirmed which one your
deployment target actually uses. Anything older than iOS 26 needs those PNGs.

---

## Part 2 — test the subscription today, with no App Store Connect

`Kare.storekit` is already in the project root. It lets you buy, cancel, refund
and renew in the simulator without a single thing existing on Apple's side.

1. Drag `Kare.storekit` into the Project navigator.
2. **Product → Scheme → Edit Scheme → Run → Options**.
3. Set **StoreKit Configuration** to `Kare.storekit`.
4. Run. Open Settings → Kare+. Real prices, real purchase sheet, real
   entitlement.

While it is running, **Debug → StoreKit → Manage Transactions** lets you refund
or expire the subscription and watch the paid widgets lock themselves again.
Do that once. It is the behaviour the old flag could never produce, and it is
what App Review will try.

---

## Part 3 — what only you can do, in order

These are blocking, and the first one takes the longest to come back.

### 1. Sign the Paid Apps agreement

App Store Connect → **Business** → Paid Apps agreement. Then banking and tax.
Until this is active you cannot even create a subscription product. Start it
today whatever else you do; the review is not instant.

### 2. Create the subscription group and the two products

App Store Connect → your app → **Subscriptions** → new group, name it `Kare+`.

Two products, and the IDs must match the code **character for character**:

| product ID | duration | reference name |
|---|---|---|
| `com.erdendereli.Widgy.kareplus.monthly` | 1 month | Kare+ Monthly |
| `com.erdendereli.Widgy.kareplus.yearly` | 1 year | Kare+ Yearly |

A typo does not crash and does not warn. `Product.products(for:)` just returns
fewer products, the paywall shows "Plans couldn't load", and it looks like a
network fault. If that screen appears on a real device, check these strings
first.

Each product needs a display name and a description **in every language you
ship**, which for Kare means English and Turkish. Those strings come from App
Store Connect, not from our catalogue, so they are not in `Localizable.xcstrings`.

### 3. Put Terms and Privacy on the web

`KarePlusView` links to:

- `https://widgy-creators.vercel.app/terms`
- `https://widgy-creators.vercel.app/privacy`

**Neither page exists yet.** App Review opens both. A 404 here is a rejection,
and it is one of the most common ones for a first subscription release. Either
build the two pages or change the URLs in `KarePlus` to wherever they land.

### 4. Turn off the StoreKit configuration before you archive

Edit Scheme → Run → Options → StoreKit Configuration → **None**.

If you archive with it set, the build talks to a local file instead of the App
Store and nobody can buy anything.

---

## What App Review will check on the paywall

All four are already in the code, listed so you can see them on screen and
confirm nothing moved:

- the price and the period, per plan, in the user's own currency
- that it renews automatically, and how to stop it
- a **Restore purchases** button
- links to **Terms of Use** and **Privacy Policy**

---

## One thing worth knowing

Prices are no longer written anywhere in the app. They come from
`product.displayPrice`, already formatted for the user's storefront. A Turkish
user sees lira, a German sees euro, and when you change a price in App Store
Connect the app follows without a release.

That also means the paywall shows nothing until StoreKit answers. That is
deliberate. A placeholder price next to a Subscribe button that charges
something else is worse than a spinner.
