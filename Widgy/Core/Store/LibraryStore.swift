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
