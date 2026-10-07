//
//  StateViews.swift
//  Kare
//

import SwiftUI

struct LoadingStateView: View {
    var message: String = "Loading widgets…"

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
            Text(message)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let message: String
    var retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
