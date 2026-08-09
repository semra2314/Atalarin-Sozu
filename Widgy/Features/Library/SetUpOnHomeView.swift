//
//  SetUpOnHomeView.swift
//  Widgy
//
//  Where a fixed-design widget (Aurora, ...) goes when tapped from the library.
//
//  iOS does not let an app place a widget on the home screen itself — that can
//  only happen through the system widget gallery. So instead of pretending, this
//  screen does the next best thing: shows exactly what the widget looks like at
//  each size, and names the exact gallery entry to look for.
//

import SwiftUI
import SwiftData

struct SetUpOnHomeView: View {
    let templateID: String

    @Environment(\.appEnvironment) private var environment

    @State private var template: WidgetTemplate?
    @State private var selectedSize: WidgetSize = .small
    @State private var errorMessage: String?

    /// Every size the widget supports, home screen and lock screen alike.
    /// They're placed through different flows, which the steps below explain.
    private var sizes: [WidgetSize] {
        template?.supportedSizes ?? [.small, .medium, .large]
    }

    private var isLockScreenSize: Bool { selectedSize.isLockScreen }

    private var galleryName: String { template?.galleryName ?? template?.name ?? "Widgy" }

    var body: some View {
        ScrollView {
            if let template {
                content(template)
            } else if let errorMessage {
                ErrorStateView(message: errorMessage) { Task { await load() } }
            } else {
                LoadingStateView().frame(height: 320)
            }
        }
        .background(Theme.Palette.background)
        .navigationTitle(template?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func content(_ template: WidgetTemplate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            preview(template)
            sizePicker
            steps
        }
        .padding(.bottom, Theme.Spacing.xxl)
    }

    // MARK: - Preview

    private func preview(_ template: WidgetTemplate) -> some View {
        WidgetPreview(template: template, size: selectedSize, preferSizeImage: true)
            .frame(maxWidth: 340)
            .frame(maxWidth: .infinity)
            .padding(.top, Theme.Spacing.xl)
            .background(alignment: .center) {
                Circle()
                    .fill(Theme.Palette.accent.opacity(0.15))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
            }
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Sizes")
                .widgyCapsLabel()
                .foregroundStyle(Theme.Palette.subtleText)
                .padding(.horizontal, Theme.Spacing.lg)

            ScrollView(.horizontal) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(sizes) { size in
                        CategoryChip(
                            title: size.displayName,
                            isSelected: selectedSize == size
                        ) {
                            withAnimation(.snappy) { selectedSize = size }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - How to place it

    private var steps: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(isLockScreenSize ? "Add it to your lock screen" : "Add it to your home screen")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text("iOS only lets widgets be placed from its own gallery, so here's the shortcut.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            // Lock screen widgets are added through the wallpaper editor, not
            // the home-screen gallery — a genuinely different flow.
            VStack(spacing: Theme.Spacing.md) {
                if isLockScreenSize {
                    step(1, icon: "lock.fill", title: "Touch and hold the lock screen",
                         detail: "Wake your phone, then press and hold until Customise appears.")
                    step(2, icon: "paintbrush.fill", title: "Tap Customise, then Lock Screen",
                         detail: "Tap the widget area under the clock to open the picker.")
                    step(3, icon: "magnifyingglass", title: "Find “\(galleryName)”",
                         detail: "Scroll to \(galleryName) and tap the \(selectedSize.displayName) widget to place it.")
                } else {
                    step(1, icon: "hand.tap.fill", title: "Touch and hold",
                         detail: "Press an empty spot on your home screen until the icons jiggle.")
                    step(2, icon: "plus.circle.fill", title: "Tap +, then search",
                         detail: "Hit the plus in the top corner and search for “\(galleryName)”.")
                    step(3, icon: "square.grid.2x2.fill", title: "Pick \(selectedSize.displayName)",
                         detail: "Swipe to the size you want, then tap Add Widget.")
                }
            }

            calloutIfNeeded
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    /// The most common point of confusion: “Widgy” in the gallery is the
    /// build-your-own widget, not this one.
    @ViewBuilder
    private var calloutIfNeeded: some View {
        if galleryName != "Widgy" {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Theme.Palette.accent)
                Text("In the gallery, pick **\(galleryName)** — not “Widgy”. “Widgy” is the make-your-own widget.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Palette.accentTint, in: .rect(cornerRadius: Theme.Radius.card, style: .continuous))
        }
    }

    private func step(_ number: Int, icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.Palette.accent)
                .frame(width: 44, height: 44)
                .background(Theme.Palette.accentTint, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(number). \(title)")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                Text(detail)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            Spacer(minLength: 0)
        }
    }

    private func load() async {
        do {
            let fetched = try await environment.widgets.template(id: templateID)
            template = fetched
            selectedSize = fetched.supportedSizes.first { !$0.isLockScreen } ?? .small
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SetUpOnHomeView(templateID: "t-aurora").withAppRoutes()
    }
    .environment(\.appEnvironment, .preview)
    .environment(AppNavigator())
    .modelContainer(for: InstalledWidget.self, inMemory: true)
}
