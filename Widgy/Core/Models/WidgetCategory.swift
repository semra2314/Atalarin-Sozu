//
//  WidgetCategory.swift
//  Widgy
//

import Foundation

nonisolated enum WidgetCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case productivity
    case health
    case finance
    case weather
    case photos
    case minimal
    case social
    case fun

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .productivity: "Productivity"
        case .health: "Health"
        case .finance: "Finance"
        case .weather: "Weather"
        case .photos: "Photos"
        case .minimal: "Minimal"
        case .social: "Social"
        case .fun: "Fun"
        }
    }

    var symbolName: String {
        switch self {
        case .productivity: "checklist"
        case .health: "heart.fill"
        case .finance: "chart.line.uptrend.xyaxis"
        case .weather: "cloud.sun.fill"
        case .photos: "photo.on.rectangle.angled"
        case .minimal: "circle.dotted"
        case .social: "bubble.left.and.bubble.right.fill"
        case .fun: "sparkles"
        }
    }
}
