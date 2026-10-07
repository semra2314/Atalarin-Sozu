//
//  WidgetSize.swift
//  Kare
//

import Foundation
import CoreGraphics

/// The home-screen sizes a template can be rendered at.
/// Kept independent of `WidgetKit.WidgetFamily` so the main app target
/// stays free of WidgetKit and the widget extension can map onto it later.
nonisolated enum WidgetSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large
    case accessoryCircular
    case accessoryRectangular

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .accessoryCircular: "Lock · Circular"
        case .accessoryRectangular: "Lock · Rectangular"
        }
    }

    /// Width-to-height ratio used to lay out previews.
    var aspectRatio: CGFloat {
        switch self {
        case .small: 1
        case .medium: 2.13
        case .large: 1 / 1.06
        case .accessoryCircular: 1
        case .accessoryRectangular: 2.8
        }
    }

    var isLockScreen: Bool {
        self == .accessoryCircular || self == .accessoryRectangular
    }

    /// Suffix for per-size product images, e.g. "aurora_small".
    var assetKey: String {
        switch self {
        case .medium: "medium"
        case .large: "large"
        default: "small"
        }
    }
}
