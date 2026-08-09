//
//  LibraryView.swift
//  Widgy
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \InstalledWidget.sortIndex)
    private var widgets: [InstalledWidget]

    @State private var showFavoritesOnly = false

    private var visible: [InstalledWidget] {
        showFavoritesOnly ? widgets.filter(\.isFavorite) : widgets
    }

    var body: some View {
        Group {
            if widgets.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Library")
        .toolbar {
            if !widgets.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showFavoritesOnly.toggle() }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                    }
                }
                ToolbarItem(placement: .topBarLeading) { EditButton() }
            }
        }
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
            }
            .onDelete(perform: delete)
            .onMove(perform: move)
        }
        .listStyle(.insetGrouped)
    }

    private func delete(at offsets: IndexSet) {
        let store = LibraryStore(context: modelContext)
        for index in offsets {
            try? store.remove(templateID: visible[index].templateID)
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

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            thumbnail
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(widget.name).font(Theme.Typography.cardTitle)
                Text("\(widget.authorName) · \(widget.size.displayName)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            Spacer()

            Image(systemName: widget.isCustomizable ? "slider.horizontal.3" : "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(Theme.Palette.subtleText)

            if widget.isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(.pink).font(.caption)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let imageName = widget.previewImageName {
            // Fixed-design widget (Aurora, Focus, ...): show our real artwork,
            // never the text/sticker editor render.
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let content = widget.content {
            CustomWidgetView(content: content, size: .small, referenceWidth: 46)
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
