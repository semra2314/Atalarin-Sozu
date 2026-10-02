//
//  KarePlusGate.swift
//  Kare
//
//  Wraps the setup screen of a paid widget. Kare+ members and people who
//  bought this one widget get the screen; everyone else gets one honest page
//  with the two ways to get it.
//
//  While Kare+ is not on sale yet (`subscriptionsAreLive == false`),
//  `unlocksPaidWidgets` is true for everyone and this is a pass-through.
//

import SwiftUI

struct KarePlusGate<Content: View>: View {
    let templateID: String
    @ViewBuilder var content: () -> Content

    @Environment(\.subscriptions) private var subscriptions
    @State private var showKarePlus = false
    @State private var showUnlock = false

    private var template: WidgetTemplate? {
        SampleCatalog.templates.first { $0.id == templateID }
    }

    var body: some View {
        if subscriptions.isUnlocked(templateID: templateID, isFree: template?.price.isFree ?? false) {
            content()
        } else {
            locked
        }
    }

    private var locked: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.Palette.accent)
            Text("A paid widget")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Text("Buy just this one, or unlock every paid widget with Kare+.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)

            if subscriptions.canOfferSubscription, template != nil {
                Button {
                    showUnlock = true
                } label: {
                    Text("See options")
                        .font(Theme.Typography.title)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Palette.accent, in: .capsule)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.background)
        .sheet(isPresented: $showKarePlus) { KarePlusView().kareMacScaled() }
        .sheet(isPresented: $showUnlock) {
            if let template {
                WidgetUnlockSheet(template: template) {
                    // Let this sheet finish going away before the next one.
                    Task {
                        try? await Task.sleep(for: .milliseconds(350))
                        showKarePlus = true
                    }
                }
                .kareMacScaled()
            }
        }
    }
}
