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
private let raisedProfileOverhang: CGFloat = 14

/// Diameter of the raised Profile button.
private let profileDiameter: CGFloat = 52

/// Box every tab icon is drawn into.
///
/// SF Symbols do not share a common height: `square.grid.2x2.fill` is a squat
/// square, `rectangle.stack.fill` is taller, `magnifyingglass` carries a
/// handle below its circle. Left to size themselves, each tab's stack came out
/// a different height, and because the row centres its children vertically the
/// labels ended up on five slightly different baselines — Discover sat visibly
/// higher than the rest. Pinning the icon to a fixed box makes every tab
/// geometrically identical, so the labels line up by construction.
private let iconBox: CGFloat = 24

struct WidgyTabBar: View {
    @Binding var selection: AppTab

    /// Fixed height, declared rather than measured.
    ///
    /// This is what the content inset reserves for scrolling screens. Letting
    /// it be inferred from the subviews left it ambiguous, because the raised
    /// Profile button uses `.offset` and offsets do not participate in layout,
    /// and the Discover list kept ending up trapped behind the bar.
    ///
    /// 68pt against the old 94: a tab icon and its label need 40pt, and the
    /// rest is breathing room. The Profile button still clears the top edge by
    /// its overhang, so the raised look survives the trim.
    static let height: CGFloat = 68

    /// How far the Profile button sticks out above the bar's top edge, derived
    /// rather than guessed so it stays true if any of the three numbers move.
    private static var profilePoke: CGFloat {
        max(0, raisedProfileOverhang - (height - profileDiameter) / 2)
    }

    /// What scrolling screens should reserve: the bar itself, plus the sliver
    /// of Profile button standing above it.
    static var contentInset: CGFloat { height + profilePoke }

    var body: some View {
        HStack(spacing: 0) {
            item(.discover)
            item(.library)
            profileButton
            item(.search)
            item(.settings)
        }
        .frame(height: Self.height)
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
            VStack(spacing: 3) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 19))
                    .frame(height: iconBox)
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.4)
                    .lineLimit(1)
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
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: profileDiameter, height: profileDiameter)
                .background(Circle().fill(Theme.Palette.ink))
                .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 4))
                .shadow(color: .black.opacity(0.22), radius: 9, y: 3)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .offset(y: -raisedProfileOverhang)
    }
}

extension View {
    /// Reserves room at the bottom of scrolling content for the floating tab
    /// bar. Apply to every screen that scrolls beneath it.
    ///
    /// `contentMargins` rather than `padding` so it insets the *scroll*
    /// content — the last row can be scrolled fully clear of the bar, and the
    /// scroll indicator stops in the right place too.
    func widgyTabBarInset() -> some View {
        contentMargins(.bottom, WidgyTabBar.contentInset, for: .scrollContent)
    }
}

#Preview {
    VStack {
        Spacer()
        WidgyTabBar(selection: .constant(.discover))
    }
}
