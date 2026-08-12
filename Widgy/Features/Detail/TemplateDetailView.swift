//
//  TemplateDetailView.swift
//  Widgy
//

import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    let templateID: String

    @Environment(\.appEnvironment) private var environment
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigator.self) private var navigator

    @State private var template: WidgetTemplate?
    @State private var errorMessage: String?
    @State private var selectedSize: WidgetSize = .small
    @State private var isInstalled = false
    @State private var reviews: [Review] = []
    @State private var showReviewComposer = false
    @State private var showAddToHome = false

    /// Live WidgetKit widgets (Aurora, Focus, Daily, ...) are added from the iOS
    /// widget gallery, not "installed" like the editable one.
    private var isLive: Bool { template.map { !$0.isEditable } ?? false }

    var body: some View {
        ScrollView {
            if let template {
                detail(template)
            } else if let errorMessage {
                ErrorStateView(message: errorMessage) { Task { await load() } }
            } else {
                LoadingStateView().frame(height: 320)
            }
        }
        .background(Theme.Palette.background)
        .navigationTitle(template?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let template {
                installBar(template)
            }
        }
        .task { await load() }
        .sheet(isPresented: $showAddToHome) {
            AddToHomeGuide(galleryName: template?.galleryName ?? template?.name ?? "Kare")
                .presentationDetents([.large])
        }
    }

    private func detail(_ template: WidgetTemplate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
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

            sizePicker(template)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(template.name)
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)

                NavigationLink(value: AppRoute.author(authorID: template.author.id)) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("by")
                            .foregroundStyle(Theme.Palette.subtleText)
                        Text(template.author.displayName)
                            .foregroundStyle(Theme.Palette.ink)
                        if template.author.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Theme.Palette.accent)
                        }
                    }
                    .font(Theme.Typography.label)
                }

                Text(template.summary)
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.ink.opacity(0.85))
                    .padding(.top, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            // Widgets that need setting up inside the app get a direct way in.
            if let action = companionAction(for: template) {
                NavigationLink(value: action.route) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: action.icon)
                        Text(action.title)
                    }
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Theme.Palette.accent, in: .capsule)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Spacing.lg)
            }

            statsRow(template)
            tagCloud(template)
            reviewsSection(template)
        }
        .padding(.bottom, Theme.Spacing.xxl)
        .sheet(isPresented: $showReviewComposer) {
            ReviewComposer { stars, text in
                await submitReview(templateID: template.id, stars: stars, text: text)
            }
            .presentationDetents([.medium])
        }
    }

    /// Some widgets are configured inside the app rather than on the home
    /// screen — Focus starts a session, Frame picks a photo. Those get a
    /// prominent shortcut on their detail page.
    private func companionAction(for template: WidgetTemplate) -> (route: AppRoute, icon: String, title: String)? {
        switch template.id {
        case "t-focus": (.focus, "timer", "Open Focus")
        case "t-frame": (.frame, "photo", "Choose your photo")
        case "t-daily": (.daily, "book.closed", "Choose your source")
        default: nil
        }
    }

    // MARK: - Reviews

    private func reviewsSection(_ template: WidgetTemplate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("Ratings & Reviews")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Button {
                    showReviewComposer = true
                } label: {
                    Text("Write a review").widgyCapsLabel().foregroundStyle(Theme.Palette.accent)
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                Text(String(format: "%.1f", template.rating))
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
                VStack(alignment: .leading, spacing: 2) {
                    StarRating(value: template.rating, size: 16)
                    Text("\(template.ratingCount) ratings")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }

            if reviews.isEmpty {
                Text("No written reviews yet. Be the first.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                VStack(spacing: Theme.Spacing.md) {
                    ForEach(reviews) { review in
                        ReviewRow(review: review)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func submitReview(templateID: String, stars: Int, text: String) async {
        let review = Review(templateID: templateID, authorName: "You", stars: stars, text: text)
        do {
            try await environment.widgets.submitReview(review)
            reviews = (try? await environment.widgets.reviews(for: templateID)) ?? reviews
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sizePicker(_ template: WidgetTemplate) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(template.supportedSizes) { size in
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

    private func statsRow(_ template: WidgetTemplate) -> some View {
        HStack(spacing: 0) {
            stat(value: String(format: "%.1f", template.rating), label: "\(template.ratingCount) ratings")
            Divider().frame(height: 34)
            stat(value: template.installCountText, label: "installs")
            Divider().frame(height: 34)
            stat(value: template.category.displayName, label: "category")
        }
        .padding(.vertical, Theme.Spacing.md)
        .widgyCard()
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Palette.subtleText)
        }
        .frame(maxWidth: .infinity)
    }

    private func tagCloud(_ template: WidgetTemplate) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(template.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Palette.surface, in: .capsule)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private func installBar(_ template: WidgetTemplate) -> some View {
        Button {
            if isLive {
                // Make sure it's tracked, then show how to place it on the home screen.
                if !isInstalled { installOnly(template) }
                showAddToHome = true
            } else {
                toggleInstall(template)
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if isLive {
                    if isInstalled {
                        Image(systemName: "checkmark")
                        Text("Added · Set up on Home Screen")
                    } else {
                        Image(systemName: "plus.square.on.square")
                        Text("Add to Home Screen")
                    }
                } else {
                    Image(systemName: isInstalled ? "checkmark" : "plus")
                    Text(isInstalled ? "In library" : "Add to library")
                    Text("·").opacity(0.5)
                    Text(template.price.displayText)
                }
            }
            .font(Theme.Typography.title)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isInstalled ? Color(hex: "8C8382") : Theme.Palette.accent,
                in: .capsule
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
        .background(
            LinearGradient(
                colors: [Theme.Palette.background, Theme.Palette.background.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    private func load() async {
        do {
            let fetched = try await environment.widgets.template(id: templateID)
            template = fetched
            selectedSize = fetched.primarySize
            refreshInstallState()
            reviews = (try? await environment.widgets.reviews(for: templateID)) ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleInstall(_ template: WidgetTemplate) {
        let store = LibraryStore(context: modelContext)
        do {
            if isInstalled {
                try store.remove(templateID: template.id)
            } else {
                try store.install(template, size: selectedSize)
                // Take the user to their Widgets tab, where they can open the editor.
                navigator.selectedTab = .library
            }
            refreshInstallState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func installOnly(_ template: WidgetTemplate) {
        do {
            try LibraryStore(context: modelContext).install(template, size: selectedSize)
            refreshInstallState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshInstallState() {
        isInstalled = LibraryStore(context: modelContext).isInstalled(templateID: templateID)
    }
}

// MARK: - Review row

private struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(review.authorName)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Text(review.createdAt, format: .relative(presentation: .named, unitsStyle: .wide))
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            StarRating(value: Double(review.stars), size: 12)
            Text(review.text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.ink.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .widgyCard()
    }
}

// MARK: - Review composer

private struct ReviewComposer: View {
    let onSubmit: (Int, String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stars = 5
    @State private var text = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Your rating").widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
                    StarPicker(value: $stars)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Your review").widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
                    TextField("What did you think?", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
                }

                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Palette.background)
            .navigationTitle("Write a review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Post") {
                        isSubmitting = true
                        Task {
                            await onSubmit(stars, text.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .tint(Theme.Palette.accent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(templateID: "t-aurora").withAppRoutes()
    }
    .environment(\.appEnvironment, .preview)
    .environment(AppNavigator())
    .modelContainer(for: InstalledWidget.self, inMemory: true)
}
