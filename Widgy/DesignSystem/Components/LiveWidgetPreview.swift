//
//  LiveWidgetPreview.swift
//  Kare
//
//  Catalogue art for the Kare+ live widgets, drawn in code until there are
//  store images for them. Uses the same pieces the widgets do, so the card
//  looks like what lands on the home screen.
//

import SwiftUI

struct LiveWidgetPreview: View {
    let templateID: String
    let size: WidgetSize

    static let supportedIDs: Set<String> = ["t-exhale", "t-countdown", "t-progress"]

    private var isSmall: Bool { size == .small || size.isLockScreen }

    var body: some View {
        ZStack {
            background
            content
                .padding(isSmall ? 12 : 16)
        }
        .aspectRatio(size.aspectRatio, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder private var background: some View {
        switch templateID {
        case "t-exhale":
            LinearGradient(colors: [Color(hex: "0B1F1D"), Color(hex: "124A42")], startPoint: .top, endPoint: .bottom)
        case "t-countdown":
            LinearGradient(colors: [Color(hex: "1E3A8A"), Color(hex: "1E3A8A").opacity(0.75)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            Color(hex: "F6F1E7")
        }
    }

    @ViewBuilder private var content: some View {
        switch templateID {
        case "t-exhale":
            HStack(spacing: 12) {
                LungsGauge(level: 0.46)
                if !isSmall {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(9) days").font(AppFont.serif(size: 24, weight: .heavy))
                        Text("smoke-free").font(.caption2.weight(.semibold)).opacity(0.7)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        case "t-countdown":
            VStack(alignment: .leading, spacing: 2) {
                Text("✈️ Summer trip").font(.caption.weight(.semibold)).opacity(0.9)
                Spacer(minLength: 0)
                Text("23").font(AppFont.serif(size: isSmall ? 40 : 48, weight: .heavy))
                Text("days to go").font(.caption2.weight(.medium)).opacity(0.75)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        default:
            let fraction = ProgressKind.year.fraction(at: .now) ?? 0.5
            VStack(alignment: .leading, spacing: 4) {
                Text(ProgressKind.year.title(at: .now))
                    .font(.caption2.weight(.bold))
                    .opacity(0.6)
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(AppFont.serif(size: isSmall ? 34 : 44, weight: .heavy))
                Spacer(minLength: 0)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: "1D1D1F").opacity(0.1))
                        Capsule().fill(Color(hex: "D44A33")).frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 6)
            }
            .foregroundStyle(Color(hex: "1D1D1F"))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    VStack {
        LiveWidgetPreview(templateID: "t-exhale", size: .medium)
        LiveWidgetPreview(templateID: "t-countdown", size: .small)
        LiveWidgetPreview(templateID: "t-progress", size: .small)
    }
    .padding()
}
