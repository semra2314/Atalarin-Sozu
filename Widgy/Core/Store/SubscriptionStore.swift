//
//  SubscriptionStore.swift
//  Kare
//
//  Kare+ , for real this time.
//
//  What this replaces: a `@AppStorage("karePlusActive")` boolean that the
//  paywall set to true when you tapped Subscribe. It was honest about being a
//  demo, but it has two properties that make it impossible to ship. It never
//  takes money, and more importantly it never *stops*: nothing revokes it when
//  a subscription lapses, is refunded, or is cancelled, so a paid widget
//  unlocked once stays unlocked forever.
//
//  StoreKit 2 answers both. Entitlement is not something we store; it is
//  something we ask Apple for. `StoreKit.Transaction.currentEntitlements` is the truth,
//  it is already verified by the App Store, and it goes away on its own when
//  the subscription does.
//
//  Two things about this file are deliberate:
//
//  1. There is no local "is subscribed" flag written anywhere. Caching it is
//     how apps end up granting access to people who refunded three months ago.
//     Entitlement is recomputed from StoreKit and held only in memory.
//
//  2. `StoreKit.Transaction.updates` is listened to for the whole life of the app, not
//     just while the paywall is open. Renewals, cancellations, refunds, family
//     sharing changes and purchases made on another device all arrive there,
//     often when no UI is on screen.
//

import Foundation
import StoreKit
import Observation
import SwiftUI   // EnvironmentKey / EnvironmentValues for the injection below.
                 // Note this also pulls in SwiftUI.Transaction, which collides
                 // with StoreKit.Transaction, so every use below is qualified.

@MainActor
@Observable
final class SubscriptionStore {

    /// Product identifiers, which must match App Store Connect exactly.
    ///
    /// A typo here does not crash and does not warn: `Product.products(for:)`
    /// simply returns fewer products than asked for, the paywall renders empty,
    /// and it looks like a network problem. That is why `loadFailed` below
    /// distinguishes "nothing came back" from "the request threw".
    enum ProductID {
        static let monthly  = "com.erdendereli.Widgy.kareplus.monthly"
        static let yearly   = "com.erdendereli.Widgy.kareplus.yearly"
        /// One payment, Kare+ forever. A non-consumable, not a subscription.
        static let lifetime = "com.erdendereli.Widgy.kareplus.lifetime"

        /// Paid widgets that can also be bought on their own, keyed by
        /// catalogue template id. One-time, non-consumable purchases.
        static let widgetByTemplate: [String: String] = [
            "t-exhale":    "com.erdendereli.Widgy.widget.exhale",
            "t-countdown": "com.erdendereli.Widgy.widget.countdown",
            "t-progress":  "com.erdendereli.Widgy.widget.progress",
            "p-momentum":  "com.erdendereli.Widgy.widget.momentum",
            "p-neon":      "com.erdendereli.Widgy.widget.neon",
            "p-gratitude": "com.erdendereli.Widgy.widget.gratitude",
            "p-mono":      "com.erdendereli.Widgy.widget.mono"
        ]

        /// Anything in here means "Kare+ member".
        static let karePlus: Set<String> = [monthly, yearly, lifetime]

        static var all: [String] {
            [monthly, yearly, lifetime] + widgetByTemplate.values.sorted()
        }
    }

    /// The live widget each single purchase unlocks in the widget extension.
    /// Presets are drawn from the user's own saved design, so only the three
    /// live widgets need telling.
    private static let widgetKindByTemplate: [String: String] = [
        "t-exhale": QuitStore.widgetKind,
        "t-countdown": CountdownStore.widgetKind,
        "t-progress": LifeProgressStore.widgetKind
    ]

    private(set) var products: [Product] = []
    /// The identifiers the App Store says this person is currently entitled to.
    private(set) var entitledIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var purchaseInFlight: String?
    private(set) var loadFailed = false
    var errorMessage: String?

    /// Whether Kare+ can be sold yet.
    ///
    /// Flip to `true` the day the two products are live in App Store Connect
    /// and the Paid Apps agreement is active. Until then StoreKit returns
    /// nothing, and without this flag every beta tester would find the paid
    /// presets locked behind a paywall that says "Plans couldn't load". That
    /// is a dead end, and it makes a working app look broken.
    ///
    /// A build-time constant rather than a runtime check on purpose. Unlocking
    /// whenever products fail to load would be the obvious shortcut and a real
    /// hole: a user with no signal would get everything for free.
    nonisolated static let subscriptionsAreLive = true

    /// True Kare+ membership: an active subscription or the lifetime unlock.
    /// Drives the "Kare+ member" label, which must never say yes to someone
    /// who has only bought a single widget.
    var isSubscribed: Bool { !entitledIDs.isDisjoint(with: ProductID.karePlus) }

    /// Kare+ bought outright rather than subscribed: there is nothing to
    /// manage or cancel.
    var hasLifetime: Bool { entitledIDs.contains(ProductID.lifetime) }

    /// Whether every paid design is usable right now.
    ///
    /// Separate from `isSubscribed` because before launch they differ: we
    /// cannot charge, so we do not lock. Nothing here claims membership.
    var unlocksPaidWidgets: Bool { isSubscribed || !Self.subscriptionsAreLive }

    /// Whether this one widget is usable: free, covered by Kare+, or bought
    /// on its own.
    func isUnlocked(templateID: String, isFree: Bool = false) -> Bool {
        if isFree || unlocksPaidWidgets { return true }
        guard let id = ProductID.widgetByTemplate[templateID] else { return false }
        return entitledIDs.contains(id)
    }

    func isUnlocked(_ template: WidgetTemplate) -> Bool {
        isUnlocked(templateID: template.id, isFree: template.price.isFree)
    }

    /// Bought on its own (not through Kare+).
    func ownsSingly(templateID: String) -> Bool {
        guard let id = ProductID.widgetByTemplate[templateID] else { return false }
        return entitledIDs.contains(id)
    }

    /// The StoreKit product that sells this widget on its own.
    func product(forTemplate templateID: String) -> Product? {
        guard let id = ProductID.widgetByTemplate[templateID] else { return nil }
        return products.first { $0.id == id }
    }

    /// The price to show for a widget: the App Store's own, formatted for this
    /// storefront, once StoreKit has answered; the catalogue's until then.
    /// What a widget's price line says to this person, everywhere it is shown.
    ///
    /// A member should never be quoted a price for something they already
    /// have, and "Free" would be wrong too: it is not free, they paid for
    /// it. So paid widgets read "Unlocked" for Kare+ and lifetime members,
    /// "Purchased" when bought on their own, and the price for everyone else.
    func priceText(for template: WidgetTemplate) -> Text {
        if template.price.isFree || !Self.subscriptionsAreLive { return Text("Free") }
        if isSubscribed { return Text("Unlocked") }
        if ownsSingly(templateID: template.id) { return Text("Purchased") }
        return Text(verbatim: displayPrice(for: template))
    }

    /// Whether the price line is a status worth emphasising (a price, or
    /// "Unlocked" / "Purchased") rather than plain "Free".
    func priceIsEmphasised(for template: WidgetTemplate) -> Bool {
        !template.price.isFree && Self.subscriptionsAreLive
    }

    func displayPrice(for template: WidgetTemplate) -> String {
        product(forTemplate: template.id)?.displayPrice ?? template.price.displayText
    }

    /// Kare+ plans in the order the paywall lists them: yearly, monthly, lifetime.
    var plans: [Product] {
        let subs = products.filter { $0.type == .autoRenewable }.sorted { $0.price > $1.price }
        let once = products.filter { $0.id == ProductID.lifetime }
        return subs + once
    }

    var lifetime: Product? { products.first { $0.id == ProductID.lifetime } }

    /// Whether to show the Kare+ entry point at all.
    var canOfferSubscription: Bool { Self.subscriptionsAreLive }

    var monthly: Product? { products.first { $0.id == ProductID.monthly } }
    var yearly: Product? { products.first { $0.id == ProductID.yearly } }

    /// The monthly price, already formatted for this storefront, as a plain
    /// string.
    ///
    /// Exists so screens that just want to print a price do not have to import
    /// StoreKit and handle a `Product`. Settings needed one number and reaching
    /// for `monthly.displayPrice` pulled a whole framework into a view that has
    /// nothing to do with purchasing, which is also how `SwiftUI.Transaction`
    /// and `StoreKit.Transaction` ended up colliding a file earlier. The
    /// paywall still works with `Product` directly; it genuinely needs to.
    ///
    /// Nil until StoreKit answers, so callers show nothing rather than a
    /// placeholder price the App Store will not charge.
    var monthlyDisplayPrice: String? { monthly?.displayPrice }

    init() {
        // Started before anything is loaded, because a transaction can arrive
        // during launch: an interrupted purchase from last session, or an
        // "Ask to Buy" request a parent just approved.
        //
        // The task is deliberately not stored and never cancelled. There was a
        // `deinit` here that cancelled it, and Swift 6 rejected it outright:
        // `deinit` is nonisolated and cannot touch main-actor state. Fighting
        // that would have been the wrong fix anyway. This store is created once
        // by `KareApp` and lives as long as the process, so a cancel would only
        // ever run at termination, and the one thing you must not do is stop
        // listening while the app is alive. Renewals and refunds arrive with no
        // UI on screen.
        //
        // `[weak self]` still matters: it keeps the task from being the reason
        // the store stays alive, so this holds no ownership it shouldn't.
        Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { return }
                await self.handle(update)
            }
        }
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: ProductID.all)
            // Yearly first: it is the better deal and the one worth defaulting
            // to, and sorting by price keeps that true if the prices change.
            products = fetched.sorted { $0.price > $1.price }
            loadFailed = plans.isEmpty
        } catch {
            loadFailed = true
            errorMessage = error.localizedDescription
        }
        await refreshEntitlements()
    }

    /// Asks the App Store what this person currently owns.
    ///
    /// Unverified transactions are skipped rather than trusted. A jailbroken
    /// device can hand the app a forged receipt; `VerificationResult` exists
    /// precisely so we do not have to decide whether to believe it.
    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expiry = transaction.expirationDate, expiry < .now { continue }
            owned.insert(transaction.productID)
        }
        entitledIDs = owned
        // The widget extension cannot ask StoreKit through this store, so the
        // answer is mirrored into the App Group for the Kare+ widgets to read.
        let ownedKinds = Self.widgetKindByTemplate.compactMap { templateID, kind in
            ownsSingly(templateID: templateID) ? kind : nil
        }
        KarePlusAccess.set(unlocked: unlocksPaidWidgets, ownedKinds: Set(ownedKinds))
    }

    // MARK: - Buying

    /// Returns true only when the purchase went through and was verified,
    /// so the caller knows whether to celebrate.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchaseInFlight = product.id
        defer { purchaseInFlight = nil }
        do {
            switch try await product.purchase() {
            case let .success(verification):
                await handle(verification)
                if case .verified = verification { return true }
                return false
            case .userCancelled:
                // Not an error. Saying anything here would be scolding someone
                // for changing their mind.
                return false
            case .pending:
                // Ask to Buy, or a payment method needing approval. The result
                // arrives later through StoreKit.Transaction.updates.
                errorMessage = String(localized: "This purchase is waiting for approval.")
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Required by App Review, and genuinely needed: a new phone, a reinstall,
    /// or a second device all land here.
    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if entitledIDs.isEmpty {
                errorMessage = String(localized: "No previous purchase found on this Apple Account.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Transactions

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case let .verified(transaction) = result else { return }
        await refreshEntitlements()
        // Tells the App Store we have delivered the goods. Without this the
        // same transaction is redelivered on every launch, forever.
        await transaction.finish()
    }
}

// MARK: - Environment

private struct SubscriptionStoreKey: EnvironmentKey {
    @MainActor static let defaultValue = SubscriptionStore()
}

extension EnvironmentValues {
    var subscriptions: SubscriptionStore {
        get { self[SubscriptionStoreKey.self] }
        set { self[SubscriptionStoreKey.self] = newValue }
    }
}
