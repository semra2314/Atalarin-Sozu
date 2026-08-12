//
//  WidgySelection.swift
//  Widgy  (shared: app + widget extension)
//
//  Lets each placed custom widget remember which saved design it shows.
//
//  Without this, every instance of the widget read the same single payload, so
//  placing two custom widgets gave you the same design twice. Long-pressing a
//  widget and choosing "Edit Widget" now offers the user's saved designs.
//

import AppIntents
import WidgetKit

/// One entry in the widget's "Design" picker.
nonisolated struct WidgyDesign: AppEntity, Identifiable, Hashable {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Design" }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery: WidgyDesignQuery { WidgyDesignQuery() }
}

nonisolated struct WidgyDesignQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WidgyDesign] {
        allDesigns().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WidgyDesign] {
        allDesigns()
    }

    func defaultResult() async -> WidgyDesign? {
        allDesigns().first
    }

    private func allDesigns() -> [WidgyDesign] {
        SharedWidgetStore.all().map { WidgyDesign(id: $0.id, name: $0.name) }
    }
}

// Not marked `nonisolated`: `@Parameter` is a mutable stored property, and
// `nonisolated` can't be applied to one — an error outright in Swift 6.
struct SelectDesignIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose a design" }
    static var description: IntentDescription {
        IntentDescription("Pick which of your saved designs this widget shows.")
    }

    @Parameter(title: "Design")
    var design: WidgyDesign?

    init() {}

    init(design: WidgyDesign?) {
        self.design = design
    }
}
