//
//  ExhaleSetupView.swift
//  Kare
//
//  Where the Exhale widget gets its quit date and its numbers. Saving writes
//  into the App Group and reloads the widget.
//

import SwiftUI
import UIKit

struct ExhaleSetupView: View {
    @State private var plan: QuitPlan = .starting()
    /// What is on the widget right now. The button says "Saved" only while
    /// the form still matches it, so an edit is never mistaken for saved.
    @State private var lastSaved: QuitPlan?
    @State private var isBreathing = false
    @State private var confirmRestart = false
    @State private var showAddToHome = false

    /// Advanced every minute so the preview's numbers move while it is open.
    @State private var now = Date.now

    private var hasSavedPlan: Bool { lastSaved != nil }
    private var justSaved: Bool { lastSaved == plan }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                preview
                nowCard
                form
                saveButton
                moneyCard
                milestones
                if hasSavedPlan { restartSection }
                note
            }
            .kareReadableWidth()
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Exhale")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            load()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                now = .now
            }
        }
        .confirmationDialog("Start the count again?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Start over from now", role: .destructive) { restart() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A slip is part of quitting for most people. Your count starts again from this moment.")
        }
        .sheet(isPresented: $showAddToHome) {
            AddToHomeGuide(galleryName: "Exhale").presentationDetents([.large])
        }
    }

    // MARK: - Preview

    /// Tapping the lungs here does what tapping them on the home screen does.
    private var preview: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                breathe()
            } label: {
                LungsGauge(level: isBreathing ? 1 : plan.recovery(at: now))
                    .frame(height: 150)
            }
            .buttonStyle(.plain)

            Text(LocalizedStringKey(plan.stage(at: now).titleKey))
                .font(AppFont.serif(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Group {
                if isBreathing {
                    Text("Breathe in…")
                } else {
                    Text("Tap the lungs to take a breath")
                }
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: Theme.Spacing.xl) {
                previewStat(Text(plan.days(at: now), format: .number), label: "days")
                previewStat(Text(plan.moneyText(at: now)), label: "saved", color: Color(hex: "FDE68A"))
                previewStat(Text(plan.lifeRegainedText(at: now)), label: "won back")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
        .padding(.horizontal, Theme.Spacing.lg)
        .background {
            // The widget's own artwork for the current stage, once it exists.
            let stage = plan.stage(at: now)
            ZStack {
                LinearGradient(colors: stage.fallbackHexes.map { Color(hex: $0) },
                               startPoint: .top, endPoint: .bottom)
                if UIImage(named: stage.art) != nil {
                    Image(stage.art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.5)],
                               startPoint: .top, endPoint: .bottom)
            }
            .clipShape(.rect(cornerRadius: Theme.Radius.hero, style: .continuous))
        }
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
    }

    private func previewStat(_ value: Text, label: LocalizedStringKey, color: Color = .white) -> some View {
        VStack(spacing: 2) {
            value
                .font(AppFont.serif(size: 22, weight: .heavy))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    // MARK: - Form

    private var form: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Your numbers").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)

            VStack(spacing: 0) {
                DatePicker("Last cigarette", selection: $plan.quitDate, in: ...Date.now,
                           displayedComponents: [.date, .hourAndMinute])
                    .padding(Theme.Spacing.md)
                Divider().padding(.leading, Theme.Spacing.md)

                VStack(alignment: .leading, spacing: 4) {
                    Stepper(value: packsPerDay, in: 0.25...5, step: 0.25) {
                        row("Packs a day",
                            value: Text(packsPerDay.wrappedValue, format: .number.precision(.fractionLength(0...2))))
                    }
                    Text("That is \(Int(plan.dailyCigarettes.rounded())) cigarettes a day.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
                .padding(Theme.Spacing.md)
                Divider().padding(.leading, Theme.Spacing.md)

                Stepper(value: $plan.cigarettesPerPack, in: 10...40) {
                    row("In a pack", value: Text(plan.cigarettesPerPack, format: .number))
                }
                .padding(Theme.Spacing.md)
                Divider().padding(.leading, Theme.Spacing.md)

                HStack {
                    Text("Price of a pack")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Palette.ink)
                    Spacer()
                    TextField("0", value: $plan.packPrice,
                              format: .currency(code: plan.currencyCode))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(Theme.Typography.body)
                        .frame(maxWidth: 140)
                }
                .padding(Theme.Spacing.md)
            }
            .kareCard()
        }
    }

    /// Packs a day, as most people count. Quarter-pack steps, five
    /// cigarettes at a time in a 20-pack. Writing it also keeps
    /// `cigarettesPerDay` in step for anything that still reads it.
    private var packsPerDay: Binding<Double> {
        Binding(
            get: { plan.packsPerDay ?? plan.dailyCigarettes / Double(max(1, plan.cigarettesPerPack)) },
            set: { packs in
                plan.packsPerDay = packs
                plan.cigarettesPerDay = Int((packs * Double(plan.cigarettesPerPack)).rounded())
            }
        )
    }

    private func row(_ title: LocalizedStringKey, value: Text) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            value
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: justSaved ? "checkmark" : "lungs.fill")
                if justSaved {
                    Text("Saved to your widget")
                } else {
                    Text("Save to widget")
                }
            }
            .font(Theme.Typography.title)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.Palette.accent, in: .capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Now

    /// What the body is doing at this moment, and what comes next. The part
    /// people come back to the app for.
    @ViewBuilder private var nowCard: some View {
        let elapsed = plan.elapsed(at: now)
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if let current = plan.currentMilestone(at: now) {
                milestoneBlock(current, heading: "Right now in your body", tint: Color(hex: "10B981"))
            } else {
                milestoneBlock(QuitMilestone.all[0], heading: "In the first minutes", tint: Color(hex: "10B981"))
            }

            if let next = plan.nextMilestone(at: now) {
                Divider()
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text("Next").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)
                        Spacer()
                        Text("In \(next.remainingText(from: elapsed))")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Palette.subtleText)
                    }
                    Label {
                        Text(LocalizedStringKey(next.titleKey))
                            .font(Theme.Typography.cardTitle)
                            .foregroundStyle(Theme.Palette.ink)
                    } icon: {
                        Image(systemName: next.part.symbolName)
                            .foregroundStyle(Theme.Palette.subtleText)
                    }
                    ProgressView(value: next.progress(from: elapsed))
                        .tint(Color(hex: "10B981"))
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .kareCard()
    }

    private func milestoneBlock(_ milestone: QuitMilestone, heading: LocalizedStringKey, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(heading).kareCapsLabel().foregroundStyle(tint)
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: milestone.part.symbolName)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(tint, in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(milestone.titleKey))
                        .font(Theme.Typography.headlineSmall)
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(LocalizedStringKey(milestone.detailKey))
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Palette.subtleText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Money

    /// What smoking cost, turned around: what stays in the pocket now.
    private var moneyCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("In your pocket").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.moneyText(at: now))
                        .font(AppFont.serif(size: 36, weight: .heavy))
                        .foregroundStyle(Theme.Palette.ink)
                        .contentTransition(.numericText())
                    Text("kept since your last cigarette")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }

                Divider()

                moneyRow("Every day", amount: plan.dailyCost)
                moneyRow("Every month", amount: plan.dailyCost * 30.44)
                moneyRow("Every year", amount: plan.dailyCost * 365)

                Divider()

                HStack {
                    Label("Life won back", systemImage: "hourglass")
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Palette.ink)
                    Spacer()
                    Text(plan.lifeRegainedText(at: now))
                        .font(Theme.Typography.title)
                        .foregroundStyle(Color(hex: "10B981"))
                }
                Text("An estimate: about 20 minutes of life expectancy for every cigarette not smoked.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            .padding(Theme.Spacing.lg)
            .kareCard()
        }
    }

    private func moneyRow(_ title: LocalizedStringKey, amount: Double) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.cardTitle)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            Text(plan.money(amount))
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Palette.ink)
        }
    }

    // MARK: - Milestones

    private var milestones: some View {
        let elapsed = plan.elapsed(at: now)
        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("What your body is doing").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)

            VStack(spacing: 0) {
                ForEach(Array(QuitMilestone.all.enumerated()), id: \.element.id) { index, milestone in
                    let reached = elapsed >= milestone.after
                    let isNext = milestone == plan.nextMilestone(at: now)
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: milestone.part.symbolName)
                            .font(.footnote)
                            .foregroundStyle(reached ? .white : Theme.Palette.subtleText)
                            .frame(width: 30, height: 30)
                            .background(reached ? Color(hex: "10B981") : Theme.Palette.surfaceMuted,
                                        in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey(milestone.titleKey))
                                .font(Theme.Typography.cardTitle)
                                .foregroundStyle(reached || isNext ? Theme.Palette.ink : Theme.Palette.subtleText)
                            if isNext {
                                ProgressView(value: milestone.progress(from: elapsed))
                                    .tint(Color(hex: "10B981"))
                                    .padding(.vertical, 2)
                            }
                            Group {
                                if reached {
                                    Text("Done")
                                } else {
                                    Text("In \(milestone.remainingText(from: elapsed))")
                                }
                            }
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Palette.subtleText)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(Theme.Spacing.md)

                    if index < QuitMilestone.all.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .kareCard()

            Text("Health timeline from the World Health Organization and the NHS. Life won back is an estimate from University College London (2024). Kare is not medical advice; your doctor or a quit line can help you plan.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }

    // MARK: - Restart

    private var restartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                confirmRestart = true
            } label: {
                Label("Start over", systemImage: "arrow.counterclockwise")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.Palette.surface, in: .capsule)
                    .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if plan.restarts > 0 {
                Text("Every attempt counts. Most people who quit for good tried more than once.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
    }

    private var note: some View {
        Button {
            showAddToHome = true
        } label: {
            Text("How do I add it to my home screen?")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.accent)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func load() {
        if let saved = QuitStore.load() {
            plan = saved
            lastSaved = saved
        }
    }

    private func save() {
        var clean = plan
        clean.breathUntil = nil
        clean.resetArmedUntil = nil
        clean.packPrice = max(0, clean.packPrice)
        QuitStore.save(clean)
        withAnimation(.snappy) {
            plan = clean
            lastSaved = clean
        }
    }

    private func breathe() {
        withAnimation(.spring(duration: 1.2)) { isBreathing = true }
        Task {
            try? await Task.sleep(for: .seconds(QuitWidgetTiming.breath))
            withAnimation(.spring(duration: 1.4)) { isBreathing = false }
        }
    }

    private func restart() {
        QuitStore.restart()
        if let saved = QuitStore.load() {
            plan = saved
            lastSaved = saved
        }
        now = .now
    }
}

#Preview {
    NavigationStack { ExhaleSetupView() }
        .environment(\.appEnvironment, .preview)
}
