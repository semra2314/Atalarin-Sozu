//
//  LibraryStore.swift
//  Kare
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

        // Hand the design to the widget extension straight away.
        //
        // SwiftData lives in the app; the extension is a separate process and
        // reads only what SharedWidgetStore has written to the App Group. Until
        // now the only thing that ever wrote there was the editor's save. That
        // was survivable when the one editable template started blank, but a
        // ready-made preset is meant to work without being edited at all: you
        // add it, you go to the home screen, you pick it. Without this line it
        // never reached the "Design" picker, so the widget showed some other
        // design and the preset looked broken through no fault of the user.
        if let content = template.content {
            SharedWidgetStore.save(id: template.id,
                                   content: content,
                                   family: size,
                                   name: template.name)
        }

        syncMirror()
        return widget
    }

    /// Tells the widget extension which widgets are in the library. A new
    /// user starts with none, and the widget picker only offers what is here.
    func syncMirror() {
        let all = (try? context.fetch(FetchDescriptor<InstalledWidget>())) ?? []
        LibraryMirror.set(Set(all.map(\.templateID)))
    }

    /// Returns what the "why did you remove it?" survey needs to know.
    @discardableResult
    func remove(templateID: String) throws -> RemovalSurveyTarget? {
        guard let existing = try fetch(templateID: templateID) else { return nil }
        let days = Calendar.current.dateComponents([.day], from: existing.addedAt, to: .now).day
        let target = RemovalSurveyTarget(templateID: existing.templateID, name: existing.name, daysInstalled: days)
        context.delete(existing)
        try context.save()
        // Drop the mirrored design too, so a placed widget stops offering a
        // design the user has deleted.
        SharedWidgetStore.remove(id: templateID)
        syncMirror()
        return target
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
