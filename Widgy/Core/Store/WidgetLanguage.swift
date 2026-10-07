//
//  WidgetLanguage.swift
//  Kare  (shared: app + widget extension)
//
//  Carries the language chosen in Kare's Settings over to the widgets.
//
//  The in-app choice only reaches SwiftUI through `\.locale`, and the widget
//  extension is a separate process that never sees it: a phone in English
//  with Kare set to Turkish used to get Turkish screens and English widgets.
//  The app now mirrors the choice into the App Group, and every widget reads
//  it back: for SwiftUI text through `\.locale`, and for strings built in
//  code (greetings, "3 days left", "2 d 4 h") through `bundle` and `locale`.
//

import Foundation
import WidgetKit

nonisolated enum WidgetLanguage {
    private static let key = "kare.appLanguage"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedWidgetStore.appGroupID)
    }

    /// "tr" or "en", or nil to follow the phone.
    static var code: String? {
        guard let raw = defaults?.string(forKey: key), raw == "tr" || raw == "en" else { return nil }
        return raw
    }

    static var locale: Locale {
        code.map { Locale(identifier: $0) } ?? .autoupdatingCurrent
    }

    /// The .lproj for the chosen language, so strings built in code match
    /// the widget's SwiftUI text. The main bundle when following the phone.
    static var bundle: Bundle {
        guard let code,
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    /// A catalogue string in the chosen language.
    static func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// A catalogue format with one number, plural rules included.
    static func localized(_ key: String, _ number: Int) -> String {
        String.localizedStringWithFormat(localized(key), number)
    }

    /// A calendar speaking the chosen language, for formatters that take one.
    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = locale
        return calendar
    }

    /// Called by the app at launch and whenever the language changes in
    /// Settings. `appLanguageRaw` is `AppLanguage.rawValue`.
    static func save(appLanguageRaw: String) {
        guard let defaults else { return }
        let value = (appLanguageRaw == "tr" || appLanguageRaw == "en") ? appLanguageRaw : "system"
        guard defaults.string(forKey: key) != value else { return }
        defaults.set(value, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
