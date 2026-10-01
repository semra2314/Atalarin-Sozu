//
//  AppEnvironment.swift
//  Kare
//

import SwiftUI

/// Single composition root. Everything the app depends on is assembled here,
/// which is what makes the Mock -> Firebase swap a one-line change.
///
/// Deliberately immutable and `Sendable`: it is a dependency container, not
/// observable state, so it carries no actor isolation of its own.
nonisolated final class AppEnvironment: Sendable {
    let widgets: WidgetRepository

    init(widgets: WidgetRepository) {
        self.widgets = widgets
    }

    /// The configuration the shipping app runs on.
    ///
    /// Default is the in-memory mock so the app builds and demos with zero setup.
    /// Once the iCloud/CloudKit capability is added and the catalog is seeded,
    /// switch this to `.cloudKit(...)` — no view or view-model changes needed:
    ///
    ///     static let live = cloudKit(containerIdentifier: "iCloud.com.yourteam.Widgy")
    ///
    /// The catalogue ships inside the app, so the live build runs the mock with
    /// no artificial delay. The 220ms default exists to make loading states
    /// visible in development; in the shipping app it was just a spinner
    /// flashing on every screen for no reason.
    ///
    /// Reviews are real now: `FirebaseWidgetRepository` keeps the bundled
    /// catalogue and sends reviews to Firestore.
    static let live = AppEnvironment(widgets: FirebaseWidgetRepository())

    /// CloudKit-backed catalog (public database).
    static func cloudKit(containerIdentifier: String) -> AppEnvironment {
        AppEnvironment(widgets: CloudKitWidgetRepository(containerIdentifier: containerIdentifier))
    }

    /// Instant, deterministic data for SwiftUI previews and tests.
    static let preview = AppEnvironment(widgets: MockWidgetRepository(artificialDelay: .zero))
}

extension EnvironmentValues {
    @Entry var appEnvironment: AppEnvironment = .preview
}
