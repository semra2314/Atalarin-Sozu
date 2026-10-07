//
//  LifeProgress.swift
//  Kare  (shared: app + widget extension)
//
//  Kare+ · How much of the day, week, month, year, or life has passed.
//  Each placed widget picks which one through "Edit Widget".
//

import AppIntents
import Foundation
import WidgetKit

nonisolated enum ProgressKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case day, week, month, year, life

    var id: String { rawValue }

    /// How many marks the large widget draws: one per hour, day, month or year.
    func units(at date: Date, calendar: Calendar = .current) -> Int {
        switch self {
        case .day: 24
        case .week: 7
        case .month: calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        case .year: 12
        case .life: LifeProgressStore.lifespanYears
        }
    }

    /// The span this kind measures, or nil for `.life` without a birthday.
    func interval(containing date: Date, calendar: Calendar = .current) -> DateInterval? {
        switch self {
        case .day: calendar.dateInterval(of: .day, for: date)
        case .week: calendar.dateInterval(of: .weekOfYear, for: date)
        case .month: calendar.dateInterval(of: .month, for: date)
        case .year: calendar.dateInterval(of: .year, for: date)
        case .life:
            LifeProgressStore.birthDate().flatMap { birth in
                calendar.date(byAdding: .year, value: LifeProgressStore.lifespanYears, to: birth)
                    .map { DateInterval(start: birth, end: max(birth, $0)) }
            }
        }
    }

    func fraction(at date: Date, calendar: Calendar = .current) -> Double? {
        guard let interval = interval(containing: date, calendar: calendar),
              interval.duration > 0 else { return nil }
        return min(1, max(0, date.timeIntervalSince(interval.start) / interval.duration))
    }

    /// The heading: "Tuesday", "September", "2026", "This week", "Your life".
    func title(at date: Date) -> String {
        switch self {
        case .day: date.formatted(.dateTime.weekday(.wide).locale(WidgetLanguage.locale))
        case .week: WidgetLanguage.localized("This week")
        case .month: date.formatted(.dateTime.month(.wide).locale(WidgetLanguage.locale))
        case .year: date.formatted(.dateTime.year().locale(WidgetLanguage.locale))
        case .life: WidgetLanguage.localized("Your life")
        }
    }
}

// MARK: - Artwork and detail

nonisolated extension ProgressKind {
    /// Background art: the time of day for Today (reusing Daily's paper
    /// backgrounds), the season for the month and year, a night sky for a
    /// life. Nil for the week, which stays plain paper.
    func art(at date: Date, calendar: Calendar = .current) -> String? {
        switch self {
        case .day:
            let hour = calendar.component(.hour, from: date)
            return hour < 11 ? "daily-bg-morning" : (hour < 17 ? "daily-bg-day" : "daily-bg-evening")
        case .week:
            return nil
        case .month, .year:
            return "progress-bg-\(Season.of(date, calendar: calendar).rawValue)"
        case .life:
            return "progress-bg-life"
        }
    }

    /// White type on a dark picture, or dark type on paper.
    var isDark: Bool { self == .life }

    /// The line under the percentage: what is left, in the unit people count in.
    func remainingText(at date: Date, calendar: Calendar = .current) -> String? {
        guard let interval = interval(containing: date, calendar: calendar) else { return nil }
        switch self {
        case .day:
            let hours = max(0, Int(interval.end.timeIntervalSince(date) / 3_600))
            return WidgetLanguage.localized("%lld hours left", hours)
        case .week, .month, .year:
            let start = calendar.startOfDay(for: date)
            let days = max(0, calendar.dateComponents([.day], from: start, to: interval.end).day ?? 0)
            return WidgetLanguage.localized("%lld days left", days)
        case .life:
            let weeks = max(0, Int(date.timeIntervalSince(interval.start) / (7 * 86_400)))
            return WidgetLanguage.localized("%lld weeks lived", weeks)
        }
    }
}

nonisolated enum Season: String, Sendable {
    case spring, summer, autumn, winter

    /// Northern-hemisphere meteorological seasons.
    static func of(_ date: Date, calendar: Calendar = .current) -> Season {
        switch calendar.component(.month, from: date) {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .autumn
        default: .winter
        }
    }
}

nonisolated enum LifeProgressStore {
    static let widgetKind = "ProgressWidget"
    /// A round figure, not a forecast. The setup screen says so.
    static let lifespanYears = 80
    private static let birthKey = "progress.birthDate"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedWidgetStore.appGroupID)
    }

    static func birthDate() -> Date? {
        defaults?.object(forKey: birthKey) as? Date
    }

    static func save(birthDate: Date?) {
        if let birthDate {
            defaults?.set(birthDate, forKey: birthKey)
        } else {
            defaults?.removeObject(forKey: birthKey)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

// MARK: - Widget configuration

nonisolated enum ProgressKindOption: String, AppEnum {
    case day, week, month, year, life

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Progress" }

    static var caseDisplayRepresentations: [ProgressKindOption: DisplayRepresentation] {
        [
            .day: "Today",
            .week: "This week",
            .month: "This month",
            .year: "This year",
            .life: "Your life"
        ]
    }

    var kind: ProgressKind { ProgressKind(rawValue: rawValue) ?? .year }
}

// Not `nonisolated`: `@Parameter` is a mutable stored property (see KareSelection).
struct SelectProgressIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose what to measure" }
    static var description: IntentDescription {
        IntentDescription("Day, week, month, year, or your life so far.")
    }

    @Parameter(title: "Measure", default: .year)
    var measure: ProgressKindOption

    init() {}
}
