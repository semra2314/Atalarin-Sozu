//
//  DiscoverView.swift
//  Kare
//

import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: DiscoverViewModel?
    @AppStorage(OnboardingKeys.seenDiscoverTip) private var seenTip = false

    var body: some View {
        Group {
            switch viewModel?.state ?? .idle {
            case .idle, .loading:
                LoadingStateView()
            case let .failed(message):
                ErrorStateView(message: message) {
                    Task { await viewModel?.load() }
                }
            case let .loaded(sections):
                content(sections)
            }
        }
        .navigationTitle("Discover")
        .background(Theme.Palette.background)
        .task {
            if viewModel == nil {
                viewModel = DiscoverViewModel(repository: environment.widgets)
            }
            await viewModel?.loadIfNeeded()
        }
        .refreshable { await viewModel?.load() }
    }

    private func content(_ sections: [CatalogSection]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                if !seenTip {
                    tipBanner.padding(.horizontal, Theme.Spacing.lg)
                }

                if let hero = sections.first?.templates.first {
                    NavigationLink(value: AppRoute.templateDetail(templateID: hero.id, source: "hero")) {
                        WidgetOfTheDayHero(template: hero)
                            .zoomSource("hero")
                    }
                    .buttonStyle(.karePress)
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                categoryRow(stockedCategories(in: sections))

                ForEach(sections) { section in
                    sectionView(section)
                }
            }
            .padding(.top, Theme.Spacing.lg)
            // Breathing room only — the tab bar's height is reserved by
            // `.kareTabBarInset()` below.
            .padding(.bottom, Theme.Spacing.lg)
        }
        .kareTabBarInset()
    }

    private var tipBanner: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(Theme.Palette.accent)
            Text("Tap any widget to make it yours.")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            Button {
                withAnimation { seenTip = true }
            } label: {
                Image(systemName: "xmark")
                    .accessibilityLabel(Text("Dismiss"))
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Palette.accentTint, in: .rect(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    /// Categories that actually have something in them, in the fixed order of
    /// `allCases` so the row does not reshuffle between loads.
    ///
    /// Showing all eight meant Weather and Finance were always there and
    /// always led to an empty shelf. Those two need live data we do not have
    /// yet, and a chip that reliably disappoints is worse than no chip. This
    /// reads the loaded catalogue rather than a hard-coded list, so a category
    /// reappears by itself the day something lands in it.
    private func stockedCategories(in sections: [CatalogSection]) -> [WidgetCategory] {
        let stocked = Set(sections.flatMap(\.templates).map(\.category))
        return WidgetCategory.allCases.filter(stocked.contains)
    }

    private func categoryRow(_ categories: [WidgetCategory]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(categories) { category in
                    NavigationLink(value: AppRoute.category(category)) {
                        CategoryChip(
                            title: category.displayName,
                            symbolName: category.symbolName
                        ) {}
                        .allowsHitTesting(false)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func sectionView(_ section: CatalogSection) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: section.title, subtitle: section.subtitle)
                .padding(.horizontal, Theme.Spacing.lg)

            switch section.style {
            case .spotlight:
                spotlight(section.templates)
            case .carousel:
                carousel(section.templates, section: section.id)
            case .compactList:
                compactList(section.templates)
            }
        }
    }

    private func spotlight(_ templates: [WidgetTemplate]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(templates) { template in
                    let source = "spotlight-\(template.id)"
                    NavigationLink(value: AppRoute.templateDetail(templateID: template.id, source: source)) {
                        WidgetCard(template: template, size: .medium, width: 300)
                            .zoomSource(source)
                    }
                    .buttonStyle(.karePress)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
    }

    private func carousel(_ templates: [WidgetTemplate], section: String) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(templates) { template in
                    let source = "\(section)-\(template.id)"
                    NavigationLink(value: AppRoute.templateDetail(templateID: template.id, source: source)) {
                        WidgetCard(template: template, size: .small, width: 150)
                            .zoomSource(source)
                    }
                    .buttonStyle(.karePress)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private func compactList(_ templates: [WidgetTemplate]) -> some View {
        VStack(spacing: 0) {
            ForEach(templates) { template in
                NavigationLink(value: AppRoute.templateDetail(templateID: template.id)) {
                    TemplateRow(template: template)
                }
                .buttonStyle(.plain)

                if template.id != templates.last?.id {
                    Divider().padding(.leading, 76)
                }
            }
        }
        .kareCard()
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

// MARK: - Widget of the Day hero

private struct WidgetOfTheDayHero: View {
    let template: WidgetTemplate

    /// Taller on iPad, where the card is twice as wide and 320pt would turn
    /// the photo into a letterbox.
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var height: CGFloat { sizeClass == .regular ? 440 : 320 }

    var body: some View {
        // The photo fills a fixed frame instead of sizing the card itself.
        // A wide photo used to make the card wider than the screen, which
        // pushed the title out of the visible part.
        Color.clear
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay {
                if let imageName = template.previewImageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    template.theme.backgroundGradient
                }
            }
            .overlay {
                LinearGradient(colors: [.black.opacity(0.55), .clear],
                               startPoint: .bottom, endPoint: .center)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Widget of the Day")
                        .font(.system(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, 6)
                        .background(Theme.Palette.accent, in: .capsule)

                    Text(LocalizedStringKey(template.name))
                        .font(Theme.Typography.displayLarge)
                        .foregroundStyle(.white)

                    Text("by \(template.author.displayName)")
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(Theme.Spacing.xl)
            }
            .clipShape(.rect(cornerRadius: Theme.Radius.hero, style: .continuous))
            .contentShape(.rect(cornerRadius: Theme.Radius.hero, style: .continuous))
            .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
    }
}

#Preview {
    NavigationStack {
        DiscoverView().withAppRoutes()
    }
    .environment(\.appEnvironment, .preview)
    .environment(AppNavigator())
    .modelContainer(for: InstalledWidget.self, inMemory: true)
}
