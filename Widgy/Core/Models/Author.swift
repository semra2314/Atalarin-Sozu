//
//  Author.swift
//  Kare
//

import Foundation

nonisolated struct Author: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var displayName: String
    var handle: String
    var avatarURL: URL?
    var isVerified: Bool

    init(
        id: String,
        displayName: String,
        handle: String,
        avatarURL: URL? = nil,
        isVerified: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.avatarURL = avatarURL
        self.isVerified = isVerified
    }
}
