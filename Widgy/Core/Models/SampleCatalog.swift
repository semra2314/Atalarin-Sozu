//
//  SampleCatalog.swift
//  Kare
//
//  Seed catalog. Aurora (live clock) and Focus (live deep-work timer) are
//  fixed-design live WidgetKit widgets: each ships its own store image and is
//  locked, not editable in the app. "Custom" is the one template with no
//  store image — it's the only entry that opens the "make your own" editor.
//

import Foundation

nonisolated enum SampleCatalog {

    /// The one real creator.
    ///
    /// The catalogue used to be credited to "Nova Studio" and "Deniz Kaya",
    /// one of them with a verified tick. Neither exists. Everything that ships
    /// inside the app was made by us, so it is all credited to Kare itself
    /// rather than to a personal handle: these are the house widgets, and the
    /// first-party shelf of a marketplace should read as the house.
    ///
    /// When other people publish through the portal this becomes a list again,
    /// and each entry will be someone who signed the agreement.
    static let owner = Author(
        id: "a-kare",
        displayName: "Kare",
        handle: "@kare",
        isVerified: true
    )

    static let authors: [Author] = [owner]

    /// Deliberately empty.
    ///
    /// This used to seed three glowing five-star reviews from "Selin", "Mert"
    /// and "Aylin". They were invented, and they rendered on the Aurora and
    /// Focus detail pages as though real people had written them. App Store
    /// Review guideline 3.2.2(vii) prohibits exactly that, and it is the kind
    /// of thing a reviewer notices in a brand-new app with no users.
    ///
    /// The detail page already handles the empty case honestly: no average is
    /// drawn, and it says "No written reviews yet. Be the first." Reviews
    /// written by real people in the app still appear here. An empty shelf we
    /// can fill is worth more than a full one we made up.
    static let reviews: [Review] = []

    /// Catalog templates, each with a store image (`previewImageName`) and a
    /// ready-made editable design (`content`).
    static let templates: [WidgetTemplate] = (baseTemplates + presetTemplates).map {
        var template = $0
        template.content = contentByID[$0.id]
        template.previewImageName = previewByID[$0.id]
        template.sizePreviewBaseName = sizeBaseByID[$0.id]
        // Presets have no entry of their own: they all run inside the one
        // generic "Kare" widget, so that is what the user must look for in the
        // iOS gallery. Anything editable without an explicit name is a preset.
        template.galleryName = galleryNameByID[$0.id] ?? (template.isEditable ? "Kare" : nil)
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
        "t-exhale": "Exhale",
        "t-countdown": "Countdown",
        "t-progress": "Progress",
        "t-custom": "Kare"
    ]

    /// Live widgets that have settings of their own. Those settings open only
    /// from the user's library, never from the market page.
    static let setupTemplateIDs: Set<String> = [
        "t-focus", "t-frame", "t-daily", "t-exhale", "t-countdown", "t-progress"
    ]

    /// The Kare+ live widgets, in the order Discover shows them.
    static let liveKarePlusIDs = ["t-exhale", "t-countdown", "t-progress"]

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
            author: owner,
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["2C1E5C", "7B3FA0", "E0639A"],
                accentHex: "FFD8A8",
                usesGlassEffect: true
            ),
            tags: ["clock", "gradient", "live"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 12)
        ),
        WidgetTemplate(
            id: "t-focus",
            name: "Focus Stack",
            summary: "A live deep-work timer. Start it, and the countdown follows you to the lock screen.",
            author: owner,
            category: .productivity,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["10151F", "1E2B3C"],
                accentHex: "4CC9F0"
            ),
            tags: ["focus", "timer", "live"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 30)
        ),
        WidgetTemplate(
            id: "t-frame",
            name: "Frame",
            summary: "Your own photo on the home screen, with a caption if you want one. Pick it once and it stays.",
            author: owner,
            category: .photos,
            supportedSizes: [.small, .medium, .large],
            theme: WidgetTheme(
                backgroundHexes: ["241C1C", "5B4038"],
                accentHex: "E5D5C8"
            ),
            tags: ["photo", "personal", "memories"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 8)
        ),
        WidgetTemplate(
            id: "t-hush",
            name: "Hush",
            summary: "One quiet word, changing through the day. Nothing to tap, nothing to manage.",
            author: owner,
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["0A0A0A", "1A1A1A"],
                accentHex: "E8E6E3"
            ),
            tags: ["calm", "minimal", "mindful"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: .free,
            publishedAt: .now.addingTimeInterval(-86_400 * 4)
        ),
        WidgetTemplate(
            id: "t-daily",
            name: "Daily",
            summary: "A passage a day, from the source you choose: scripture, Stoic philosophy, poetry or proverbs. Always shown with its reference.",
            author: owner,
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["FAF3E7", "EBDCC4"],
                accentHex: "2B2018"
            ),
            tags: ["quote", "daily", "reflection"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: .free,
            publishedAt: .now
        ),
        WidgetTemplate(
            id: "t-proverb",
            name: "Söz",
            summary: "A Turkish proverb or idiom every four hours, with its meaning and an example. From 400 sayings.",
            author: owner,
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["FBF4EA", "F0E2CE"],
                accentHex: "C05A3E"
            ),
            tags: ["atasözü", "deyim", "türkçe"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: .free,
            publishedAt: .now
        ),
        // Kare+ live widgets. Drawn by their own WidgetKit views and set up
        // in the app (ExhaleSetupView, CountdownSetupView, ProgressSetupView).
        WidgetTemplate(
            id: "t-exhale",
            name: "Exhale",
            summary: "For quitting smoking. Your lungs fill as your body recovers, with days smoke-free and the money you kept. Tap the lungs to breathe.",
            author: owner,
            category: .health,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["0B1F1D", "124A42"],
                accentHex: "A7F3D0"
            ),
            tags: ["quit smoking", "sigara", "sigarayı bırak", "nefes al", "health", "lungs", "live"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: usd(199),
            publishedAt: .now
        ),
        WidgetTemplate(
            id: "t-countdown",
            name: "Countdown",
            summary: "Days until the day you are waiting for: a trip, a wedding, an exam. One dot per day, filling as it gets closer.",
            author: owner,
            category: .productivity,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["1E3A8A", "312E81"],
                accentHex: "FFFFFF"
            ),
            tags: ["countdown", "geri sayım", "days", "event", "live"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: usd(199),
            publishedAt: .now
        ),
        WidgetTemplate(
            id: "t-progress",
            name: "Progress",
            summary: "How much of the day, week, month or year has passed, or of your life. A big number and one dot per unit.",
            author: owner,
            category: .minimal,
            supportedSizes: [.small, .medium, .large, .accessoryCircular, .accessoryRectangular],
            theme: WidgetTheme(
                backgroundHexes: ["F6F1E7", "EDE4D3"],
                accentHex: "D44A33"
            ),
            tags: ["year progress", "life in weeks", "time", "minimal", "live"],
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: usd(199),
            publishedAt: .now
        ),
        WidgetTemplate(
            id: "t-custom",
            name: "Custom Widget",
            summary: "Design your own from scratch: pick a background, add your text, drop in stickers, exactly how you want it.",
            author: owner,
            category: .minimal,
            supportedSizes: [.small, .medium, .large],
            theme: WidgetTheme(
                backgroundHexes: ["1D1D1F", "3A3A3C"],
                accentHex: "D44A33"
            ),
            tags: ["custom", "editor", "diy"],
            installCount: 0,
            rating: 0, ratingCount: 0,
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
        "t-proverb": "soz_widget",
        // Kare+ store art. Until these are in the asset catalogue the
        // catalogue draws `LiveWidgetPreview` instead.
        "t-exhale": "exhale_widget",
        "t-countdown": "countdown_widget",
        "t-progress": "progress_widget",
        // Market art for the editable designs. In the library and on the
        // detail page's size picker they still draw their real design.
        "t-custom": "custom_widget",
        "p-sunset": "sunset_widget",
        "p-hydrate": "hydrate_widget",
        "p-deepwork": "deepwork_widget",
        "p-pastel": "pastel_widget",
        "p-mood": "mood_widget",
        "p-us": "us_widget",
        "p-momentum": "momentum_widget",
        "p-neon": "neon_widget",
        "p-gratitude": "gratitude_widget",
        "p-mono": "mono_widget"
    ]

    // MARK: - Presets

    /// Ready-made designs that reuse the one generic "Kare" widget.
    ///
    /// A preset is not a new widget. It ships no WidgetKit extension, no
    /// timeline provider, no artwork and no new target: it is a catalog entry
    /// plus a `WidgetContent`, and `WidgetPreview` already renders that content
    /// through `CustomWidgetView` when there is no store image. So the card in
    /// Discover shows the design exactly as it will look on the home screen,
    /// drawn from the same code that will draw it there. Ten of these cost less
    /// than one more fixed widget, and they carry no extra App Store review
    /// surface.
    ///
    /// They also fix the shape of the catalog. Five of the seven fixed widgets
    /// were `.minimal`, so tapping any other category in Discover led to a
    /// nearly empty shelf. These spread across health, fun, social and
    /// productivity.
    ///
    /// Every preset is editable: the user opens it, changes the words to their
    /// own, and saves. That is the point. It is a starting line, not a poster.
    private static let presetTemplates: [WidgetTemplate] = [
        preset(id: "p-sunset", name: "Sunset", summary: "A warm gradient and a soft greeting. Change the words to whatever you want to read at a glance.",
               category: .minimal, tags: ["gradient", "warm", "greeting"],
               backgroundHexes: ["FF9A6C", "F76B8A", "8E44AD"], accentHex: "FFE3D0"),

        preset(id: "p-hydrate", name: "Hydrate", summary: "A nudge to drink water, sitting where you already look a hundred times a day.",
               category: .health, tags: ["water", "habit", "reminder"],
               backgroundHexes: ["7FD8F7", "3AA9E0"], accentHex: "F0FBFF"),

        preset(id: "p-deepwork", name: "Deep Work", summary: "One instruction, in monospace, on a cold dark gradient. For the hours that matter.",
               category: .productivity, tags: ["focus", "mono", "dark"],
               backgroundHexes: ["0F2027", "203A43", "2C5364"], accentHex: "9EE7FF"),

        preset(id: "p-pastel", name: "Pastel", summary: "Soft pink into periwinkle, with room for a short hello. The friendliest thing on the screen.",
               category: .fun, tags: ["pastel", "soft", "cute"],
               backgroundHexes: ["FBC2EB", "A6C1EE"], accentHex: "4A2C5A"),

        preset(id: "p-mood", name: "Mood", summary: "Today in one word and one emoji. Edit it whenever the mood turns.",
               category: .social, tags: ["mood", "emoji", "status"],
               backgroundHexes: ["2C2C34", "44444F"], accentHex: "F2F2F5"),

        preset(id: "p-us", name: "Us", summary: "A small private thing for a person you like. Two words and a heart.",
               category: .social, tags: ["couple", "heart", "personal"],
               backgroundHexes: ["3B1D2E", "8E3B5E"], accentHex: "FFD9E4"),

        // Paid. These are the ones Kare+ unlocks, so they carry more
        // composition than the free set: layered type, placed stickers,
        // considered colour.
        preset(id: "p-momentum", name: "Momentum", summary: "A single line to hold you to one thing at a time. Heavy serif on near-black.",
               category: .productivity, tags: ["discipline", "serif", "minimal"],
               backgroundHexes: ["101010", "2B2B2B"], accentHex: "F5F5F5",
               price: usd(99)),

        preset(id: "p-neon", name: "Neon", summary: "Electric magenta bleeding into deep violet. Loud, on purpose.",
               category: .fun, tags: ["neon", "night", "bold"],
               backgroundHexes: ["1A0033", "3D0066", "FF00AA"], accentHex: "FFFFFF",
               price: usd(99)),

        preset(id: "p-gratitude", name: "Gratitude", summary: "A warm paper card with a prompt you finish yourself. Rewrite it each morning.",
               category: .health, tags: ["gratitude", "journal", "calm"],
               backgroundHexes: ["FDF6E3", "F5E6C8"], accentHex: "3A2E1F",
               price: usd(99)),

        preset(id: "p-mono", name: "Monochrome", summary: "Black type on off-white, and nothing else. The one that disappears into a clean home screen.",
               category: .minimal, tags: ["white", "editorial", "clean"],
               backgroundHexes: ["FFFFFF", "F0F0F0"], accentHex: "111111",
               price: usd(99))
    ]

    /// Presets share every field except identity, look and price, so they are
    /// built here rather than written out ten times. `isEditable` is always
    /// true: a preset the user cannot rewrite is just a poster.
    private static func preset(
        id: String,
        name: String,
        summary: String,
        category: WidgetCategory,
        tags: [String],
        backgroundHexes: [String],
        accentHex: String,
        price: WidgetTemplate.Price = .free
    ) -> WidgetTemplate {
        WidgetTemplate(
            id: id,
            name: name,
            summary: summary,
            author: owner,
            category: category,
            supportedSizes: [.small, .medium, .large],
            theme: WidgetTheme(backgroundHexes: backgroundHexes, accentHex: accentHex),
            tags: tags,
            installCount: 0,
            rating: 0, ratingCount: 0,
            price: price,
            publishedAt: .now,
            isEditable: true
        )
    }

    /// Money as exact decimal cents. `Decimal` conforms to
    /// `ExpressibleByFloatLiteral` through `Double`, so writing `0.99` inline
    /// would store 0.9899999999999999 and eventually print it.
    private static func usd(_ cents: Int) -> WidgetTemplate.Price {
        .paid(amount: Decimal(cents) / 100, currencyCode: "USD")
    }

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
    ].merging(presetContent) { current, _ in current }

    // MARK: - Preset designs

    /// The actual artwork for each preset, expressed as editor data.
    ///
    /// Everything lives in `texts` rather than the legacy single `text` field.
    /// The two are not interchangeable: `CustomWidgetView` draws `texts`, and
    /// only the *decoder* lifts a legacy `text` into it. A design built in
    /// memory with `text:` alone and no `texts:` would render blank.
    private static let presetContent: [String: WidgetContent] = [

        "p-sunset": design(
            ["FF9A6C", "F76B8A", "8E44AD"],
            texts: [
                .init(text: "good\nevening", fontStyle: .serif, fontWeight: .heavy,
                      fontSize: 30, colorHex: "FFFFFF", alignment: .leading,
                      x: 0.36, y: 0.32, widthFraction: 0.72)
            ]
        ),

        "p-hydrate": design(
            ["7FD8F7", "3AA9E0"],
            texts: [
                .init(text: "drink\nwater", fontStyle: .rounded, fontWeight: .heavy,
                      fontSize: 28, colorHex: "FFFFFF", alignment: .leading,
                      x: 0.35, y: 0.31, widthFraction: 0.7)
            ],
            stickers: [.init(emoji: "💧", x: 0.76, y: 0.74, scale: 1.7)]
        ),

        "p-deepwork": design(
            ["0F2027", "203A43", "2C5364"],
            texts: [
                .init(text: "deep\nwork", fontStyle: .monospaced, fontWeight: .bold,
                      fontSize: 27, colorHex: "9EE7FF", alignment: .leading,
                      x: 0.34, y: 0.33, widthFraction: 0.7)
            ],
            stickers: [.init(symbolName: "moon.stars.fill", x: 0.79, y: 0.77,
                             scale: 0.9, colorHex: "9EE7FF")]
        ),

        "p-pastel": design(
            ["FBC2EB", "A6C1EE"],
            texts: [
                .init(text: "hi :)", fontStyle: .rounded, fontWeight: .heavy,
                      fontSize: 36, colorHex: "4A2C5A", alignment: .center,
                      x: 0.5, y: 0.5, widthFraction: 0.85)
            ]
        ),

        "p-mood": design(
            ["2C2C34", "44444F"],
            texts: [
                .init(text: "today", fontStyle: .monospaced, fontWeight: .semibold,
                      fontSize: 12, colorHex: "9A9AA5", alignment: .leading,
                      x: 0.30, y: 0.24, widthFraction: 0.5),
                .init(text: "calm", fontStyle: .serif, fontWeight: .heavy,
                      fontSize: 30, colorHex: "F2F2F5", alignment: .leading,
                      x: 0.34, y: 0.50, widthFraction: 0.7)
            ],
            stickers: [.init(emoji: "🌙", x: 0.78, y: 0.77, scale: 1.4)]
        ),

        "p-us": design(
            ["3B1D2E", "8E3B5E"],
            texts: [
                .init(text: "us", fontStyle: .serif, fontWeight: .heavy,
                      fontSize: 40, colorHex: "FFD9E4", alignment: .center,
                      x: 0.5, y: 0.44, widthFraction: 0.8)
            ],
            stickers: [.init(emoji: "❤️", x: 0.5, y: 0.72, scale: 1.2)]
        ),

        // Paid designs. Two type sizes instead of one, and a placed sticker,
        // so the extra composition is visible on the card before anyone pays.

        "p-momentum": design(
            ["101010", "2B2B2B"],
            texts: [
                .init(text: "one thing", fontStyle: .serif, fontWeight: .heavy,
                      fontSize: 26, colorHex: "F5F5F5", alignment: .leading,
                      x: 0.39, y: 0.42, widthFraction: 0.78),
                .init(text: "at a time", fontStyle: .serif, fontWeight: .regular,
                      fontSize: 26, colorHex: "8A8A8A", alignment: .leading,
                      x: 0.38, y: 0.60, widthFraction: 0.78)
            ],
            stickers: [.init(symbolName: "arrow.up.right", x: 0.82, y: 0.20,
                             scale: 0.8, colorHex: "F5F5F5")]
        ),

        "p-neon": design(
            ["1A0033", "3D0066", "FF00AA"],
            texts: [
                .init(text: "stay", fontStyle: .rounded, fontWeight: .heavy,
                      fontSize: 34, colorHex: "FFFFFF", alignment: .leading,
                      x: 0.32, y: 0.38, widthFraction: 0.7),
                .init(text: "weird", fontStyle: .rounded, fontWeight: .heavy,
                      fontSize: 34, colorHex: "00F0FF", alignment: .leading,
                      x: 0.38, y: 0.62, widthFraction: 0.7)
            ],
            stickers: [.init(emoji: "⚡️", x: 0.80, y: 0.19, scale: 1.3)]
        ),

        "p-gratitude": design(
            ["FDF6E3", "F5E6C8"],
            texts: [
                .init(text: "today I'm\ngrateful for", fontStyle: .serif,
                      fontWeight: .semibold, fontSize: 19, colorHex: "3A2E1F",
                      alignment: .leading, x: 0.40, y: 0.36, widthFraction: 0.76)
            ],
            stickers: [.init(symbolName: "leaf.fill", x: 0.79, y: 0.78,
                             scale: 0.9, colorHex: "9CAF88")]
        ),

        "p-mono": design(
            ["FFFFFF", "F0F0F0"],
            texts: [
                .init(text: "NOTE", fontStyle: .monospaced, fontWeight: .bold,
                      fontSize: 12, colorHex: "9A9A9A", alignment: .leading,
                      x: 0.29, y: 0.23, widthFraction: 0.5),
                .init(text: "keep it\nsimple", fontStyle: .serif, fontWeight: .heavy,
                      fontSize: 26, colorHex: "111111", alignment: .leading,
                      x: 0.38, y: 0.54, widthFraction: 0.76)
            ]
        )
    ]

    /// Builds a preset design from a gradient and its placed elements.
    ///
    /// `text` is left empty on purpose: it is the pre-`texts` field, kept only
    /// so old saved widgets still decode. Filling both would put the same words
    /// on the canvas twice for anyone whose design round-trips.
    private static func design(
        _ backgroundHexes: [String],
        texts: [WidgetContent.TextElement],
        stickers: [WidgetContent.Sticker] = []
    ) -> WidgetContent {
        WidgetContent(
            text: "",
            background: .color(backgroundHexes),
            stickers: stickers,
            texts: texts
        )
    }
}
