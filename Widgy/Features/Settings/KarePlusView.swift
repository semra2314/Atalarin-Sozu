//
//  KarePlusView.swift
//  Kare
//
//  The Kare+ subscription screen.
//
//  Every price on this screen now comes from StoreKit, not from a constant.
//  That is not tidiness: prices are set per storefront in App Store Connect,
//  they are shown in the user's own currency, and Apple adjusts them when
//  exchange rates or local tax move. A hardcoded "$1.99" would be wrong for
//  most of the world on day one, and quoting a price the App Store will not
//  charge is both a rejection under guideline 3.1.2 and a promise broken at
//  the worst possible moment.
//
//  The subscribed state is likewise not stored. It is whatever
//  `Transaction.currentEntitlements` says right now, so cancelling or
//  refunding takes the paid widgets away again, which is the whole difference
//  between a paywall and a demo.
//

import SwiftUI
import StoreKit

// MARK: - Terms

enum KarePlus {
    /// Share of net subscription revenue that goes to the creator pool.
    /// Mirrors `POOL_PERCENT` in the portal's lib/terms.ts.
    static let poolPercent = 50

    /// Where the legal links point. App Review checks both are reachable and
    /// that they load real documents, not a marketing page.
    static let termsURL = URL(string: "https://kare.erdendereli.com/terms")!
    static let privacyURL = URL(string: "https://kare.erdendereli.com/privacy")!
}

// MARK: - Screen

struct KarePlusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.subscriptions) private var store
    /// The app's chosen language, not the phone's. Used to place the percent
    /// sign correctly in the savings badge.
    @Environment(\.locale) private var locale

    @State private var selected: Product?
    /// The dance-then-tick shown while a purchase goes through.
    @State private var phase: AddPhase?

    /// How many widgets a subscription actually unlocks, counted from the
    /// catalogue rather than typed in, so the number can never drift.
    private var paidCount: Int {
        SampleCatalog.templates.filter { !$0.price.isFree }.count
    }

    private var benefits: [(String, LocalizedStringKey, LocalizedStringKey)] {
        [
            ("square.grid.2x2.fill", "Every paid widget",
             "Unlocks all \(paidCount) paid designs in the catalogue, and everything paid we add later."),
            ("wand.and.stars", "The full editor",
             "Advanced backgrounds, custom stickers and every typography control."),
            ("heart.fill", "Designers get paid",
             "Half of subscription revenue goes to the creators whose widgets you actually use."),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    hero
                    benefitList

                    if store.isSubscribed {
                        activeCard
                    } else if store.isLoading {
                        ProgressView().padding(.vertical, Theme.Spacing.xl)
                    } else if store.loadFailed {
                        unavailableCard
                    } else {
                        planPicker
                        subscribeButton
                    }

                    footnote
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
                .kareReadableWidth()
            }
            .background(Theme.Palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .accessibilityLabel(Text("Close"))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.Palette.subtleText)
                    }
                }
            }
            .task {
                if store.products.isEmpty { await store.load() }
                // Default to the yearly plan, which `plans` lists first.
                selected = selected ?? store.plans.first
            }
            .alert("Something went wrong",
                   isPresented: Binding(get: { store.errorMessage != nil },
                                        set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
        .addedCelebration($phase, kind: .subscribe)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Just the word. The logo carries no square mark.
            Text("Kare+")
                .font(Theme.Typography.displayLarge)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.top, Theme.Spacing.lg)

            Text("Every paid widget, one subscription.")
                .font(Theme.Typography.bodyLarge)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Benefits

    private var benefitList: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ForEach(benefits, id: \.0) { symbol, title, detail in
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    Image(systemName: symbol)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.accent)
                        .frame(width: 34, height: 34)
                        .background(Theme.Palette.accentTint, in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.Palette.ink)
                        Text(detail)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Palette.subtleText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Plans

    private var planPicker: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(store.plans, id: \.id) { product in
                Button { selected = product } label: { planRow(product) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func planRow(_ product: Product) -> some View {
        let isSelected = selected?.id == product.id
        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Theme.Palette.accent : Theme.Palette.hairline)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.sm) {
                    // The App Store's own name for the plan, so it matches the
                    // Manage Subscriptions screen the user will see later.
                    Text(verbatim: product.displayName)
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Palette.ink)
                    if let saving = savingText(for: product, locale: locale) {
                        // "Save %@" as the key, so each language decides where
                        // the word and the figure go relative to each other.
                        Text("Save \(saving)")
                            .font(Theme.Typography.labelCaps)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, 3)
                            .background(Theme.Palette.accent, in: .capsule)
                            .foregroundStyle(.white)
                    }
                }
                Text(periodText(for: product))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            Spacer()

            // displayPrice is already formatted for the user's storefront and
            // currency. Formatting it ourselves is how apps end up showing
            // "$14.99" to someone who will be charged in lira.
            Text(verbatim: product.displayPrice)
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.surface, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Theme.Palette.accent : Theme.Palette.hairline,
                        lineWidth: isSelected ? 1.5 : 0.5)
        }
        .contentShape(.rect)
    }

    /// "per month" / "per year", read off the product rather than assumed.
    private func periodText(for product: Product) -> LocalizedStringKey {
        if product.id == SubscriptionStore.ProductID.lifetime { return "One payment, yours forever" }
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        switch (period.unit, period.value) {
        case (.year, 1):  return "per year"
        case (.month, 1): return "per month"
        case (.week, 1):  return "per week"
        default:          return ""
        }
    }

    /// How much the yearly plan saves against twelve months of the monthly one.
    ///
    /// Computed from the live prices, so it stays true after a price change in
    /// App Store Connect instead of quietly becoming a false claim. Returns
    /// nothing rather than a negative badge if yearly ever stops being cheaper.
    ///
    /// The number is formatted by Foundation, not by us, because the percent
    /// sign does not sit in the same place in every language: English writes
    /// 37%, Turkish writes %37. Gluing the sign on by hand produced "Save %37"
    /// in English. Passing the locale explicitly matters too, since the app
    /// has its own language switcher and `Locale.current` would follow the
    /// phone instead of the setting.
    private func savingText(for product: Product, locale: Locale) -> String? {
        guard product.subscription?.subscriptionPeriod.unit == .year,
              let monthly = store.monthly?.price, monthly > 0 else { return nil }
        let yearOfMonthly = monthly * 12
        guard product.price < yearOfMonthly else { return nil }
        let fraction = (yearOfMonthly - product.price) / yearOfMonthly
        return NSDecimalNumber(decimal: fraction).doubleValue
            .formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }

    private var subscribeButton: some View {
        Button {
            guard let product = selected else { return }
            runAddCelebration($phase, work: { await store.purchase(product) }) {
                dismiss()
            }
        } label: {
            Group {
                if selected?.id == SubscriptionStore.ProductID.lifetime {
                    Text("Buy Kare+ for life")
                } else {
                    Text("Subscribe")
                }
            }
            .font(Theme.Typography.cardTitle)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(Theme.Palette.accent, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(selected == nil || phase != nil)
    }

    // MARK: States

    private var activeCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.Palette.accent, in: .circle)
            Text(store.hasLifetime ? LocalizedStringKey("Kare+ is yours for life") : LocalizedStringKey("Kare+ is active"))
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
            Text("Every paid widget in the catalogue is yours to install.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)

            // Cancelling belongs to iOS, not to us. Linking there is required,
            // and hiding it is a guideline 3.1.2 rejection. A lifetime unlock
            // has nothing to manage.
            if !store.hasLifetime {
                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                    Text("Manage subscription")
                        .kareCapsLabel()
                        .foregroundStyle(Theme.Palette.accent)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .kareCard()
    }

    /// Shown when StoreKit returns nothing.
    ///
    /// Almost always means the products are not live in App Store Connect yet,
    /// or the device has no network. Saying "try again" is more use than an
    /// empty box, and far more use than a Subscribe button that does nothing.
    private var unavailableCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title2)
                .foregroundStyle(Theme.Palette.subtleText)
            Text("Plans couldn't load")
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
            Text("Check your connection and try again.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)
            Button {
                Task { await store.load() }
            } label: {
                Text("Try again").kareCapsLabel().foregroundStyle(Theme.Palette.accent)
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .kareCard()
    }

    // MARK: Footnote

    /// Restore, the renewal terms and the two links. All four are required by
    /// App Review for a subscription, and missing any one of them is among the
    /// most common rejections for a first paid release.
    private var footnote: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !store.isSubscribed {
                Button {
                    Task { await store.restore() }
                } label: {
                    Text("Restore purchases")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.accent)
                }
            }

            Text("Payment is charged to your Apple Account. The subscription renews automatically unless you turn off auto-renew at least 24 hours before the period ends.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Theme.Spacing.md) {
                Link("Terms of Use", destination: KarePlus.termsURL)
                Text(verbatim: "·").foregroundStyle(Theme.Palette.subtleText)
                Link("Privacy Policy", destination: KarePlus.privacyURL)
            }
            .font(Theme.Typography.caption)
            .tint(Theme.Palette.accent)

            Text("\(KarePlus.poolPercent)% of subscription revenue goes to the creator pool and is shared between the designers whose widgets are installed that month.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }
}

#Preview {
    KarePlusView()
}
