//
//  CountdownSetupView.swift
//  Kare
//
//  The list of countdowns the Countdown widget can show. Each placed widget
//  picks one of them from "Edit Widget" on the home screen.
//

import SwiftUI
import UIKit

struct CountdownSetupView: View {
    @State private var events: [CountdownEvent] = []
    @State private var editing: CountdownEvent?
    @State private var showAddToHome = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                if events.isEmpty {
                    empty
                } else {
                    list
                }
                addButton
                note
            }
            .kareReadableWidth()
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Countdown")
        .navigationBarTitleDisplayMode(.inline)
        .task { events = CountdownStore.all() }
        .sheet(item: $editing) { event in
            CountdownEditor(event: event) { saved in
                CountdownStore.upsert(saved)
                events = CountdownStore.all()
            } onDelete: { id in
                CountdownStore.delete(id: id)
                events = CountdownStore.all()
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showAddToHome) {
            AddToHomeGuide(galleryName: "Countdown").presentationDetents([.large])
        }
    }

    private var empty: some View {
        ContentUnavailableView {
            Label("No countdowns yet", systemImage: "calendar.badge.plus")
        } description: {
            Text("A trip, a wedding, an exam, a visit. Add the day you are waiting for.")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    private var list: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(events) { event in
                Button {
                    editing = event
                } label: {
                    CountdownCard(event: event)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var addButton: some View {
        Button {
            editing = CountdownEvent(
                title: "",
                date: Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now,
                theme: .trip
            )
        } label: {
            Label("New countdown", systemImage: "plus")
                .font(Theme.Typography.title)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.Palette.accent, in: .capsule)
        }
        .buttonStyle(.plain)
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Place more than one Countdown widget and choose a different countdown for each: touch and hold the widget, then Edit Widget.")
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

// MARK: - Card

private struct CountdownCard: View {
    let event: CountdownEvent

    var body: some View {
        let days = event.daysLeft()
        HStack(spacing: Theme.Spacing.md) {
            Text(event.emoji)
                .font(.system(size: 28))
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.15), in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title.isEmpty ? String(localized: "Untitled") : event.title)
                    .font(Theme.Typography.headlineSmall)
                    .lineLimit(1)
                Text(event.date, format: .dateTime.day().month(.wide).year())
                    .font(Theme.Typography.caption)
                    .opacity(0.75)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 0) {
                Text(max(0, days), format: .number)
                    .font(AppFont.serif(size: 30, weight: .heavy))
                Group {
                    if days == 0 { Text("today") } else if days < 0 { Text("passed") } else { Text("days") }
                }
                .font(Theme.Typography.caption)
                .opacity(0.75)
            }
        }
        .foregroundStyle(.white)
        .padding(Theme.Spacing.md)
        .background {
            ZStack {
                LinearGradient(colors: event.fallbackHexes.map { Color(hex: $0) },
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                // The same art as the widget, once it is in the asset catalogue.
                // The wide cut when there is one, the square art otherwise.
                if let art = event.theme?.art,
                   let name = [art + "-wide", art].first(where: { UIImage(named: $0) != nil }) {
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.45)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
        }
    }
}

// MARK: - Editor

private struct CountdownEditor: View {
    @State var event: CountdownEvent
    let onSave: (CountdownEvent) -> Void
    let onDelete: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    init(event: CountdownEvent,
         onSave: @escaping (CountdownEvent) -> Void,
         onDelete: @escaping (String) -> Void) {
        _event = State(initialValue: event)
        self.isExisting = CountdownStore.all().contains { $0.id == event.id }
        self.onSave = onSave
        self.onDelete = onDelete
    }

    /// Read once: whether this is an edit or a new countdown does not change
    /// while the sheet is open.
    private let isExisting: Bool

    private var canSave: Bool {
        !event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Picking a theme also swaps the emoji, unless the user already chose
    /// one of their own.
    private func themeButton(_ theme: CountdownTheme) -> some View {
        let selected = event.theme == theme
        return Button {
            withAnimation(.snappy) {
                let untouched = event.emoji.isEmpty
                    || CountdownTheme.allCases.contains { $0.emoji == event.emoji }
                event.theme = theme
                if untouched { event.emoji = theme.emoji }
            }
        } label: {
            VStack(spacing: 4) {
                Text(theme.emoji).font(.system(size: 22))
                Text(LocalizedStringKey(theme.displayName))
                    .font(Theme.Typography.caption)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                LinearGradient(colors: theme.fallbackHexes.map { Color(hex: $0) },
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Theme.Palette.accent : .clear, lineWidth: 3)
            }
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    CountdownCard(event: event)

                    VStack(spacing: 0) {
                        HStack(spacing: Theme.Spacing.md) {
                            TextField("🎉", text: $event.emoji)
                                .font(.system(size: 26))
                                .multilineTextAlignment(.center)
                                .frame(width: 52, height: 52)
                                .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: 14))
                                .onChange(of: event.emoji) { _, value in
                                    // One emoji, not a sentence.
                                    if let last = value.last, value.count > 1 {
                                        event.emoji = String(last)
                                    }
                                }
                            TextField("What are you waiting for?", text: $event.title)
                                .font(Theme.Typography.bodyLarge)
                                .submitLabel(.done)
                        }
                        .padding(Theme.Spacing.md)

                        Divider().padding(.leading, Theme.Spacing.md)

                        DatePicker("Date", selection: $event.date, displayedComponents: .date)
                            .padding(Theme.Spacing.md)
                    }
                    .kareCard()

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Style").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)
                        Picker("Style", selection: $event.style) {
                            ForEach(CountdownStyle.allCases) { style in
                                Label(LocalizedStringKey(style.displayName), systemImage: style.symbolName)
                                    .tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("What is it for?").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Theme.Spacing.sm)],
                                  spacing: Theme.Spacing.sm) {
                            ForEach(CountdownTheme.allCases) { theme in
                                themeButton(theme)
                            }
                        }
                    }

                    if isExisting {
                        Button(role: .destructive) {
                            onDelete(event.id)
                            dismiss()
                        } label: {
                            Label("Delete countdown", systemImage: "trash")
                                .font(Theme.Typography.label)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.xl)
            }
            .background(Theme.Palette.background)
            .navigationTitle(isExisting ? Text("Edit countdown") : Text("New countdown"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var clean = event
                        clean.title = clean.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if clean.emoji.isEmpty { clean.emoji = "🎉" }
                        onSave(clean)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CountdownSetupView() }
        .environment(\.appEnvironment, .preview)
}
