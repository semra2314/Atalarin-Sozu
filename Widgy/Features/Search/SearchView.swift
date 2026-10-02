//
//  SearchView.swift
//  Kare
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: SearchViewModel?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Theme.Spacing.lg)]

    @FocusState private var searchFocused: Bool

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("Search").kareScreenTitle()
                searchField
                filterRow

                if let viewModel {
                    if viewModel.isSearching && viewModel.results.isEmpty {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, Theme.Spacing.xxl)
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorStateView(message: errorMessage) {
                            Task { await viewModel.performSearch() }
                        }
                    } else if viewModel.results.isEmpty {
                        ContentUnavailableView.search(text: viewModel.query)
                            .padding(.top, Theme.Spacing.xxl)
                    } else {
                        grid(viewModel.results)
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .kareReadableScrollMargins(Theme.Layout.wideWidth)
        .kareTabBarInset()
        .background(Theme.Palette.background)
        .navigationTitle("Search")
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel?.query) { _, _ in
            viewModel?.scheduleSearch()
        }
        .task {
            if viewModel == nil {
                viewModel = SearchViewModel(repository: environment.widgets)
                await viewModel?.performSearch()
            }
        }
    }

    /// A field in the content rather than `.searchable`.
    ///
    /// The system search bar lives inside the navigation bar, where it collapses
    /// under a large title until you pull down — on this screen it simply wasn't
    /// there as far as anyone could tell. A search screen should show its search
    /// box without being asked.
    private var searchField: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Palette.subtleText)

            TextField(
                "Widgets, creators, tags",
                text: Binding(
                    get: { viewModel?.query ?? "" },
                    set: { viewModel?.query = $0 }
                )
            )
            .textFieldStyle(.plain)
            .font(Theme.Typography.bodyLarge)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .focused($searchFocused)
            .onSubmit { Task { await viewModel?.performSearch() } }

            if !(viewModel?.query ?? "").isEmpty {
                Button {
                    viewModel?.query = ""
                    viewModel?.scheduleSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .accessibilityLabel(Text("Clear search"))
                        .foregroundStyle(Theme.Palette.subtleText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: 48)
        .background(Theme.Palette.surface, in: .capsule)
        .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: 1))
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var filterRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(WidgetCategory.allCases) { category in
                    CategoryChip(
                        title: category.displayName,
                        symbolName: category.symbolName,
                        isSelected: viewModel?.selectedCategory == category
                    ) {
                        viewModel?.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private func grid(_ templates: [WidgetTemplate]) -> some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.xl) {
            ForEach(templates) { template in
                NavigationLink(value: AppRoute.templateDetail(templateID: template.id, source: "search-\(template.id)")) {
                    WidgetCard(template: template, size: .small, width: 150)
                        .zoomSource("search-\(template.id)")
                }
                .buttonStyle(.karePress)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        SearchView().withAppRoutes()
    }
    .environment(\.appEnvironment, .preview)
    .modelContainer(for: InstalledWidget.self, inMemory: true)
}
