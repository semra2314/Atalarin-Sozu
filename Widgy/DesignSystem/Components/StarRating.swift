//
//  StarRating.swift
//  Kare
//

import SwiftUI

/// Read-only star display supporting halves (e.g. 4.6).
struct StarRating: View {
    let value: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(Theme.Palette.accent)
            }
        }
        .accessibilityLabel("\(value, specifier: "%.1f") out of 5 stars")
    }

    private func symbol(for index: Int) -> String {
        let delta = value - Double(index)
        if delta >= 1 { return "star.fill" }
        if delta >= 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Interactive 1...5 star picker.
struct StarPicker: View {
    @Binding var value: Int
    var size: CGFloat = 30

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= value ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(Theme.Palette.accent)
                    .onTapGesture {
                        withAnimation(.snappy) { value = star }
                    }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRating(value: 4.6)
        StarPicker(value: .constant(3))
    }
    .padding()
}
