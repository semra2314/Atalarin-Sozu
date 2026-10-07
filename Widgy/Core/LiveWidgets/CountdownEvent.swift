//
//  CountdownEvent.swift
//  Kare  (shared: app + widget extension)
//
//  Kare+ · Countdowns to the days that matter: a trip, a wedding, an exam.
//
//  The app keeps a list; each placed widget picks one of them through
//  "Edit Widget", the same way custom designs are picked.
//

import AppIntents
import Foundation
import WidgetKit

nonisolated enum CountdownStyle: String, Codable, CaseIterable, Sendable, Identifiable {
    /// One dot per day left, filling as the day approaches.
    case dots
    /// Same, in hearts. For the people who count down to a person.
    case hearts
    /// Just the number, very large.
    case bold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dots: "Dots"
        case .hearts: "Hearts"
        case .bold: "Bold"
        }
    }

    var symbolName: String {
        switch self {
        case .dots: "circle.grid.3x3.fill"
        case .hearts: "heart.fill"
        case .bold: "textformat.size"
        }
    }
}

/// What the countdown is for. Picks the artwork behind the number, a
/// matching emoji to start from, and the gradient used until the art exists.
nonisolated enum CountdownTheme: String, Codable, CaseIterable, Sendable, Identifiable {
    case trip, celebration, love, study, calm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trip: "Trip"
        case .celebration: "Celebration"
        case .love: "Someone"
        case .study: "Exam"
        case .calm: "Anything"
        }
    }

    var emoji: String {
        switch self {
        case .trip: "✈️"
        case .celebration: "🎉"
        case .love: "❤️"
        case .study: "📚"
        case .calm: "⭐️"
        }
    }

    /// Asset name of the background. `-wide` is added for medium widgets.
    var art: String { "countdown-bg-\(rawValue)" }

    var fallbackHexes: [String] {
        switch self {
        case .trip: ["0E4C75", "3FA7C9"]
        case .celebration: ["3A0F4F", "C2376B"]
        case .love: ["4A0E24", "B8345A"]
        case .study: ["1B2A3A", "3D5A73"]
        case .calm: ["1D1D1F", "3A3A3C"]
        }
    }
}

nonisolated struct CountdownEvent: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var title: String
    var emoji: String
    var date: Date
    /// When the countdown was made. The dots fill from here to `date`.
    var createdAt: Date
    var style: CountdownStyle
    var colorHex: String
    /// Optional so countdowns saved before themes existed still decode.
    var theme: CountdownTheme?

    init(id: String = UUID().uuidString,
         title: String,
         emoji: String = "✈️",
         date: Date,
         createdAt: Date = .now,
         style: CountdownStyle = .dots,
         colorHex: String = CountdownEvent.palette[0],
         theme: CountdownTheme? = .trip) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.date = date
        self.createdAt = createdAt
        self.style = style
        self.colorHex = colorHex
        self.theme = theme
    }

    /// The gradient behind the number while there is no artwork.
    var fallbackHexes: [String] {
        theme?.fallbackHexes ?? [colorHex, colorHex]
    }

    /// Dark enough for white type to read on every one.
    static let palette = ["1E3A8A", "7C2D12", "831843", "14532D", "312E81", "1D1D1F"]

    /// Whole calendar days until the event, counted from midnight to midnight,
    /// so "tomorrow" is 1 at any hour of the day.
    func daysLeft(from now: Date = .now) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// 0...1: how much of the wait is behind you.
    func progress(at now: Date = .now) -> Double {
        let total = date.timeIntervalSince(createdAt)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(createdAt) / total))
    }

    /// Total days in the wait, for drawing one mark per day.
    var totalDays: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: createdAt),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        return max(1, days)
    }
}

// MARK: - Store

nonisolated enum CountdownStore {
    static let widgetKind = "CountdownWidget"
    private static let fileName = "countdowns.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedWidgetStore.appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func all() -> [CountdownEvent] {
        guard let url = fileURL, let data = try? Data(contentsOf: url),
              let events = try? JSONDecoder().decode([CountdownEvent].self, from: data) else { return [] }
        return events.sorted { $0.date < $1.date }
    }

    static func event(id: String?) -> CountdownEvent? {
        let events = all()
        guard let id else { return nextUpcoming(in: events) }
        return events.first { $0.id == id } ?? nextUpcoming(in: events)
    }

    /// The soonest event that has not passed, or the latest one if all have.
    static func nextUpcoming(in events: [CountdownEvent]) -> CountdownEvent? {
        events.first { $0.daysLeft() >= 0 } ?? events.last
    }

    static func save(_ events: [CountdownEvent]) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func upsert(_ event: CountdownEvent) {
        var events = all()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        save(events)
    }

    static func delete(id: String) {
        save(all().filter { $0.id != id })
    }
}

// MARK: - Widget configuration

nonisolated struct CountdownEntity: AppEntity, Identifiable, Hashable {
    let id: String
    let title: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Countdown" }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    static var defaultQuery: CountdownQuery { CountdownQuery() }
}

nonisolated struct CountdownQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CountdownEntity] {
        allEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [CountdownEntity] {
        allEntities()
    }

    func defaultResult() async -> CountdownEntity? {
        CountdownStore.nextUpcoming(in: CountdownStore.all()).map {
            CountdownEntity(id: $0.id, title: $0.title)
        }
    }

    private func allEntities() -> [CountdownEntity] {
        CountdownStore.all().map { CountdownEntity(id: $0.id, title: $0.title) }
    }
}

// Not `nonisolated`: `@Parameter` is a mutable stored property (see KareSelection).
struct SelectCountdownIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose a countdown" }
    static var description: IntentDescription {
        IntentDescription("Pick which of your countdowns this widget shows.")
    }

    @Parameter(title: "Countdown")
    var countdown: CountdownEntity?

    init() {}
}
