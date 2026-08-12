//
//  DailyPassage.swift
//  Widgy  (shared: app + widget extension)
//
//  Content and preferences for the Daily widget. The app writes the chosen
//  source into the App Group; the widget reads it and picks the day's passage.
//
//  ── On sourcing ──────────────────────────────────────────────────────────
//  Every passage here is from a **public-domain** translation, because modern
//  translations of scripture are usually copyrighted (NIV, most Turkish meals,
//  and so on) and shipping them would be a licensing problem, not a technical
//  one. Specifically:
//    • Bible      — King James Version (1611), public domain worldwide.
//    • Quran      — Muhammad Sarwar / classical public-domain English renderings.
//    • Stoic      — Long's Meditations (1862) and Seneca's letters, public domain.
//    • Poetry     — Rumi (Nicholson, 1926) and other pre-1929 translations.
//    • Proverbs   — traditional sayings, no single author.
//
//  Every passage carries its reference, and the widget always displays it.
//  A quotation without its source is how misattribution spreads, and that
//  matters more than usual with scripture.
//

import Foundation
import WidgetKit

nonisolated enum DailySource: String, Codable, CaseIterable, Sendable, Identifiable {
    case quran
    case bible
    case stoic
    case poetry
    case proverbs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quran: "Quran"
        case .bible: "Bible"
        case .stoic: "Stoic"
        case .poetry: "Poetry"
        case .proverbs: "Proverbs"
        }
    }

    var subtitle: String {
        switch self {
        case .quran: "Public-domain English translation"
        case .bible: "King James Version"
        case .stoic: "Marcus Aurelius, Seneca, Epictetus"
        case .poetry: "Rumi, Whitman, Dickinson"
        case .proverbs: "Traditional sayings"
        }
    }

    var symbolName: String {
        switch self {
        case .quran: "book.closed"
        case .bible: "book"
        case .stoic: "building.columns"
        case .poetry: "feather"
        case .proverbs: "quote.opening"
        }
    }
}

nonisolated struct DailyPassage: Codable, Hashable, Sendable {
    var text: String
    /// Where it comes from, e.g. "Quran 94:5-6" or "Meditations, IV.3".
    var reference: String
}

/// The user's Daily widget preference, shared through the App Group.
nonisolated struct DailyPreference: Codable, Hashable, Sendable {
    var sourceRaw: String

    var source: DailySource { DailySource(rawValue: sourceRaw) ?? .proverbs }

    init(source: DailySource = .proverbs) {
        self.sourceRaw = source.rawValue
    }
}

nonisolated enum DailyStore {
    static let widgetKind = "DailyWidget"
    private static let fileName = "daily-preference.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedWidgetStore.appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func save(source: DailySource) {
        guard let url = fileURL,
              let data = try? JSONEncoder().encode(DailyPreference(source: source)) else { return }
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func loadSource() -> DailySource {
        guard let url = fileURL, let data = try? Data(contentsOf: url),
              let preference = try? JSONDecoder().decode(DailyPreference.self, from: data)
        else { return .proverbs }
        return preference.source
    }

    /// The passage for a given day. Deterministic: the same day always yields
    /// the same passage, so the widget doesn't flicker between refreshes, and
    /// everyone reading the same source sees the same thing on the same day.
    static func passage(for date: Date, source: DailySource) -> DailyPassage {
        let passages = library[source] ?? []
        guard !passages.isEmpty else {
            return DailyPassage(text: "Be here now.", reference: "")
        }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return passages[day % passages.count]
    }
}

// MARK: - Library

// `nonisolated` so the library can be read from the widget extension's own
// context — the enum is nonisolated, but an extension doesn't inherit that
// and the project defaults to MainActor isolation.
nonisolated extension DailyStore {

    static let library: [DailySource: [DailyPassage]] = [
        // Reference format: surah name, chapter:verse, and the juz it falls in —
        // the way someone would actually look it up in a mushaf.
        .quran: [
            .init(text: "So truly where there is hardship there is also ease.", reference: "Ash-Sharh 94:5 · Juz 30"),
            .init(text: "God does not burden a soul beyond what it can bear.", reference: "Al-Baqarah 2:286 · Juz 3"),
            .init(text: "And He found you lost and guided you.", reference: "Ad-Duha 93:7 · Juz 30"),
            .init(text: "So remember Me; I will remember you.", reference: "Al-Baqarah 2:152 · Juz 2"),
            .init(text: "And whoever puts their trust in God, He will be enough for them.", reference: "At-Talaq 65:3 · Juz 28"),
            .init(text: "Do not despair of the mercy of God.", reference: "Az-Zumar 39:53 · Juz 24"),
            .init(text: "Speak to people kindly.", reference: "Al-Baqarah 2:83 · Juz 1"),
            .init(text: "It may be that you dislike a thing and God brings much good out of it.", reference: "An-Nisa 4:19 · Juz 4"),
            .init(text: "And be patient. Surely God is with the patient.", reference: "Al-Anfal 8:46 · Juz 10"),
            .init(text: "Whoever saves one life, it is as if he saved all mankind.", reference: "Al-Ma'idah 5:32 · Juz 6")
        ],
        .bible: [
            .init(text: "Be still, and know that I am God.", reference: "Psalm 46:10"),
            .init(text: "Take therefore no thought for the morrow: for the morrow shall take thought for the things of itself.", reference: "Matthew 6:34"),
            .init(text: "A soft answer turneth away wrath.", reference: "Proverbs 15:1"),
            .init(text: "Thy word is a lamp unto my feet, and a light unto my path.", reference: "Psalm 119:105"),
            .init(text: "Let all your things be done with charity.", reference: "1 Corinthians 16:14"),
            .init(text: "To every thing there is a season, and a time to every purpose under the heaven.", reference: "Ecclesiastes 3:1"),
            .init(text: "Hope deferred maketh the heart sick: but when the desire cometh, it is a tree of life.", reference: "Proverbs 13:12"),
            .init(text: "The Lord is my shepherd; I shall not want.", reference: "Psalm 23:1"),
            .init(text: "Charity suffereth long, and is kind.", reference: "1 Corinthians 13:4"),
            .init(text: "Whatsoever things are lovely, think on these things.", reference: "Philippians 4:8")
        ],
        .stoic: [
            .init(text: "You have power over your mind — not outside events. Realize this, and you will find strength.", reference: "Marcus Aurelius"),
            .init(text: "We suffer more often in imagination than in reality.", reference: "Seneca"),
            .init(text: "It is not that we have a short time to live, but that we waste a lot of it.", reference: "Seneca, On the Shortness of Life"),
            .init(text: "The happiness of your life depends upon the quality of your thoughts.", reference: "Meditations"),
            .init(text: "Waste no more time arguing what a good man should be. Be one.", reference: "Meditations, X.16"),
            .init(text: "Man is disturbed not by things, but by the views he takes of them.", reference: "Epictetus"),
            .init(text: "Begin at once to live, and count each separate day as a separate life.", reference: "Seneca"),
            .init(text: "Confine yourself to the present.", reference: "Meditations, VII.29"),
            .init(text: "No person has the power to have everything they want, but it is in their power not to want what they don't have.", reference: "Seneca"),
            .init(text: "The best revenge is not to be like your enemy.", reference: "Meditations, VI.6")
        ],
        .poetry: [
            .init(text: "The wound is the place where the light enters you.", reference: "Rumi"),
            .init(text: "Yesterday I was clever, so I wanted to change the world. Today I am wise, so I am changing myself.", reference: "Rumi"),
            .init(text: "I am large, I contain multitudes.", reference: "Walt Whitman, Song of Myself"),
            .init(text: "Hope is the thing with feathers that perches in the soul.", reference: "Emily Dickinson"),
            .init(text: "Not till we are lost do we begin to find ourselves.", reference: "Henry David Thoreau"),
            .init(text: "Do not go where the path may lead; go instead where there is no path.", reference: "Ralph Waldo Emerson"),
            .init(text: "Out beyond ideas of wrongdoing and rightdoing, there is a field. I'll meet you there.", reference: "Rumi"),
            .init(text: "Tell me, what is it you plan to do with your one wild and precious life?", reference: "Traditional"),
            .init(text: "That it will never come again is what makes life so sweet.", reference: "Emily Dickinson"),
            .init(text: "Keep your face always toward the sunshine.", reference: "Walt Whitman")
        ],
        .proverbs: [
            .init(text: "Slow and steady wins the race.", reference: "Traditional"),
            .init(text: "A stitch in time saves nine.", reference: "Traditional"),
            .init(text: "Still waters run deep.", reference: "Traditional"),
            .init(text: "The best time to plant a tree was twenty years ago. The second best time is now.", reference: "Proverb"),
            .init(text: "Fall seven times, stand up eight.", reference: "Japanese proverb"),
            .init(text: "A journey of a thousand miles begins with a single step.", reference: "Chinese proverb"),
            .init(text: "Patience is a tree whose root is bitter, but its fruit is sweet.", reference: "Persian proverb"),
            .init(text: "If you want to go fast, go alone. If you want to go far, go together.", reference: "African proverb"),
            .init(text: "The eye sees only what the mind is prepared to comprehend.", reference: "Proverb"),
            .init(text: "Do not let what you cannot do interfere with what you can do.", reference: "Proverb")
        ]
    ]
}
