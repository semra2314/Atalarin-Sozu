//
//  Review.swift
//  Kare
//
//  A user's star rating + comment on a template. Pure value type, like the rest
//  of the catalog models, so it round-trips through CloudKit/JSON unchanged.
//

import Foundation

nonisolated struct Review: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var templateID: String
    var authorName: String
    /// The Firebase user who wrote it. Nil only for reviews from the
    /// in-memory mock, which has no accounts.
    var authorID: String?
    var stars: Int          // 1...5
    var text: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        templateID: String,
        authorName: String,
        authorID: String? = nil,
        stars: Int,
        text: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.templateID = templateID
        self.authorName = authorName
        self.authorID = authorID
        self.stars = max(1, min(5, stars))
        self.text = text
        self.createdAt = createdAt
    }
}
