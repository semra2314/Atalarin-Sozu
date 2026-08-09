//
//  SectionHeader.swift
//  Widgy
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var seeAllAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headlineSmall)
                    .foregroundStyle(Theme.Palette.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }

            Spacer()

            if let seeAllAction {
                Button(action: seeAllAction) {
                    Text("See all")
                        .widgyCapsLabel()
                        .foregroundStyle(Theme.Palette.ink)
                }
            }
        }
    }
}
