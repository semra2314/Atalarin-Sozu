//
//  TemplateRow.swift
//  Kare
//

import SwiftUI

struct TemplateRow: View {
    let template: WidgetTemplate
    @Environment(\.subscriptions) private var subscriptions

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            WidgetPreview(template: template, size: .small, showsLabel: false)
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(template.name))
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                Text(LocalizedStringKey(template.summary))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .lineLimit(1)
            }

            Spacer(minLength: Theme.Spacing.sm)

            // Same rule as `WidgetCard`: no sticker price until Kare+ is on sale.
            subscriptions.priceText(for: template)
                .font(Theme.Typography.labelCaps)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Palette.accentTint, in: .capsule)
                .foregroundStyle(Theme.Palette.accent)
        }
        .padding(Theme.Spacing.md)
        .contentShape(.rect)
        // One stop for VoiceOver: name, summary, price.
        .accessibilityElement(children: .combine)
    }
}
