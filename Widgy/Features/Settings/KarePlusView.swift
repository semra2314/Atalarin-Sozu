//
//  KarePlusView.swift
//  Widgy
//
//  The Kare+ subscription screen.
//
//  Prices and the pool share are declared once, here, and match the creator
//  agreement on the portal word for word. If the deck, the site and the app
//  ever disagree about what Kare+ costs, this is the file that was not updated.
//
//  There is no StoreKit behind this yet. Rather than pretend, the sheet says
//  plainly that the beta takes no payment, and "subscribing" flips a local
//  flag so the rest of the app can be seen in its subscribed state. A button
//  that silently does nothing would be worse than no button; a button that
//  implies a charge it never makes would be worse still.
//

import SwiftUI

// MARK: - Terms

enum KarePlus {
    /// Mirrors `SUBSCRIPTION` in the portal's lib/terms.ts.
    static let monthlyPrice = "$1.99"
    static let yearlyPrice = "$14.99"

    /// Yıllık planın aylığa göre kazandırdığı oran, hesaplanıyor ki fiyatlar
    /// değişince rozet kendiliğinden düzelsin.
    static var yearlySavingText: String {
        let monthlyYear = 1.99 * 12
        let percent = Int(((monthlyYear - 14.99) / monthlyYear * 100).rounded())
        return "%\(percent)"
    }

    /// Share of net subscription revenue that goes to the creator pool.
    static let poolPercent = 50

    static let isSubscribedKey = "karePlusActive"
}

enum KarePlusPlan: String, CaseIterable, Identifiable {
    case yearly, monthly
    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        }
    }

    var price: String {
        switch self {
        case .yearly: KarePlus.yearlyPrice
        case .monthly: KarePlus.monthlyPrice
        }
    }

    var per: LocalizedStringKey {
        switch self {
        case .yearly: "per year"
        case .monthly: "per month"
        }
    }
}

// MARK: - Screen

struct KarePlusView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(KarePlus.isSubscribedKey) private var isSubscribed = false
    @State private var plan: KarePlusPlan = .yearly

    private let benefits: [(String, LocalizedStringKey, LocalizedStringKey)] = [
        ("square.grid.2x2.fill", "Every paid widget",
         "Install anything in the catalogue without buying widgets one by one."),
        ("wand.and.stars", "The full editor",
         "Advanced backgrounds, custom stickers and every typography control."),
        ("heart.fill", "Designers get paid",
         "Half of subscription revenue goes to the creators whose widgets you actually use."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    hero
                    benefitList
                    if isSubscribed {
                        activeCard
                    } else {
                        planPicker
                        subscribeButton
                    }
                    footnote
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(Theme.Palette.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.Palette.subtleText)
                    }
                }
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Theme.Palette.accent)
                    .frame(width: 18, height: 18)
                Text("Kare+")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
            }
            .padding(.top, Theme.Spacing.lg)

            Text("Every paid widget, one subscription.")
                .font(Theme.Typography.bodyLarge)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Benefits

    private var benefitList: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ForEach(benefits, id: \.0) { symbol, title, detail in
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    Image(systemName: symbol)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.accent)
                        .frame(width: 34, height: 34)
                        .background(Theme.Palette.accentTint, in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.Palette.ink)
                        Text(detail)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Palette.subtleText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Plans

    private var planPicker: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(KarePlusPlan.allCases) { option in
                Button { plan = option } label: { planRow(option) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func planRow(_ option: KarePlusPlan) -> some View {
        let selected = plan == option
        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .font(.title3)
                .foregroundStyle(selected ? Theme.Palette.accent : Theme.Palette.hairline)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(option.title)
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Palette.ink)
                    if option == .yearly {
                        Text("Save \(KarePlus.yearlySavingText)")
                            .font(Theme.Typography.labelCaps)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, 3)
                            .background(Theme.Palette.accent, in: .capsule)
                            .foregroundStyle(.white)
                    }
                }
                Text(option.per)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            Spacer()

            Text(option.price)
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.surface, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(selected ? Theme.Palette.accent : Theme.Palette.hairline,
                        lineWidth: selected ? 1.5 : 0.5)
        }
        .contentShape(.rect)
    }

    private var subscribeButton: some View {
        Button {
            withAnimation(.snappy) { isSubscribed = true }
        } label: {
            Text("Subscribe")
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
                .background(Theme.Palette.accent, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: Subscribed state

    private var activeCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.Palette.accent, in: .circle)
            Text("Kare+ is active")
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Palette.ink)
            Text("Every paid widget in the catalogue is yours to install.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)

            Button {
                withAnimation(.snappy) { isSubscribed = false }
            } label: {
                Text("Turn off").widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .widgyCard()
    }

    // MARK: Footnote

    private var footnote: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("No payment is taken in this beta.")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.ink)
            Text("\(KarePlus.poolPercent)% of subscription revenue goes to the creator pool and is shared between the designers whose widgets are installed that month.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }
}

#Preview {
    KarePlusView()
}
