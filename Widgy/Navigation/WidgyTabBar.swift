//
//  WidgyTabBar.swift
//  Widgy
//
//  Custom bottom navigation: Discover · Widgets · [raised black Profile] · Search · Settings.
//  The centre Profile is a filled black circle that pops above the bar.
//

import SwiftUI

/// How far the centre Profile button pops above the bar. File-scope so both the
/// layout padding and the offset read from one number and can't drift apart.
private let raisedProfileOverhang: CGFloat = 16

struct WidgyTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            item(.discover)
            item(.library)
            profileButton
            item(.search)
            item(.settings)
        }
        // The raised profile button is moved up with `.offset`, which doesn't
        // participate in layout — so the bar has to reserve that space itself,
        // otherwise the safe-area inset under-reports its height and scrolling
        // content ends up trapped behind it.
        .padding(.top, 12 + raisedProfileOverhang)
        .padding(.bottom, 4)
        .padding(.horizontal, Theme.Spacing.sm)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.Palette.hairline).frame(height: 0.5)
                }
        }
    }

    private func item(_ tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 20))
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            .foregroundStyle(selection == tab ? Theme.Palette.accent : Theme.Palette.subtleText)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var profileButton: some View {
        Button {
            selection = .profile
        } label: {
            Image(systemName: "person.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Theme.Palette.ink))
                .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 4))
                .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .offset(y: -raisedProfileOverhang)
    }
}

#Preview {
    VStack {
        Spacer()
        WidgyTabBar(selection: .constant(.discover))
    }
}
