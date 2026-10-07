//
//  LungsGauge.swift
//  Kare  (shared: app + widget extension)
//
//  A pair of lungs that fill from the bottom. Used by the Exhale widget and
//  by its setup screen, so the preview in the app is the widget, not a
//  drawing of it.
//

import SwiftUI

struct LungsGauge: View {
    /// 0...1. Clamped, so a bad value draws empty or full, never inverted.
    var level: Double
    var fill: [Color] = [Color(hex: "34D399"), Color(hex: "A7F3D0")]
    var track: Color = Color.white.opacity(0.14)
    var outline: Color = Color.white.opacity(0.35)

    private var clamped: Double { min(1, max(0, level)) }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    Rectangle().fill(track)
                    Rectangle()
                        .fill(LinearGradient(colors: fill, startPoint: .bottom, endPoint: .top))
                        .frame(height: geo.size.height * clamped)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .mask {
                Image(systemName: "lungs.fill")
                    .resizable()
                    .scaledToFit()
            }

            Image(systemName: "lungs")
                .resizable()
                .scaledToFit()
                .foregroundStyle(outline)
        }
        .aspectRatio(1.15, contentMode: .fit)
        .animation(.spring(duration: 1.2, bounce: 0.25), value: clamped)
        .accessibilityElement()
        .accessibilityLabel(Text("Lungs"))
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    HStack(spacing: 20) {
        LungsGauge(level: 0.2)
        LungsGauge(level: 0.65)
        LungsGauge(level: 1)
    }
    .frame(height: 120)
    .padding()
    .background(Color(hex: "0F2A27"))
}
