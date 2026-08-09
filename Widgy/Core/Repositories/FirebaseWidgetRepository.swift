//
//  FirebaseWidgetRepository.swift
//  Widgy
//
//  Placeholder for the production backend.
//
//  To activate:
//    1. Add the Firebase SPM package (FirebaseFirestore) to the Widgy target.
//    2. Drop `GoogleService-Info.plist` into the project.
//    3. Uncomment the implementation below and delete the `notImplemented` throws.
//    4. In `AppEnvironment.live`, swap `MockWidgetRepository()` for
//       `FirebaseWidgetRepository()`. Nothing else changes.
//
//  Expected Firestore shape:
//    /templates/{templateId}        -> WidgetTemplate (Codable)
//    /catalogSections/{sectionId}   -> { title, subtitle, style, templateIds: [String] }
//

import Foundation

nonisolated struct FirebaseWidgetRepository: WidgetRepository {

    func discoverSections() async throws -> [CatalogSection] {
        throw RepositoryError.notImplemented("Firebase discover")
    }

    func template(id: String) async throws -> WidgetTemplate {
        throw RepositoryError.notImplemented("Firebase template fetch")
    }

    func search(query: String, category: WidgetCategory?) async throws -> [WidgetTemplate] {
        throw RepositoryError.notImplemented("Firebase search")
    }

    func templates(in category: WidgetCategory) async throws -> [WidgetTemplate] {
        throw RepositoryError.notImplemented("Firebase category fetch")
    }

    func reviews(for templateID: String) async throws -> [Review] {
        throw RepositoryError.notImplemented("Firebase reviews")
    }

    func submitReview(_ review: Review) async throws {
        throw RepositoryError.notImplemented("Firebase submit review")
    }
}
