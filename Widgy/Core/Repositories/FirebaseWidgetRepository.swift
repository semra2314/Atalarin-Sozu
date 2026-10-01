//
//  FirebaseWidgetRepository.swift
//  Kare
//
//  What the shipping app runs on. The catalogue ships inside the app (it is
//  ours, it changes with app updates, and it must work offline), so those
//  calls go straight to the bundled catalogue. Reviews are written by people
//  and read by other people, so they go to Firestore.
//

import Foundation

nonisolated struct FirebaseWidgetRepository: WidgetRepository {
    private let catalog = MockWidgetRepository(artificialDelay: .zero)

    func discoverSections() async throws -> [CatalogSection] {
        try await catalog.discoverSections()
    }

    func template(id: String) async throws -> WidgetTemplate {
        try await catalog.template(id: id)
    }

    func search(query: String, category: WidgetCategory?) async throws -> [WidgetTemplate] {
        try await catalog.search(query: query, category: category)
    }

    func templates(in category: WidgetCategory) async throws -> [WidgetTemplate] {
        try await catalog.templates(in: category)
    }

    func reviews(for templateID: String) async throws -> [Review] {
        guard await ReviewService.isAvailable else { return try await catalog.reviews(for: templateID) }
        do {
            return try await ReviewService.fetch(templateID: templateID)
        } catch {
            throw RepositoryError.transport(underlying: error)
        }
    }

    func submitReview(_ review: Review) async throws {
        guard await ReviewService.isAvailable else { return try await catalog.submitReview(review) }
        try await ReviewService.submit(review)
    }
}
