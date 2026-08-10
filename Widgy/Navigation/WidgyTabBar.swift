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

    /// Fixed height, declared rather than measured.
    ///
    /// This is what the safe-area inset reserves for scrolling content. Letting
    /// it be inferred from the subviews left it ambiguous — the raised Profile
    /// button uses `.offset`, which doesn't participate in layout — and the
    /// Discover list kept ending up trapped behind the bar. 58pt button + the
    /// overhang it needs above + breathing room below.
    static let height: CGFloat = 58 + raisedProfileOverhang + 20

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

extension View {
    /// Reserves room at the bottom of scrolling content for the floating tab
    /// bar. Apply to every screen that scrolls beneath it.
    ///
    /// `contentMargins` rather than `padding` so it insets the *scroll*
    /// content — the last row can be scrolled fully clear of the bar, and the
    /// scroll indicator stops in the right place too.
    func widgyTabBarInset() -> some View {
        contentMargins(.bottom, WidgyTabBar.height, for: .scrollContent)
    }
}

#Preview {
    VStack {
        Spacer()
        WidgyTabBar(selection: .constant(.discover))
    }
}
