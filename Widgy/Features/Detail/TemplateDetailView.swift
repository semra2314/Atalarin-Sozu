//
//  TemplateDetailView.swift
//  Kare
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
    @State private var reviewsLoading = true
    @State private var reviewsFailed = false
    @State private var reviewAlert: String?
    @State private var reportTarget: Review?
    @State private var showReviewComposer = false
    @State private var showAddToHome = false
    @State private var showKarePlus = false
    @State private var showUnlock = false
    @State private var showSignInRequired = false
    /// The spinner-then-tick shown while a widget is being added.
    @State private var addPhase: AddPhase?
    @State private var surveyTarget: RemovalSurveyTarget?
    @Environment(\.subscriptions) private var subscriptions
    @AppStorage(OnboardingKeys.hasAccount) private var hasAccount = false
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""

    /// Live WidgetKit widgets (Aurora, Focus, Daily, ...) are added from the iOS
    /// widget gallery, not "installed" like the editable one.
    private var isLive: Bool { template.map { !$0.isEditable } ?? false }

    /// Live widgets with settings of their own (a quit date, a photo, a list
    /// of countdowns). The market page never shows those settings: the
    /// widget goes to the library, and its settings live there.
    private var needsSetup: Bool {
        template.map { SampleCatalog.setupTemplateIDs.contains($0.id) } ?? false
    }

    /// A paid widget the user has not unlocked.
    ///
    /// This is the whole point of Kare+ existing. Until there were paid
    /// presets in the catalogue the subscription screen promised "every paid
    /// widget" and unlocked nothing at all, which is a promise the product
    /// could not keep.
    private var isLocked: Bool {
        guard let template else { return false }
        return !subscriptions.isUnlocked(template)
    }

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
        .navigationTitle(Text(LocalizedStringKey(template?.name ?? "")))
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
        .sheet(isPresented: $showKarePlus) { KarePlusView() }
        .sheet(isPresented: $showUnlock) {
            if let template {
                WidgetUnlockSheet(template: template) {
                    // Let this sheet finish going away before the next one.
                    Task {
                        try? await Task.sleep(for: .milliseconds(350))
                        showKarePlus = true
                    }
                }
            }
        }
        .sheet(isPresented: $showSignInRequired) {
            SignInRequiredSheet(action: .writeReview)
                .presentationDetents([.medium])
        }
        .addedCelebration($addPhase)
        .removalSurvey($surveyTarget)
    }

    private func detail(_ template: WidgetTemplate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            WidgetPreview(template: template, size: selectedSize, preferSizeImage: true)
                .frame(maxWidth: 340)
                // The design stays fully visible while locked. Blurring it
                // would hide the only reason anyone would pay.
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.45), in: .circle)
                            .padding(Theme.Spacing.sm)
                    }
                }
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
                Text(LocalizedStringKey(template.name))
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

                Text(LocalizedStringKey(template.summary))
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.ink.opacity(0.85))
                    .padding(.top, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.lg)

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

    // MARK: - Reviews

    private func reviewsSection(_ template: WidgetTemplate) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("Ratings & Reviews")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Button {
                    // A rating and a review both carry a name, so both are
                    // behind the same door. The composer holds the stars too,
                    // which is why one gate covers rating as well.
                    if hasAccount {
                        showReviewComposer = true
                    } else {
                        showSignInRequired = true
                    }
                } label: {
                    Text("Write a review").kareCapsLabel().foregroundStyle(Theme.Palette.accent)
                }
            }

            // The average and the rating count used to be shown here, from
            // numbers invented in the sample catalogue. With no users there is
            // no average, and a made-up 4.8 is worse than an honest blank: it
            // is the first thing anyone would think to check.
            //
            // Real reviews, written in the app, do appear. Once there are
            // enough of them an average computed from this list belongs here.
            if !reviews.isEmpty {
                let average = Double(reviews.map(\.stars).reduce(0, +)) / Double(reviews.count)
                HStack(spacing: Theme.Spacing.md) {
                    Text(String(format: "%.1f", average))
                        .font(Theme.Typography.displayLarge)
                        .foregroundStyle(Theme.Palette.ink)
                    VStack(alignment: .leading, spacing: 2) {
                        StarRating(value: average, size: 16)
                        Text("\(reviews.count) ratings")
                            .font(Theme.Typography.label)
                            .foregroundStyle(Theme.Palette.subtleText)
                    }
                }
            }

            if reviewsLoading && reviews.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
            } else if reviewsFailed && reviews.isEmpty {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Couldn't load reviews.")
                        .foregroundStyle(Theme.Palette.subtleText)
                    Button("Try again") { Task { await loadReviews() } }
                        .foregroundStyle(Theme.Palette.accent)
                }
                .font(Theme.Typography.body)
                .padding(.vertical, Theme.Spacing.sm)
            } else if reviews.isEmpty {
                Text("No written reviews yet. Be the first.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                VStack(spacing: Theme.Spacing.md) {
                    ForEach(reviews) { review in
                        ReviewRow(review: review,
                                  isMine: ReviewService.isMine(review),
                                  onReport: { reportTarget = review },
                                  onBlock: { block(review) },
                                  onDelete: { Task { await deleteMyReview(review) } })
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .confirmationDialog("Report this review", isPresented: Binding(
            get: { reportTarget != nil }, set: { if !$0 { reportTarget = nil } }
        ), titleVisibility: .visible, presenting: reportTarget) { review in
            ForEach(ReviewService.ReportReason.allCases) { reason in
                Button(reason.title) { Task { await report(review, reason: reason) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("We look at every report within 24 hours and remove reviews that break the rules.")
        }
        .alert(reviewAlert ?? "", isPresented: Binding(
            get: { reviewAlert != nil }, set: { if !$0 { reviewAlert = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
    }

    private func loadReviews() async {
        reviewsLoading = true
        reviewsFailed = false
        do {
            reviews = try await environment.widgets.reviews(for: templateID)
        } catch {
            reviewsFailed = true
        }
        reviewsLoading = false
    }

    private func report(_ review: Review, reason: ReviewService.ReportReason) async {
        await ReviewService.report(review, reason: reason)
        withAnimation { reviews.removeAll { $0.id == review.id } }
        reviewAlert = String(localized: "Thanks for telling us. That review is hidden for you, and we'll take a look.")
    }

    private func block(_ review: Review) {
        guard let uid = review.authorID else { return }
        ReviewService.block(uid: uid)
        withAnimation { reviews.removeAll { $0.authorID == uid } }
        reviewAlert = String(localized: "You won't see reviews from this person anymore.")
    }

    private func deleteMyReview(_ review: Review) async {
        do {
            try await ReviewService.deleteMine(templateID: review.templateID)
            withAnimation { reviews.removeAll { $0.id == review.id } }
        } catch {
            reviewAlert = error.localizedDescription
        }
    }

    private func submitReview(templateID: String, stars: Int, text: String) async {
        // Signed with the name on the account, not a placeholder. This is the
        // whole reason the gate exists: a review that says "You" identifies
        // nobody and is worth nothing to the next reader.
        let name = displayName.isEmpty ? "You" : displayName
        let review = Review(templateID: templateID, authorName: name,
                            authorID: AuthService.currentUID, stars: stars, text: text)
        do {
            try await environment.widgets.submitReview(review)
            await loadReviews()
        } catch {
            reviewAlert = error.localizedDescription
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

    /// Three facts about the widget, every one of them read off the template
    /// rather than invented. The row used to show a rating average and an
    /// install count, both hard-coded in the sample catalogue; with no users
    /// behind them they were the weakest thing on the screen.
    private func statsRow(_ template: WidgetTemplate) -> some View {
        let lockSizes: Set<WidgetSize> = [.accessoryCircular, .accessoryRectangular]
        let homeSizes = template.supportedSizes.filter { !lockSizes.contains($0) }
        let hasLockScreen = template.supportedSizes.contains { lockSizes.contains($0) }

        return HStack(spacing: 0) {
            stat(value: "\(homeSizes.count)", label: "sizes")
            Divider().frame(height: 34)
            stat(value: hasLockScreen ? String(localized: "Yes") : String(localized: "No"),
                 label: "lock screen")
            Divider().frame(height: 34)
            stat(value: template.category.displayName, label: "category")
        }
        .padding(.vertical, Theme.Spacing.md)
        .kareCard()
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(LocalizedStringKey(value)).font(.headline)
            Text(LocalizedStringKey(label))
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

    /// The bar at the bottom of the detail page.
    ///
    /// Once a widget is in the library there are exactly two things left to
    /// want, and the old bar offered neither. It showed a wide grey "Added"
    /// that mostly reported a fact, and the only way back out of the library
    /// was to leave and find the widget somewhere else. So installed widgets
    /// now get two buttons of equal width: leave, or learn how to place it.
    ///
    /// Equal width is deliberate. Making one narrower would rank them, and
    /// which of the two matters depends entirely on why the user came back.
    @ViewBuilder
    private func installBar(_ template: WidgetTemplate) -> some View {
        Group {
            if isLocked {
                barButton(icon: "lock.fill", prominent: true) {
                    showUnlock = true
                } label: {
                    Text("Unlock")
                    Text(verbatim: "·").opacity(0.5)
                    Text(verbatim: subscriptions.displayPrice(for: template))
                }
            } else if isInstalled {
                HStack(spacing: Theme.Spacing.sm) {
                    barButton(icon: "minus.circle", prominent: false) {
                        remove(template)
                    } label: {
                        Text("Remove")
                    }

                    if needsSetup {
                        barButton(icon: "slider.horizontal.3", prominent: true) {
                            openInLibrary(template)
                        } label: {
                            Text("Set up in Library")
                        }
                    } else {
                        barButton(icon: "plus.square.on.square", prominent: true) {
                            showAddToHome = true
                        } label: {
                            Text("Add to Home Screen")
                        }
                    }
                }
            } else if isLive && needsSetup {
                // Settings live in the library, so adding one takes you there.
                barButton(icon: "plus", prominent: true) {
                    addToLibrary(template)
                } label: {
                    Text("Add to library")
                }
            } else if isLive {
                barButton(icon: "plus.square.on.square", prominent: true) {
                    // Track it first, celebrate, then show how to place it.
                    installOnly(template)
                    runAddCelebration($addPhase) { showAddToHome = true }
                } label: {
                    Text("Add to Home Screen")
                }
            } else {
                barButton(icon: "plus", prominent: true) {
                    addToLibrary(template)
                } label: {
                    Text("Add to library")
                    Text("·").opacity(0.5)
                    priceLabel(for: template)
                }
            }
        }
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

    /// What the button says this costs.
    ///
    /// Three different truths, and saying the wrong one is worse than saying
    /// nothing. "Included in Kare+" is right for a member, but during the beta
    /// there is no Kare+ to be included in, and quoting the sticker price on a
    /// widget we are about to hand over free is just confusing. It says plain
    /// "Free", not "free during beta": the word beta in a release build is an
    /// App Review rejection (guideline 2.2).
    @ViewBuilder
    private func priceLabel(for template: WidgetTemplate) -> some View {
        if template.price.isFree {
            Text(LocalizedStringKey(template.price.displayText))
        } else if subscriptions.isSubscribed {
            Text("Included in Kare+")
        } else if subscriptions.ownsSingly(templateID: template.id) {
            Text("Purchased")
        } else {
            Text("Free")
        }
    }

    /// One button in the bottom bar.
    ///
    /// `maxWidth: .infinity` on every one of them is what makes a pair split
    /// the row evenly, and a lone button fill it. The height is fixed rather
    /// than left to the label so the two never disagree by a point when one
    /// wraps and the other does not.
    private func barButton<Label: View>(
        icon: String,
        prominent: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                label()
            }
            .font(Theme.Typography.title)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(prominent ? Color.white : Theme.Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                if prominent {
                    Capsule().fill(Theme.Palette.accent)
                } else {
                    Capsule()
                        .fill(Theme.Palette.surface)
                        .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Take it back out of the library.
    ///
    /// Separate from `addToLibrary` because that one also navigates to the
    /// Widgets tab, which would be a strange thing to do to someone who just
    /// asked to remove something.
    private func remove(_ template: WidgetTemplate) {
        do {
            let removed = try LibraryStore(context: modelContext).remove(templateID: template.id)
            refreshInstallState()
            if let removed, RemovalFeedbackStore.shouldAsk { surveyTarget = removed }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load() async {
        do {
            let fetched = try await environment.widgets.template(id: templateID)
            template = fetched
            selectedSize = fetched.primarySize
            refreshInstallState()
            await loadReviews()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Add an editable widget and take the user to it.
    ///
    /// This used to be `toggleInstall` and also handled removal, but removal
    /// now has its own button and its own function. Keeping the toggle would
    /// have left a branch nothing could reach, which is the kind of code that
    /// reads as an option the UI no longer offers.
    private func addToLibrary(_ template: WidgetTemplate) {
        do {
            let widget = try LibraryStore(context: modelContext).install(template, size: selectedSize)
            let destination = widget.libraryDestination
            // The tick first, then straight into the widget in the Library:
            // its editor or its settings, not the list it was added to.
            runAddCelebration($addPhase) {
                refreshInstallState()
                navigator.openInLibrary(destination)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Open an already-added widget in the Library. `install` returns the
    /// existing row when there is one, so this never adds a duplicate.
    private func openInLibrary(_ template: WidgetTemplate) {
        do {
            let widget = try LibraryStore(context: modelContext).install(template, size: selectedSize)
            navigator.openInLibrary(widget.libraryDestination)
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
    var isMine = false
    var onReport: () -> Void = {}
    var onBlock: () -> Void = {}
    var onDelete: () -> Void = {}

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
                Menu {
                    if isMine {
                        Button("Delete my review", systemImage: "trash", role: .destructive, action: onDelete)
                    } else {
                        Button("Report review", systemImage: "flag", action: onReport)
                        if review.authorID != nil {
                            Button("Block this person", systemImage: "hand.raised", role: .destructive, action: onBlock)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Palette.subtleText)
                        .frame(width: 32, height: 32)
                        .contentShape(.rect)
                }
                .accessibilityLabel("Review options")
            }
            StarRating(value: Double(review.stars), size: 12)
            Text(review.text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.ink.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .kareCard()
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
                    Text("Your rating").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)
                    StarPicker(value: $stars)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Your review").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)
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
