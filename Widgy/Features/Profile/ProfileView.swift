//
//  ProfileView.swift
//  Widgy
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigator.self) private var navigator
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @AppStorage(OnboardingKeys.username) private var username = ""
    @State private var showEditProfile = false

    @Query(sort: \InstalledWidget.addedAt, order: .reverse)
    private var widgets: [InstalledWidget]

    private var name: String { displayName.isEmpty ? "You" : displayName }
    private var handle: String { "@" + (username.isEmpty ? "you" : username) }
    private var madeCount: Int { widgets.filter { $0.contentData != nil }.count }
    private var favoriteCount: Int { widgets.filter(\.isFavorite).count }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                header
                identity
                stats
                myWidgets
                favourites
            }
            .padding(.bottom, Theme.Spacing.lg)
        }
        .widgyTabBarInset()
        .background(Theme.Palette.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Profile")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            Button {
                showEditProfile = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.body)
                    .foregroundStyle(Theme.Palette.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: Identity

    private var identity: some View {
        Button {
            showEditProfile = true
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                ProfileAvatar(size: 100)

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
        .buttonStyle(.plain)
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
            SectionHeader(title: "My Widgets") { navigator.selectedTab = .library }
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

    // MARK: Favourites

    /// Was a pair of invented "Saved Collections" cards with made-up item
    /// counts. Replaced with something true: the widgets the user has actually
    /// favourited, which also gives the heart button on each card a purpose.
    @ViewBuilder
    private var favourites: some View {
        let favourited = widgets.filter(\.isFavorite)

        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Favourites")
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.lg)

            if favourited.isEmpty {
                Text("Tap the heart on any widget to keep it here.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .padding(.horizontal, Theme.Spacing.lg)
            } else {
                VStack(spacing: 0) {
                    ForEach(favourited) { widget in
                        NavigationLink(value: widget.libraryDestination) {
                            favouriteRow(widget)
                        }
                        .buttonStyle(.plain)

                        if widget.id != favourited.last?.id {
                            Divider().padding(.leading, 76)
                        }
                    }
                }
                .widgyCard()
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }

    private func favouriteRow(_ widget: InstalledWidget) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            badge(widget)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(widget.name)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Palette.ink)
                Text(widget.category.displayName)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.subtleText)
        }
        .padding(Theme.Spacing.md)
        .contentShape(.rect)
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
