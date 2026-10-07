//
//  ProfileStore.swift
//  Kare
//
//  The user's avatar. Name and handle live in `@AppStorage`; an image doesn't
//  belong there — UserDefaults is for small values, and a photo would be read
//  back on every launch whether it's needed or not. This keeps it as a file.
//

import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class ProfileStore {
    static let shared = ProfileStore()

    /// Bumped on every write so views observing this object redraw. The file
    /// path never changes, so SwiftUI has nothing else to notice.
    private(set) var revision = 0

    private let fileName = "profile-avatar.jpg"

    private var fileURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    private init() {}

    #if canImport(UIKit)
    func avatar() -> UIImage? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    /// Downscaled before saving: this is drawn at 100pt at most, so a full
    /// camera image would be a hundred times more than anyone can see.
    func save(imageData: Data) {
        guard let fileURL,
              let compact = ImageDownscaler.downscaledJPEG(imageData, maxDimension: 400) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? compact.write(to: fileURL, options: .atomic)
        revision += 1
    }

    func removeAvatar() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
        revision += 1
    }
    #endif
}
