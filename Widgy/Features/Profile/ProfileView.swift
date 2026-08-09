//
//  ProfileView.swift
//  Widgy
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @AppStorage(OnboardingKeys.username) private var username = ""

    @Query(sort: \InstalledWidget.addedAt, order: .reverse)
    private var widgets: [InstalledWidget]

    private var name: String { displayName.isEmpty ? "You" : displayName }
    private var handle: String { "@" + (username.isEmpty ? "you" : username) }
    private var madeCount: Int { widgets.filter { $0.contentData != nil }.count }
    private var favoriteCount: Int { widgets.filter(\.isFavorite).count }

    private let collections: [(title: String, meta: String, hexes: [String])] = [
        ("Minimalist", "24 ITEMS · CURATED BY YOU", ["3A3A3C", "6E6E73"]),
        ("Productivity", "18 ITEMS · PRIVATE", ["2C2C2E", "8C8382"])
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                header
                identity
                stats
                myWidgets
                savedCollections
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .background(Theme.Palette.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Profile")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            Image(systemName: "bag")
                .font(.body)
                .foregroundStyle(Theme.Palette.ink)
            Circle()
                .fill(Theme.Palette.surfaceMuted)
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "person.fill").font(.footnote).foregroundStyle(Theme.Palette.subtleText))
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: Identity

    private var identity: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Theme.Palette.surfaceMuted)
                    .frame(width: 100, height: 100)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(Theme.Palette.subtleText))
                    .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 4))
                    .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)

                Circle()
                    .fill(Theme.Palette.accent)
                    .frame(width: 30, height: 30)
                    .overlay(Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(.white))
                    .overlay(Circle().stroke(Theme.Palette.background, lineWidth: 3))
            }

            VStack(spacing: 2) {
                Text(name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text(handle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
    }

    // MARK: Stats

    private var stats: some View {
        HStack(spacing: 0) {
            stat(value: "\(widgets.count)", label: "Widgets")
            divider
            stat(value: "\(madeCount)", label: "Made")
            divider
            stat(value: "\(favoriteCount)", label: "Favorites")
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .overlay(alignment: .top) { Rectangle().fill(Theme.Palette.hairline).frame(height: 0.5) }
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Palette.hairline).frame(height: 0.5) }
        .padding(.vertical, Theme.Spacing.lg)
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var divider: some View {
        Rectangle().fill(Theme.Palette.hairline).frame(width: 0.5, height: 30)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(Theme.Palette.subtleText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: My Widgets

    private var myWidgets: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "My Widgets", seeAllAction: {})
                .padding(.horizontal, Theme.Spacing.lg)

            if widgets.isEmpty {
                Text("Add a widget from Discover, then customise it here.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .padding(.horizontal, Theme.Spacing.lg)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.md),
                                    GridItem(.flexible(), spacing: Theme.Spacing.md)],
                          spacing: Theme.Spacing.md) {
                    ForEach(widgets) { widget in
                        NavigationLink(value: widget.libraryDestination) {
                            widgetCard(widget)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }

    private func widgetCard(_ widget: InstalledWidget) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                badge(widget)
                Spacer()
                Button {
                    try? LibraryStore(context: modelContext).toggleFavorite(widget)
                } label: {
                    Image(systemName: widget.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(widget.isFavorite ? Theme.Palette.accent : Theme.Palette.subtleText)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: Theme.Spacing.lg)

            Text(widget.name)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
            Text(widget.category.displayName)
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.subtleText)
                .lineLimit(1)
        }
        .padding(Theme.Spacing.lg)
        .frame(height: 132, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgyCard()
    }

    /// Real artwork for fixed-design widgets (Aurora, Focus, ...); a category
    /// glyph for anything without a store image (e.g. a customizable widget).
    @ViewBuilder
    private func badge(_ widget: InstalledWidget) -> some View {
        if let imageName = widget.previewImageName {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: widget.category.symbolName)
                .font(.footnote)
                .foregroundStyle(Theme.Palette.ink)
                .frame(width: 32, height: 32)
                .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: 8))
        }
    }

    // MARK: Saved Collections

    private var savedCollections: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Saved Collections")
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.md) {
                ForEach(collections, id: \.title) { collection in
                    collectionCard(collection)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    private func collectionCard(_ collection: (title: String, meta: String, hexes: [String])) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: collection.hexes.map(Color.init(hex:)),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            LinearGradient(colors: [.black.opacity(0.55), .clear],
                           startPoint: .bottom, endPoint: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.title)
                    .font(Theme.Typography.headlineSmall)
                    .foregroundStyle(.white)
                Text(collection.meta)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(height: 120)
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ProfileView().withAppRoutes()
    }
    .environment(\.appEnvironment, .preview)
    .environment(AppNavigator())
    .modelContainer(for: InstalledWidget.self, inMemory: true)
}
