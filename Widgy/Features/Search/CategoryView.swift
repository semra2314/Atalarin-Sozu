//
//  CategoryView.swift
//  Widgy
//

import SwiftUI

struct CategoryView: View {
    let category: WidgetCategory

    @Environment(\.appEnvironment) private var environment
    @State private var templates: [WidgetTemplate] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Theme.Spacing.lg)]

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding(.top, Theme.Spacing.xxl)
            } else if let errorMessage {
                ErrorStateView(message: errorMessage) { Task { await load() } }
            } else {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.xl) {
                    ForEach(templates) { template in
                        NavigationLink(value: AppRoute.templateDetail(templateID: template.id)) {
                            WidgetCard(template: template, size: .small, width: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .background(Theme.Palette.background)
        .navigationTitle(LocalizedStringKey(category.displayName))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            templates = try await environment.widgets.templates(in: category)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
