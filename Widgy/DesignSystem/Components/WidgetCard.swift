//
//  WidgetCard.swift
//  Kare
//

import SwiftUI

/// Preview plus metadata — the repeating unit of every catalog row.
struct WidgetCard: View {
    let template: WidgetTemplate
    var size: WidgetSize?
    var width: CGFloat = 168

    @Environment(\.subscriptions) private var subscriptions
    /// At the accessibility text sizes a one-line name is "Auro…", which
    /// tells nobody anything. Those sizes get room to wrap instead.
    @Environment(\.dynamicTypeSize) private var typeSize
    private var nameLines: Int { typeSize.isAccessibilitySize ? 3 : 1 }

    private var renderSize: WidgetSize { size ?? template.primarySize }

    /// Paid, and not yet covered by a subscription. The badge disappears the
    /// moment Kare+ is active, so a member never sees a lock on something
    /// they can already have.
    private var isLocked: Bool { !subscriptions.isUnlocked(template) }

    /// Quoting a price for something we are about to hand over free is a
    /// price the App Store will never charge. Until Kare+ is on sale every
    /// design is free, so every card says so.
    private var shownPrice: WidgetTemplate.Price {
        SubscriptionStore.subscriptionsAreLive ? template.price : .free
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            WidgetPreview(template: template, size: renderSize)
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.45), in: .circle)
                            .padding(6)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(template.name))
                    .font(Theme.Typography.headlineSmall)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(nameLines)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: typeSize.isAccessibilitySize)

                // Side by side when it fits, stacked when the text is large.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(template.author.displayName)
                        Text("·")
                        subscriptions.priceText(for: template)
                            .fontWeight(subscriptions.priceIsEmphasised(for: template) ? .semibold : .regular)
                    }
                    .lineLimit(1)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(template.author.displayName).lineLimit(1)
                        subscriptions.priceText(for: template)
                            .fontWeight(subscriptions.priceIsEmphasised(for: template) ? .semibold : .regular)
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
            }
        }
        .frame(width: width, alignment: .leading)
        .contentShape(.rect)
        // One stop for VoiceOver: name, author, price, and whether it is locked.
        .accessibilityElement(children: .combine)
        .accessibilityValue(isLocked ? Text("Kare+") : Text(""))
    }
}

#Preview {
    HStack(spacing: 16) {
        WidgetCard(template: SampleCatalog.templates[0], size: .small)
        WidgetCard(template: SampleCatalog.templates[1], size: .small)
    }
    .padding()
}
