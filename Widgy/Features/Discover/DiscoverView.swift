//
//  DiscoverView.swift
//  Widgy
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
                    NavigationLink(value: AppRoute.templateDetail(templateID: hero.id)) {
                        WidgetOfTheDayHero(template: hero)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                categoryRow

                ForEach(sections) { section in
                    sectionView(section)
                }
            }
            .padding(.top, Theme.Spacing.lg)
            // Breathing room under the last section so it clears the tab bar
            // rather than ending flush against it.
            .padding(.bottom, Theme.Spacing.xxl)
        }
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
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Palette.accentTint, in: .rect(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private var categoryRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(WidgetCategory.allCases) { category in
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
                carousel(section.templates)
            case .compactList:
                compactList(section.templates)
            }
        }
    }

    private func spotlight(_ templates: [WidgetTemplate]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(templates) { template in
                    NavigationLink(value: AppRoute.templateDetail(templateID: template.id)) {
                        WidgetCard(template: template, size: .medium, width: 300)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
    }

    private func carousel(_ templates: [WidgetTemplate]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(templates) { template in
                    NavigationLink(value: AppRoute.templateDetail(templateID: template.id)) {
                        WidgetCard(template: template, size: .small, width: 150)
                    }
                    .buttonStyle(.plain)
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
        .widgyCard()
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

// MARK: - Widget of the Day hero

private struct WidgetOfTheDayHero: View {
    let template: WidgetTemplate

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageName = template.previewImageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                template.theme.backgroundGradient
            }

            LinearGradient(colors: [.black.opacity(0.55), .clear],
                           startPoint: .bottom, endPoint: .center)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Widget of the Day")
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 6)
                    .background(Theme.Palette.accent, in: .capsule)

                Text(template.name)
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(.white)

                Text("by \(template.author.displayName)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(Theme.Spacing.xl)
        }
        .frame(height: 320)
        .clipShape(.rect(cornerRadius: Theme.Radius.hero, style: .continuous))
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
