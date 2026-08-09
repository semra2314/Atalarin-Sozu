//
//  WidgetCard.swift
//  Widgy
//

import SwiftUI

/// Preview plus metadata — the repeating unit of every catalog row.
struct WidgetCard: View {
    let template: WidgetTemplate
    var size: WidgetSize?
    var width: CGFloat = 168

    private var renderSize: WidgetSize { size ?? template.primarySize }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            WidgetPreview(template: template, size: renderSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(Theme.Typography.headlineSmall)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.xs) {
                    Text(template.author.displayName)
                        .lineLimit(1)
                    Text("·")
                    Text(template.price.displayText)
                        .fontWeight(template.price.isFree ? .regular : .semibold)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
            }
        }
        .frame(width: width, alignment: .leading)
        .contentShape(.rect)
    }
}

#Preview {
    HStack(spacing: 16) {
        WidgetCard(template: SampleCatalog.templates[0], size: .small)
        WidgetCard(template: SampleCatalog.templates[1], size: .small)
    }
    .padding()
}
