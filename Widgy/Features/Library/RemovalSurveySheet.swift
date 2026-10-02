//
//  RemovalSurveySheet.swift
//  Kare
//
//  "Why did you remove it?" One tap, an optional line, and a Skip that is
//  as easy to hit as Send. The widget is already gone by the time this
//  shows; answering changes nothing about that.
//

import SwiftUI

struct RemovalSurveySheet: View {
    let target: RemovalSurveyTarget

    @Environment(\.dismiss) private var dismiss
    @State private var reason: RemovalReason?
    @State private var note = ""
    @State private var sent = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if sent {
                thanks
            } else {
                header
                options
                if reason != nil { noteField }
                Spacer(minLength: 0)
                buttons
            }
        }
        .padding(Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.Palette.background)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: reason)
        .animation(.easeInOut(duration: 0.25), value: sent)
        .sensoryFeedback(.selection, trigger: reason)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { RemovalFeedbackStore.markAsked() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Why did you remove it?")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Text("\(Text(LocalizedStringKey(target.name)).bold()) is gone from your library. A quick answer helps us make Kare better.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }

    private var options: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(RemovalReason.allCases) { option in
                let selected = reason == option
                Button {
                    reason = option
                    if option == .other { noteFocused = true }
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Text(option.emoji).font(.system(size: 20))
                        Text(LocalizedStringKey(option.titleKey))
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(Theme.Palette.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selected ? Theme.Palette.accent : Theme.Palette.hairline)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 12)
                    .background(selected ? Theme.Palette.accentTint : Theme.Palette.surface,
                                in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(selected ? Theme.Palette.accent : Theme.Palette.hairline,
                                          lineWidth: selected ? 1.5 : 1)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var noteField: some View {
        TextField(reason == .other ? LocalizedStringKey("Tell us in a few words")
                                    : LocalizedStringKey("Anything else? (optional)"),
                  text: $note, axis: .vertical)
            .lineLimit(2...4)
            .focused($noteFocused)
            .font(Theme.Typography.body)
            .padding(Theme.Spacing.md)
            .background(Theme.Palette.surface, in: .rect(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.Palette.hairline)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var buttons: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button {
                dismiss()
            } label: {
                Text("Skip")
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Theme.Palette.surfaceMuted, in: .capsule)
            }

            Button(action: send) {
                Text("Send")
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Palette.onInk)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(reason == nil ? Theme.Palette.ink.opacity(0.25) : Theme.Palette.ink,
                                in: .capsule)
            }
            .disabled(reason == nil)
        }
        .buttonStyle(.plain)
    }

    private var thanks: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Text("🙏").font(.system(size: 56))
            Text("Thank you!")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Text("We read every answer.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private func send() {
        guard let reason else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        RemovalFeedbackStore.record(RemovalFeedback(
            templateID: target.templateID,
            widgetName: target.name,
            reason: reason,
            note: trimmed.isEmpty ? nil : String(trimmed.prefix(500)),
            daysInstalled: target.daysInstalled
        ))
        noteFocused = false
        sent = true
        Task {
            try? await Task.sleep(for: .milliseconds(1_200))
            dismiss()
        }
    }
}

extension View {
    /// Shows the removal survey for `target`, if set.
    func removalSurvey(_ target: Binding<RemovalSurveyTarget?>) -> some View {
        sheet(item: target) { RemovalSurveySheet(target: $0).kareMacScaled() }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        RemovalSurveySheet(target: .init(templateID: "t-aurora", name: "Aurora", daysInstalled: 3))
    }
}
