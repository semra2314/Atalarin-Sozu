//
//  DailySetupView.swift
//  Widgy
//
//  Where the Daily widget gets its source. Choosing here writes into the App
//  Group and reloads the widget, so the home screen follows immediately.
//

import SwiftUI

struct DailySetupView: View {
    @State private var selected: DailySource = .proverbs
    @State private var showAddToHome = false

    private var todaysPassage: DailyPassage {
        DailyStore.passage(for: .now, source: selected)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                preview
                sourceList
                note
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Daily")
        .navigationBarTitleDisplayMode(.inline)
        .task { selected = DailyStore.loadSource() }
        .sheet(isPresented: $showAddToHome) {
            AddToHomeGuide(galleryName: "Daily").presentationDetents([.large])
        }
    }

    // MARK: - Preview

    private var preview: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(todaysPassage.text)
                .font(AppFont.serif(size: 24, weight: .regular))
                .foregroundStyle(Color(hex: "2B2018"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if !todaysPassage.reference.isEmpty {
                Text(todaysPassage.reference)
                    .font(Theme.Typography.label)
                    .foregroundStyle(Color(hex: "2B2018").opacity(0.55))
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
        .padding(.horizontal, Theme.Spacing.xl)
        .background {
            ZStack {
                LinearGradient(colors: [Color(hex: "FAF3E7"), Color(hex: "EBDCC4")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Color(hex: "E8C88A").opacity(0.55), .clear],
                               center: .topTrailing, startRadius: 0, endRadius: 260)
            }
        }
        .clipShape(.rect(cornerRadius: Theme.Radius.hero, style: .continuous))
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
        .animation(.snappy, value: selected)
    }

    // MARK: - Sources

    private var sourceList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Source").widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)

            VStack(spacing: 0) {
                ForEach(Array(DailySource.allCases.enumerated()), id: \.element.id) { index, source in
                    Button {
                        withAnimation(.snappy) { selected = source }
                        DailyStore.save(source: source)
                    } label: {
                        row(source)
                    }
                    .buttonStyle(.plain)

                    if index < DailySource.allCases.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .widgyCard()
        }
    }

    private func row(_ source: DailySource) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: source.symbolName)
                .font(.footnote)
                .foregroundStyle(selected == source ? .white : Theme.Palette.ink)
                .frame(width: 34, height: 34)
                .background(selected == source ? Theme.Palette.accent : Theme.Palette.surfaceMuted,
                            in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(source.displayName)
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Palette.ink)
                Text(source.subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .lineLimit(1)
            }

            Spacer()

            if selected == source {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Palette.accent)
            }
        }
        .padding(Theme.Spacing.md)
        .contentShape(.rect)
    }

    // MARK: - Note

    private var note: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Every passage is shown with its reference, and comes from a public-domain translation.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)

            Button {
                showAddToHome = true
            } label: {
                Text("How do I add it to my home screen?")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.accent)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack { DailySetupView() }
        .environment(\.appEnvironment, .preview)
}
