//
//  MockWidgetRepository.swift
//  Widgy
//

import Foundation

/// In-memory catalog used for development, previews and tests.
actor MockWidgetRepository: WidgetRepository {
    private let templates: [WidgetTemplate]
    private var reviewsStore: [Review]
    private let artificialDelay: Duration

    init(
        templates: [WidgetTemplate] = SampleCatalog.templates,
        reviews: [Review] = SampleCatalog.reviews,
        artificialDelay: Duration = .milliseconds(220)
    ) {
        self.templates = templates
        self.reviewsStore = reviews
        self.artificialDelay = artificialDelay
    }

    func discoverSections() async throws -> [CatalogSection] {
        try await simulateLatency()
        let sorted = templates.sorted { $0.installCount > $1.installCount }
        return [
            CatalogSection(
                id: "spotlight",
                title: "Featured today",
                subtitle: "Hand-picked by the Kare team",
                style: .spotlight,
                templates: Array(sorted.prefix(3))
            ),
            CatalogSection(
                id: "trending",
                title: "Trending",
                subtitle: "Most installed this week",
                style: .carousel,
                templates: Array(sorted.prefix(8))
            ),
            CatalogSection(
                id: "minimal",
                title: "Quietly minimal",
                subtitle: nil,
                style: .carousel,
                templates: templates.filter { $0.category == .minimal }
            ),
            CatalogSection(
                id: "free",
                title: "Great and free",
                subtitle: nil,
                style: .compactList,
                templates: templates.filter { $0.price.isFree }
            )
        ].filter { !$0.templates.isEmpty }
    }

    func template(id: String) async throws -> WidgetTemplate {
        try await simulateLatency()
        guard let match = templates.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return match
    }

    func search(query: String, category: WidgetCategory?) async throws -> [WidgetTemplate] {
        try await simulateLatency()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return templates.filter { template in
            let matchesCategory = category == nil || template.category == category
            guard matchesCategory else { return false }
            guard !trimmed.isEmpty else { return true }
            return template.name.lowercased().contains(trimmed)
                || template.summary.lowercased().contains(trimmed)
                || template.tags.contains { $0.lowercased().contains(trimmed) }
                || template.author.displayName.lowercased().contains(trimmed)
        }
    }

    func templates(in category: WidgetCategory) async throws -> [WidgetTemplate] {
        try await simulateLatency()
        return templates.filter { $0.category == category }
    }

    func reviews(for templateID: String) async throws -> [Review] {
        try await simulateLatency()
        return reviewsStore
            .filter { $0.templateID == templateID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func submitReview(_ review: Review) async throws {
        try await simulateLatency()
        // One review per author per template in the demo: replace if it exists.
        reviewsStore.removeAll { $0.templateID == review.templateID && $0.authorName == review.authorName }
        reviewsStore.append(review)
    }

    private func simulateLatency() async throws {
        guard artificialDelay > .zero else { return }
        try await Task.sleep(for: artificialDelay)
    }
}
