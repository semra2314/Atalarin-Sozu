//
//  LibraryView.swift
//  Kare
//

import SwiftUI
import SwiftData
import UIKit

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \InstalledWidget.sortIndex)
    private var widgets: [InstalledWidget]

    @State private var showFavoritesOnly = false
    @State private var surveyTarget: RemovalSurveyTarget?

    private var visible: [InstalledWidget] {
        showFavoritesOnly ? widgets.filter(\.isFavorite) : widgets
    }

    var body: some View {
        Group {
            if widgets.isEmpty {
                VStack(spacing: 0) {
                    header.padding(.horizontal, Theme.Spacing.lg).padding(.top, Theme.Spacing.md)
                    emptyState
                }
                .kareReadableWidth()
            } else {
                list
            }
        }
        .background(Theme.Palette.background)
        // Same serif header as every other tab, drawn in the content column
        // instead of the system large title, which sat at the screen edge on
        // iPad while the list sat in the middle.
        .navigationTitle("Library")
        .toolbar(.hidden, for: .navigationBar)
        .removalSurvey($surveyTarget)
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("Library")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            if !widgets.isEmpty {
                Button {
                    withAnimation { showFavoritesOnly.toggle() }
                } label: {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundStyle(showFavoritesOnly ? Theme.Palette.accent : Theme.Palette.ink)
                        .contentTransition(.symbolEffect(.replace))
                        .accessibilityLabel(showFavoritesOnly ? Text("Show all widgets") : Text("Show favorites only"))
                }
                .buttonStyle(.plain)
                EditButton()
                    .font(Theme.Typography.label)
                    .tint(Theme.Palette.accent)
            }
        }
        .textCase(nil)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing here yet", systemImage: "rectangle.stack")
        } description: {
            Text("Widgets you add from Discover will collect here, ready for your home screen.")
        }
    }

    private var list: some View {
        List {
            Section {
            ForEach(visible) { widget in
                NavigationLink(value: widget.libraryDestination) {
                    LibraryRow(widget: widget)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        try? LibraryStore(context: modelContext).toggleFavorite(widget)
                    } label: {
                        Label("Favorite", systemImage: widget.isFavorite ? "heart.slash" : "heart")
                    }
                    .tint(.pink)
                }
                // The second place people want to share from: not right after
                // designing, but days later when someone asks where the widget
                // came from. A long press is the iOS convention for "more
                // things I can do with this row", so it costs no chrome.
                .contextMenu { shareItem(for: widget) }
            }
            .onDelete(perform: delete)
            .onMove(perform: move)
            } header: {
                header
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, Theme.Spacing.sm)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .kareReadableScrollMargins()
        .kareTabBarInset()
    }

    /// Share entry for a library row.
    ///
    /// Only for widgets that carry a design. The fixed live ones (Aurora,
    /// Focus, Daily) draw themselves from their own WidgetKit views against
    /// live data, so there is no `WidgetContent` to render and a share card
    /// would come out empty. Offering a menu item that produces nothing is
    /// worse than not offering it.
    @ViewBuilder
    private func shareItem(for widget: InstalledWidget) -> some View {
        if let content = widget.content,
           let rendered = ShareImage.render(content: content,
                                            size: widget.size,
                                            name: widget.name) {
            let image = Image(uiImage: rendered)
            ShareLink(item: image, preview: SharePreview(widget.name, image: image)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let store = LibraryStore(context: modelContext)
        let ids = offsets.map { visible[$0].templateID }
        var removed: [RemovalSurveyTarget] = []
        for id in ids {
            if let target = try? store.remove(templateID: id) { removed.append(target) }
        }
        // Ask about the first one only; a bulk clean-up gets one question.
        if let first = removed.first, RemovalFeedbackStore.shouldAsk {
            Task {
                // Let the row finish sliding away before the sheet comes up.
                try? await Task.sleep(for: .milliseconds(400))
                surveyTarget = first
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = widgets
        reordered.move(fromOffsets: source, toOffset: destination)
        try? LibraryStore(context: modelContext).reorder(reordered)
    }
}

private struct LibraryRow: View {
    let widget: InstalledWidget

    /// Widgets whose settings (quit date, photo, countdowns...) open from here.
    private var hasSettings: Bool { SampleCatalog.setupTemplateIDs.contains(widget.templateID) }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            thumbnail
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(widget.name)).font(Theme.Typography.cardTitle)
                if hasSettings {
                    Text("Tap to open its settings")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.accent)
                } else {
                    Text("\(widget.authorName) · \(widget.size.displayName)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }

            Spacer()

            Image(systemName: hasSettings ? "gearshape.fill"
                  : (widget.isCustomizable ? "slider.horizontal.3" : "checkmark.seal.fill"))
                .font(.caption)
                .foregroundStyle(hasSettings ? Theme.Palette.accent : Theme.Palette.subtleText)

            if widget.isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(.pink).font(.caption)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    /// The image saved at install time, or the catalogue's current one for
    /// widgets installed before their art existed. Only if it is really there.
    private var thumbnailImageName: String? {
        // Editable widgets show the user's own design, not market art.
        guard !widget.isCustomizable else { return nil }
        let name = widget.previewImageName
            ?? SampleCatalog.templates.first { $0.id == widget.templateID }?.previewImageName
        guard let name, UIImage(named: name) != nil else { return nil }
        return name
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let imageName = thumbnailImageName {
            // Fixed-design widget (Aurora, Focus, ...): show our real artwork,
            // never the text/sticker editor render.
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let content = widget.content {
            // No `referenceWidth` override. It used to be passed as 46, the
            // same as the frame, which made the scale exactly 1 and drew a
            // 30pt headline inside a 46pt thumbnail. The reference is the
            // width a design was authored against, not the box it is being
            // shown in; leaving the default makes this a true miniature.
            CustomWidgetView(content: content, size: .small)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(widget.theme?.backgroundGradient ?? LinearGradient(
                    colors: [.gray.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    Image(systemName: widget.category.symbolName)
                        .font(.caption)
                        .foregroundStyle(widget.theme?.accent ?? .white)
                )
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView().withAppRoutes()
    }
    .environment(\.appEnvironment, .preview)
    .environment(AppNavigator())
    .modelContainer(for: InstalledWidget.self, inMemory: true)
}
