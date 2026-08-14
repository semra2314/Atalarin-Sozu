//
//  LibraryStore.swift
//  Widgy
//

import Foundation
import Observation
import SwiftData

/// Owns every write to the local library. Views observe SwiftData with `@Query`
/// and route mutations through here, so persistence rules live in one place.
@MainActor
@Observable
final class LibraryStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func isInstalled(templateID: String) -> Bool {
        ((try? fetch(templateID: templateID)) ?? nil) != nil
    }

    @discardableResult
    func install(_ template: WidgetTemplate, size: WidgetSize) throws -> InstalledWidget {
        if let existing = try fetch(templateID: template.id) {
            return existing
        }
        let nextIndex = (try? context.fetchCount(FetchDescriptor<InstalledWidget>())) ?? 0
        let widget = InstalledWidget(template: template, size: size, sortIndex: nextIndex)
        context.insert(widget)
        try context.save()
        return widget
    }

    /// Puts the built-in catalogue into the library the first time the app
    /// runs, so nobody lands on an empty Widgets tab and an empty profile.
    ///
    /// This is a product decision, not a demo trick: the six widgets ship
    /// inside the app, they cost nothing, and a new user has no way of knowing
    /// what "add a widget" means until they can see one. They can be removed
    /// like anything else. Only the fixed designs are seeded; the make-your-own
    /// template stays out, because an empty custom widget has nothing to show.
    ///
    /// Idempotent by way of `install`, which returns the existing record rather
    /// than duplicating, so a second call is harmless.
    func seedBuiltInsIfNeeded() throws {
        let existing = (try? context.fetchCount(FetchDescriptor<InstalledWidget>())) ?? 0
        guard existing == 0 else { return }

        for template in SampleCatalog.templates where !template.isEditable {
            try install(template, size: template.primarySize)
        }
    }

    func remove(templateID: String) throws {
        guard let existing = try fetch(templateID: templateID) else { return }
        context.delete(existing)
        try context.save()
        // Drop the mirrored design too, so a placed widget stops offering a
        // design the user has deleted.
        SharedWidgetStore.remove(id: templateID)
    }

    func toggleFavorite(_ widget: InstalledWidget) throws {
        widget.isFavorite.toggle()
        try context.save()
    }

    /// Persist the editor payload for a widget.
    func updateContent(_ widget: InstalledWidget, content: WidgetContent) throws {
        widget.contentData = try JSONEncoder().encode(content)
        try context.save()
    }

    func reorder(_ widgets: [InstalledWidget]) throws {
        for (index, widget) in widgets.enumerated() {
            widget.sortIndex = index
        }
        try context.save()
    }

    private func fetch(templateID: String) throws -> InstalledWidget? {
        var descriptor = FetchDescriptor<InstalledWidget>(
            predicate: #Predicate { $0.templateID == templateID }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
