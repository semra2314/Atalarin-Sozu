//
//  ProgressSetupView.swift
//  Kare
//
//  Shows what each Progress widget measures, and takes the one input it needs:
//  a birthday, for "Your life".
//

import SwiftUI

struct ProgressSetupView: View {
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -22, to: .now) ?? .now
    @State private var hasBirthday = false
    @State private var showAddToHome = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                preview
                birthday
                note
            }
            .kareReadableWidth()
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let saved = LifeProgressStore.birthDate() {
                birthDate = saved
                hasBirthday = true
            }
        }
        .sheet(isPresented: $showAddToHome) {
            AddToHomeGuide(galleryName: "Progress").presentationDetents([.large])
        }
    }

    // MARK: - Preview

    /// Every kind at once, as bars. On the home screen each widget shows one;
    /// "Edit Widget" picks which.
    private var preview: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(ProgressKind.allCases) { kind in
                row(kind)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.surface, in: .rect(cornerRadius: Theme.Radius.hero, style: .continuous))
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
    }

    private func row(_ kind: ProgressKind) -> some View {
        let fraction = kind.fraction(at: .now)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(kind.title(at: .now))
                    .font(Theme.Typography.labelCaps)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(Theme.Palette.subtleText)
                Spacer()
                if let fraction {
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(AppFont.serif(size: 20, weight: .heavy))
                        .foregroundStyle(Theme.Palette.ink)
                } else {
                    Text("Add your birthday")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Palette.ink.opacity(0.1))
                    Capsule().fill(Theme.Palette.accent)
                        .frame(width: geo.size.width * (fraction ?? 0))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Birthday

    private var birthday: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Your life").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)

            VStack(spacing: 0) {
                Toggle("Show my life in years", isOn: $hasBirthday)
                    .font(Theme.Typography.cardTitle)
                    .tint(Theme.Palette.accent)
                    .padding(Theme.Spacing.md)

                if hasBirthday {
                    Divider().padding(.leading, Theme.Spacing.md)
                    DatePicker("Birthday", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
                        .padding(Theme.Spacing.md)
                }
            }
            .kareCard()
            .onChange(of: hasBirthday) { _, on in
                LifeProgressStore.save(birthDate: on ? birthDate : nil)
            }
            .onChange(of: birthDate) { _, date in
                if hasBirthday { LifeProgressStore.save(birthDate: date) }
            }

            Text("Drawn against \(LifeProgressStore.lifespanYears) years: a round number, not a prediction. Your birthday stays on this phone.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Each Progress widget measures one thing. Touch and hold it on your home screen, then Edit Widget, to choose the day, week, month, year or your life.")
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
    NavigationStack { ProgressSetupView() }
        .environment(\.appEnvironment, .preview)
}
