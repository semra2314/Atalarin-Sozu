//
//  WidgetUnlockSheet.swift
//  Kare
//
//  Two honest ways to get a paid widget: buy just this one, or open every
//  paid widget with Kare+. Equal footing, no dark patterns: the single price
//  is shown as plainly as the subscription.
//

import SwiftUI
import StoreKit

struct WidgetUnlockSheet: View {
    let template: WidgetTemplate
    /// Called when the user picks Kare+ instead. The parent dismisses this
    /// sheet and shows the paywall, so two sheets never stack.
    var onChooseKarePlus: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.subscriptions) private var store
    @State private var phase: AddPhase?

    private var product: Product? { store.product(forTemplate: template.id) }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            WidgetPreview(template: template, size: template.primarySize, showsLabel: false)
                .frame(width: 150, height: 150)
                .clipShape(.rect(cornerRadius: 30, style: .continuous))
                .shadow(color: Theme.Shadow.color, radius: 20, y: 8)
                .accessibilityHidden(true)
                .padding(.top, Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.xs) {
                Text(LocalizedStringKey(template.name))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text(LocalizedStringKey(template.summary))
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer(minLength: 0)

            VStack(spacing: Theme.Spacing.sm) {
                buyThisButton
                karePlusButton
                Button {
                    Task { await store.restore() }
                } label: {
                    Text("Restore purchases")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.accent)
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .addedCelebration($phase, kind: .purchase)
        .task { if store.products.isEmpty { await store.load() } }
        .alert("Something went wrong",
               isPresented: Binding(get: { store.errorMessage != nil },
                                    set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var buyThisButton: some View {
        Button {
            guard let product else { return }
            runAddCelebration($phase, work: { await store.purchase(product) }) {
                dismiss()
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if store.isLoading && product == nil {
                    ProgressView().tint(.white)
                } else {
                    Text("Buy just this one")
                    Text(verbatim: "·").opacity(0.6)
                    Text(verbatim: store.displayPrice(for: template))
                }
            }
            .font(Theme.Typography.title)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.Palette.accent, in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(product == nil || phase != nil)
        .opacity(product == nil && !store.isLoading ? 0.5 : 1)
    }

    private var karePlusButton: some View {
        Button {
            dismiss()
            onChooseKarePlus()
        } label: {
            VStack(spacing: 2) {
                Text("Unlock everything with Kare+")
                    .font(Theme.Typography.title)
                if let monthly = store.monthly?.displayPrice {
                    Text("From \(monthly)/mo")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }
            .foregroundStyle(Theme.Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.Palette.surface, in: .capsule)
            .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(phase != nil)
    }
}
