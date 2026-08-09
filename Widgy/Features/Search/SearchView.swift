//
//  SearchView.swift
//  Widgy
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.appEnvironment) private var environment
    @State private var viewModel: SearchViewModel?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Theme.Spacing.lg)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
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
        .background(Theme.Palette.background)
        .navigationTitle("Search")
        .searchable(
            text: Binding(
                get: { viewModel?.query ?? "" },
                set: { viewModel?.query = $0 }
            ),
            prompt: "Widgets, creators, tags"
        )
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
                NavigationLink(value: AppRoute.templateDetail(templateID: template.id)) {
                    WidgetCard(template: template, size: .small, width: 150)
                }
                .buttonStyle(.plain)
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
