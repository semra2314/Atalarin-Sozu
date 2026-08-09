//
//  SettingsView.swift
//  Widgy
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(OnboardingKeys.completed) private var completed = false
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @AppStorage(OnboardingKeys.username) private var username = ""

    private var name: String { displayName.isEmpty ? "You" : displayName }

    private struct Row: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
    }

    private let rows: [Row] = [
        Row(icon: "person", title: "Account"),
        Row(icon: "bell", title: "Notifications"),
        Row(icon: "paintpalette", title: "Appearance"),
        Row(icon: "lock", title: "Privacy"),
        Row(icon: "questionmark.circle", title: "Help & Support")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                header
                identity
                settingsCard
                logOut
                footer
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .background(Theme.Palette.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(Theme.Palette.ink)
            Circle()
                .fill(Theme.Palette.surfaceMuted)
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "person.fill").font(.footnote).foregroundStyle(Theme.Palette.subtleText))
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
    }

    private var identity: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Theme.Palette.surfaceMuted)
                .frame(width: 92, height: 92)
                .overlay(Image(systemName: "person.fill").font(.system(size: 36)).foregroundStyle(Theme.Palette.subtleText))
                .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 4))
                .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)

            VStack(spacing: 2) {
                Text(name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Free plan")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                settingRow(row)
                if index < rows.count - 1 {
                    Rectangle().fill(Theme.Palette.hairline).frame(height: 0.5).padding(.leading, 68)
                }
            }
        }
        .widgyCard()
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func settingRow(_ row: Row) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: row.icon)
                .font(.body)
                .foregroundStyle(Theme.Palette.ink)
                .frame(width: 40, height: 40)
                .background(Theme.Palette.surfaceMuted, in: .circle)
            Text(row.title)
                .font(Theme.Typography.bodyLarge)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.subtleText)
        }
        .padding(Theme.Spacing.lg)
        .contentShape(.rect)
    }

    private var logOut: some View {
        Button {
            withAnimation {
                displayName = ""
                username = ""
                completed = false   // returns to onboarding via RootGate (sign-in, slides skipped)
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
            }
            .font(Theme.Typography.title)
            .foregroundStyle(Theme.Palette.ink)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Image("WidgyWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .opacity(0.5)
            Text("VERSION 1.0.0 (2026)")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.Palette.subtleText.opacity(0.6))
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
