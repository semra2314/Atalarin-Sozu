//
//  CategoryChip.swift
//  Kare
//

import SwiftUI

struct CategoryChip: View {
    let title: String
    let symbolName: String?
    var isSelected: Bool
    var action: () -> Void

    init(
        title: String,
        symbolName: String? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbolName = symbolName
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let symbolName {
                    Image(systemName: symbolName)
                }
                Text(LocalizedStringKey(title))
            }
            .font(Theme.Typography.label)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                isSelected ? Theme.Palette.accent : Theme.Palette.surfaceMuted,
                in: .capsule
            )
            .foregroundStyle(isSelected ? Color.white : Theme.Palette.subtleText)
        }
        .buttonStyle(.plain)
    }
}
