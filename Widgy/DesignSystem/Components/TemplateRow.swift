//
//  TemplateRow.swift
//  Widgy
//

import SwiftUI

struct TemplateRow: View {
    let template: WidgetTemplate

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            WidgetPreview(template: template, size: .small, showsLabel: false)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                Text(template.summary)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .lineLimit(1)
            }

            Spacer(minLength: Theme.Spacing.sm)

            Text(template.price.displayText)
                .font(Theme.Typography.labelCaps)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Palette.accentTint, in: .capsule)
                .foregroundStyle(Theme.Palette.accent)
        }
        .padding(Theme.Spacing.md)
        .contentShape(.rect)
    }
}
