//
//  SettingsView.swift
//  Widgy
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage(OnboardingKeys.completed) private var completed = false
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @AppStorage(OnboardingKeys.username) private var username = ""

    private var name: String { displayName.isEmpty ? "You" : displayName }

    @State private var showEditProfile = false
    @State private var showLanguagePicker = false
    @AppStorage(OnboardingKeys.language) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .system }

    private struct Row: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        /// A short line under the title, where one helps.
        var detail: String?
        let action: Action

        enum Action {
            case editProfile
            case chooseLanguage
            case systemSettings
        }
    }

    private var rows: [Row] {
        [
            Row(icon: "person", title: String(localized: "Account"),
                detail: username.isEmpty ? nil : "@" + username, action: .editProfile),
            Row(icon: "globe", title: String(localized: "Language"),
                detail: language.displayName, action: .chooseLanguage),
            Row(icon: "bell", title: String(localized: "Notifications"), action: .systemSettings),
            Row(icon: "lock", title: String(localized: "Privacy"), action: .systemSettings),
            Row(icon: "questionmark.circle", title: String(localized: "Help & Support"),
                action: .systemSettings)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                header
                identity
                settingsCard
                logOut
                footer
            }
            .padding(.bottom, Theme.Spacing.lg)
        }
        .widgyTabBarInset()
        .background(Theme.Palette.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
        .sheet(isPresented: $showLanguagePicker) {
            languageSheet.presentationDetents([.height(340)])
        }
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            Button {
                showEditProfile = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.body)
                    .foregroundStyle(Theme.Palette.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
    }

    private var identity: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ProfileAvatar(size: 92)

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
                Button { perform(row.action) } label: { settingRow(row) }
                    .buttonStyle(.plain)
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
            VStack(alignment: .leading, spacing: 1) {
                Text(row.title)
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.ink)
                if let detail = row.detail {
                    Text(detail)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.subtleText)
        }
        .padding(Theme.Spacing.lg)
        .contentShape(.rect)
    }

    private var languageSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, option in
                    Button {
                        languageRaw = option.rawValue
                        showLanguagePicker = false
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .font(Theme.Typography.bodyLarge)
                                .foregroundStyle(Theme.Palette.ink)
                            Spacer()
                            if language == option {
                                Image(systemName: "checkmark")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Theme.Palette.accent)
                            }
                        }
                        .padding(Theme.Spacing.lg)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)

                    if index < AppLanguage.allCases.count - 1 {
                        Divider().padding(.leading, Theme.Spacing.lg)
                    }
                }
            }
            .widgyCard()
            .padding(Theme.Spacing.lg)

            Text("Widgets on your home screen follow your phone's language.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
        .background(Theme.Palette.background)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func perform(_ action: Row.Action) {
        switch action {
        case .editProfile:
            showEditProfile = true
        case .chooseLanguage:
            showLanguagePicker = true
        case .systemSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
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
