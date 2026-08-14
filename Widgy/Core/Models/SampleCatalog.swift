//
//  SampleCatalog.swift
//  Widgy
//
//  Seed catalog. Aurora (live clock) and Focus (live deep-work timer) are
//  fixed-design live WidgetKit widgets: each ships its own store image and is
//  locked, not editable in the app. "Custom" is the one template with no
//  store image — it's the only entry that opens the "make your own" editor.
//

import Foundation

nonisolated enum SampleCatalog {

    static let authors: [Author] = [
        Author(id: "a1", displayName: "Nova Studio", handle: "@novastudio", isVerified: true),
        Author(id: "a2", displayName: "Deniz Kaya", handle: "@denizmakes"),
        Author(id: "a-kare", displayName: "Kare", handle: "@kare", isVerified: true)
    ]

    static let reviews: [Review] = [
        Review(templateID: "t-aurora", authorName: "Selin", stars: 5,
               text: "The colour shift through the day is so calming. Instant home screen upgrade.",
               createdAt: .now.addingTimeInterval(-86_400 * 2)),
        Review(templateID: "t-aurora", authorName: "Mert", stars: 4,
               text: "Beautiful. Love that the background follows the light.",
               createdAt: .now.addingTimeInterval(-86_400 * 6)),
        Review(templateID: "t-focus", authorName: "Aylin", stars: 5,
               text: "The live countdown on my home screen actually keeps me honest. Worth it.",
               createdAt: .now.addingTimeInterval(-86_400 * 1))
    ]

    /// Catalog templates, each with a store image (`previewImageName`) and a
    /// ready-made editable design (`content`).
    static let templates: [WidgetTemplate] = baseTemplates.map {
        var template = $0
        template.content = contentByID[$0.id]
        template.previewImageName = previewByID[$0.id]
        template.sizePreviewBaseName = sizeBaseByID[$0.id]
        template.galleryName = galleryNameByID[$0.id]
        return template
    }

    /// What each widget is called in the iOS widget gallery. Must match the
    /// `configurationDisplayName` in the widget extension exactly.
    private static let galleryNameByID: [String: String] = [
        "t-aurora": "Aurora",
        "t-focus": "Focus Stack",
        "t-frame": "Frame",
        "t-hush": "Hush",
        "t-daily": "Daily",
        "t-proverb": "Söz",
        "t-custom": "Kare"
    ]

    /// Base name for per-size product images: "aurora" -> aurora_small/medium/large.
    private static let sizeBaseByID: [String: String] = [
        "t-aurora": "aurora",
        "t-focus": "focus"
    ]

    private static let baseTemplates: [WidgetTemplate] = [
        WidgetTemplate(
            id: "t-aurora",
            name: "Aurora Clock",
            summary: "A live clock whose aurora background follows the light of day. Also sits on your lock screen.",
            author: authors[0],
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["2C1E5C", "7B3FA0", "E0639A"],
                accentHex: "FFD8A8",
                usesGlassEffect: true
            ),
            tags: ["clock", "gradient", "live"],
            installCount: 184_320,
            rating: 4.8,
            ratingCount: 5_214,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 12)
        ),
        WidgetTemplate(
            id: "t-focus",
            name: "Focus Stack",
            summary: "A live deep-work timer. Start it, and the countdown follows you to the lock screen.",
            author: authors[1],
            category: .productivity,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["10151F", "1E2B3C"],
                accentHex: "4CC9F0"
            ),
            tags: ["focus", "timer", "live"],
            installCount: 96_140,
            rating: 4.7,
            ratingCount: 2_880,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 30)
        ),
        WidgetTemplate(
            id: "t-frame",
            name: "Frame",
            summary: "Your own photo on the home screen, with a caption if you want one. Pick it once and it stays.",
            author: authors[0],
            category: .photos,
            supportedSizes: [.small, .medium, .large],
            theme: WidgetTheme(
                backgroundHexes: ["241C1C", "5B4038"],
                accentHex: "E5D5C8"
            ),
            tags: ["photo", "personal", "memories"],
            installCount: 71_450,
            rating: 4.9,
            ratingCount: 3_102,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 8)
        ),
        WidgetTemplate(
            id: "t-hush",
            name: "Hush",
            summary: "One quiet word, changing through the day. Nothing to tap, nothing to manage.",
            author: authors[1],
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["0A0A0A", "1A1A1A"],
                accentHex: "E8E6E3"
            ),
            tags: ["calm", "minimal", "mindful"],
            installCount: 44_890,
            rating: 4.8,
            ratingCount: 1_640,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 4)
        ),
        WidgetTemplate(
            id: "t-daily",
            name: "Daily",
            summary: "A passage a day, from the source you choose — scripture, Stoic philosophy, poetry or proverbs. Always shown with its reference.",
            author: authors[2],
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["FAF3E7", "EBDCC4"],
                accentHex: "2B2018"
            ),
            tags: ["quote", "daily", "reflection"],
            installCount: 0,
            rating: 5.0,
            ratingCount: 0,
            price: .free,
            publishedAt: .now
        ),
        WidgetTemplate(
            id: "t-proverb",
            name: "Söz",
            summary: "A Turkish proverb or idiom every four hours, with its meaning and an example. From 400 sayings.",
            author: authors[2],
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["FBF4EA", "F0E2CE"],
                accentHex: "C05A3E"
            ),
            tags: ["atasözü", "deyim", "türkçe"],
            installCount: 0,
            rating: 5.0,
            ratingCount: 0,
            price: .free,
            publishedAt: .now
        ),
        WidgetTemplate(
            id: "t-custom",
            name: "Custom Widget",
            summary: "Design your own from scratch: pick a background, add your text, drop in stickers — exactly how you want it.",
            author: authors[2],
            category: .minimal,
            supportedSizes: [.small, .medium, .large],
            theme: WidgetTheme(
                backgroundHexes: ["1D1D1F", "3A3A3C"],
                accentHex: "D44A33"
            ),
            tags: ["custom", "editor", "diy"],
            installCount: 0,
            rating: 5.0,
            ratingCount: 0,
            price: .free,
            publishedAt: .now,
            isEditable: true
        )
    ]

    /// Store/marketing images shown in the catalog.
    private static let previewByID: [String: String] = [
        "t-aurora": "aurora_widget",
        "t-focus": "focus_widget",
        "t-frame": "frame_widget",
        "t-hush": "hush_widget",
        "t-daily": "daily_widget",
        "t-proverb": "soz_widget"
    ]

    /// Editable starting designs. ONLY for customizable templates.
    ///
    /// Aurora and Focus deliberately have no entry here: they're fixed-design
    /// live widgets drawn by their own WidgetKit views (AuroraWidget/FocusWidget)
    /// from our real artwork. Giving them a `content` payload is what previously
    /// let them be opened in the editor and mirrored into the generic "Kare"
    /// widget, which then rendered Aurora's gradient instead of the real thing.
    private static let contentByID: [String: WidgetContent] = [
        "t-custom": WidgetContent(
            text: "Your\nwidget", fontStyle: .serif, fontSize: 26, textColorHex: "FFFFFF",
            alignment: .leading, background: .color(["1D1D1F", "3A3A3C"]),
            stickers: [.init(symbolName: "sparkles", x: 0.82, y: 0.22, scale: 1.0, colorHex: "D44A33")]
        )
    ]
}
