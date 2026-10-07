//
//  WidgetRepository.swift
//  Kare
//

import Foundation

/// The catalog contract. Every screen talks to this, never to a concrete backend.
///
/// Today `MockWidgetRepository` fulfils it with local sample data.
/// Swapping in `FirebaseWidgetRepository` later is a one-line change in
/// `AppEnvironment` — no view or view-model needs to be touched.
nonisolated protocol WidgetRepository: Sendable {
    func discoverSections() async throws -> [CatalogSection]
    func template(id: String) async throws -> WidgetTemplate
    func search(query: String, category: WidgetCategory?) async throws -> [WidgetTemplate]
    func templates(in category: WidgetCategory) async throws -> [WidgetTemplate]

    /// Reviews for a template, newest first.
    func reviews(for templateID: String) async throws -> [Review]
    /// Post (or replace the author's) review.
    func submitReview(_ review: Review) async throws
}

nonisolated enum RepositoryError: LocalizedError {
    case notFound
    case notImplemented(String)
    case transport(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            "We couldn't find that widget."
        case let .notImplemented(what):
            "\(what) isn't wired up yet."
        case let .transport(underlying):
            underlying.localizedDescription
        }
    }
}
