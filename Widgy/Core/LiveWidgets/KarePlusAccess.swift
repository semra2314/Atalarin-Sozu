//
//  KarePlusAccess.swift
//  Kare  (shared: app + widget extension)
//
//  Tells the widget extension whether the Kare+ widgets should draw or show
//  their locked face.
//
//  The extension cannot ask `SubscriptionStore`, which lives in the app. So the
//  app mirrors one boolean into the App Group after every entitlement check,
//  and the paid widgets read it.
//
//  This is a display hint, not a purchase record. It never grants anything in
//  the app: the paywall, the detail page and the setup screens all still ask
//  StoreKit. The worst it can do is keep a lapsed subscriber's widget drawing
//  until the next time they open Kare, which is when it gets rewritten.
//

import Foundation
import WidgetKit

nonisolated enum KarePlusAccess {
    private static let key = "karePlus.unlocksPaidWidgets"
    /// Widget kinds bought one at a time, without Kare+.
    private static let ownedKindsKey = "karePlus.ownedWidgetKinds"

    /// Every widget kind that is part of Kare+. Reloaded whenever access
    /// changes, so a new subscriber sees their widgets unlock without waiting
    /// for the system's own refresh.
    static let paidWidgetKinds = [
        QuitStore.widgetKind,
        CountdownStore.widgetKind,
        LifeProgressStore.widgetKind
    ]

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedWidgetStore.appGroupID)
    }

    /// False until the app has written it once. A widget can only be placed
    /// after the app has been opened, and the app writes this at launch.
    static var isUnlocked: Bool {
        defaults?.bool(forKey: key) ?? false
    }

    /// Whether one widget kind should draw: Kare+, or that widget bought alone.
    static func isUnlocked(kind: String) -> Bool {
        isUnlocked || ownedKinds.contains(kind)
    }

    static var ownedKinds: Set<String> {
        Set(defaults?.stringArray(forKey: ownedKindsKey) ?? [])
    }

    static func set(unlocked: Bool, ownedKinds kinds: Set<String> = []) {
        guard let defaults else { return }
        let changed = defaults.object(forKey: key) == nil
            || defaults.bool(forKey: key) != unlocked
            || ownedKinds != kinds
        defaults.set(unlocked, forKey: key)
        defaults.set(kinds.sorted(), forKey: ownedKindsKey)
        if changed {
            for kind in paidWidgetKinds {
                WidgetCenter.shared.reloadTimelines(ofKind: kind)
            }
        }
    }
}

/// Mirrors the ids of the widgets in the user's library into the App Group, so
/// the extension only offers widgets the user has actually added.
///
/// The extension cannot read SwiftData. The app rewrites this list at launch
/// and after every add or remove.
nonisolated enum LibraryMirror {
    private static let key = "library.installedTemplateIDs"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedWidgetStore.appGroupID)
    }

    /// Nil until the app has written it once (an install updated from a build
    /// without the mirror). Everything is offered then, so placed widgets do
    /// not vanish before the app is opened.
    static var installedIDs: Set<String>? {
        defaults?.stringArray(forKey: key).map(Set.init)
    }

    static func has(_ templateID: String) -> Bool {
        installedIDs?.contains(templateID) ?? true
    }

    /// The custom "Kare" widget is offered once at least one design exists.
    static var hasDesigns: Bool {
        installedIDs == nil || !SharedWidgetStore.all().isEmpty
    }

    static func set(_ ids: Set<String>) {
        guard let defaults else { return }
        guard installedIDs != ids else { return }
        defaults.set(ids.sorted(), forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
        WidgetCenter.shared.invalidateConfigurationRecommendations()
    }
}
