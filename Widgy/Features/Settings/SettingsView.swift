//
//  SettingsView.swift
//  Kare
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage(OnboardingKeys.completed) private var completed = false
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @AppStorage(OnboardingKeys.username) private var username = ""
    @AppStorage(OnboardingKeys.hasAccount) private var hasAccount = false

    private var name: String { displayName.isEmpty ? "You" : displayName }

    @State private var showEditProfile = false
    @State private var showLanguagePicker = false
    @State private var showAppearancePicker = false
    @State private var showKarePlus = false
    @State private var showAddGuide = false
    @State private var confirmDelete = false
    @State private var askPassword = false
    @State private var password = ""
    @State private var deleting = false
    @State private var deleteError: String?
    @Environment(\.subscriptions) private var subscriptions
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(OnboardingKeys.language) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .system }
    @AppStorage(OnboardingKeys.appearance) private var appearanceRaw = AppAppearance.system.rawValue
    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceRaw) ?? .system }

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
            case chooseAppearance
            case addWidgetGuide
            case systemSettings
            case open(URL)
        }
    }

    private var rows: [Row] {
        [
            Row(icon: "person", title: "Account",
                detail: username.isEmpty ? nil : "@" + username, action: .editProfile),
            // The add-to-home guide otherwise appears once, after the first
            // save, and is gone forever. This is the one instruction in the app
            // people come back needing, so it gets a permanent door.
            Row(icon: "plus.square.on.square", title: "How to add a widget",
                detail: "Home screen and lock screen", action: .addWidgetGuide),
            Row(icon: "globe", title: "Language",
                detail: language.displayName, action: .chooseLanguage),
            Row(icon: "circle.lefthalf.filled", title: "Appearance",
                detail: appearance.displayName, action: .chooseAppearance),
            Row(icon: "bell", title: "Notifications", action: .systemSettings),
            // These two used to open the phone's Settings app, which has
            // neither our privacy policy nor any way to reach us.
            Row(icon: "lock", title: "Privacy", action: .open(KarePlus.privacyURL)),
            Row(icon: "questionmark.circle", title: "Help & Support",
                action: .open(URL(string: "https://kare.erdendereli.com/support")!))
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                header
                identity
                karePlusCard
                settingsCard
                logOut
                if hasAccount { deleteAccount }
                footer
            }
            .padding(.bottom, Theme.Spacing.lg)
            .kareReadableWidth()
        }
        .kareTabBarInset()
        .background(Theme.Palette.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditProfile) { EditProfileView().kareMacScaled() }
        // Full screen, not a sheet: on iPad and Mac a sheet is a small
        // card that showed one plan and hid the other two below the fold.
        .fullScreenCover(isPresented: $showKarePlus) { KarePlusView().kareMacScaled() }
        .sheet(isPresented: $showAddGuide) {
            AddToHomeGuide(isCelebration: false)
        }
        .sheet(isPresented: $showLanguagePicker) {
            languageSheet.presentationDetents([.height(340)])
        }
        .sheet(isPresented: $showAppearancePicker) {
            appearanceSheet.presentationDetents([.height(320)])
        }
        .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                if AuthService.isAppleAccount {
                    runDelete(password: nil)
                } else {
                    password = ""
                    askPassword = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account and your reviews are deleted for good. Widgets on this phone stay. Kare+ is billed by Apple, so cancel it in Settings if you have it.")
        }
        .alert("Enter your password", isPresented: $askPassword) {
            SecureField("Password", text: $password)
            Button("Delete account", role: .destructive) { runDelete(password: password) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To keep your account safe, confirm it's you.")
        }
        .alert(deleteError ?? "", isPresented: Binding(
            get: { deleteError != nil }, set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
        .overlay {
            if deleting {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .padding(Theme.Spacing.xl)
                        .background(Theme.Palette.surface, in: .rect(cornerRadius: 20, style: .continuous))
                }
            }
        }
    }

    private var deleteAccount: some View {
        Button {
            confirmDelete = true
        } label: {
            Text("Delete account")
                .font(Theme.Typography.label)
                .foregroundStyle(Color.red)
        }
        .buttonStyle(.plain)
        .disabled(deleting)
    }

    private func runDelete(password: String?) {
        deleting = true
        Task {
            defer { deleting = false }
            do {
                try await AuthService.deleteAccount(password: password)
                signOutLocally()
            } catch AuthFailure.cancelled {
                // Closed the Apple sheet: nothing happened, nothing to say.
            } catch {
                deleteError = error.localizedDescription
            }
        }
    }

    /// Forgets who was signed in on this phone and goes back to sign-in.
    private func signOutLocally() {
        withAnimation {
            displayName = ""
            username = ""
            hasAccount = false
            completed = false
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
                    .accessibilityLabel(Text("Edit profile"))
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
                Text(subscriptions.isSubscribed ? "Kare+ member" : "Free plan")
                    .font(Theme.Typography.body)
                    .foregroundStyle(subscriptions.isSubscribed ? Theme.Palette.accent : Theme.Palette.subtleText)
            }
        }
    }

    /// Kare+ girişi. Abonelik iş modelinin ürün içindeki karşılığı, o yüzden
    /// ayarların derinlerine gömmek yerine kimliğin hemen altında duruyor.
    ///
    /// This card is always on screen. It was briefly hidden while the products
    /// did not exist, which solved the dead paywall but took the whole idea of
    /// Kare+ out of the app: testers had no way to know there was a paid tier
    /// at all, and that is the thing we most need them to have an opinion
    /// about. It stays, and the state it shows is the honest one.
    private var karePlusCard: some View {
        Button {
            // Only opens the paywall when there is something to sell. Until
            // then the card is a statement, not a door into an empty room.
            if subscriptions.canOfferSubscription { showKarePlus = true }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.Palette.accent)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: subscriptions.isSubscribed ? "checkmark" : "plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Kare+")
                        .font(Theme.Typography.headlineSmall)
                        .foregroundStyle(Theme.Palette.ink)
                    karePlusSubtitle
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                    // With large text there is no room beside the title, so
                    // the price moves under it instead of squeezing both.
                    if typeSize.isAccessibilitySize { karePlusPrice.padding(.top, 2) }
                }

                Spacer(minLength: 0)

                if !typeSize.isAccessibilitySize { karePlusPrice }

                if subscriptions.canOfferSubscription {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }
            .padding(Theme.Spacing.lg)
            .kareCard()
            .padding(.horizontal, Theme.Spacing.lg)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var karePlusPrice: some View {
                if !subscriptions.canOfferSubscription {
                    Text("Soon")
                        .font(Theme.Typography.labelCaps)
                        .foregroundStyle(Theme.Palette.subtleText)
                } else if !subscriptions.isSubscribed, let price = subscriptions.monthlyDisplayPrice {
                    // The real monthly price for this storefront, or nothing at
                    // all until StoreKit has answered. A placeholder here would
                    // be a number we invented sitting next to a Subscribe flow
                    // that charges something else.
                    Text("\(price)/mo")
                        .font(Theme.Typography.labelCaps)
                        .foregroundStyle(Theme.Palette.accent)
                        .fixedSize()
                }
    }

    /// Three states, three sentences. During the beta it says the paid designs
    /// are already free rather than teasing something nobody can buy.
    @ViewBuilder
    private var karePlusSubtitle: some View {
        if subscriptions.isSubscribed {
            Text("Active. Every paid widget is yours.")
        } else if subscriptions.canOfferSubscription {
            Text("Every paid widget, one subscription.")
        } else {
            Text("Coming soon. Paid widgets are free for now.")
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
        .kareCard()
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
                Text(LocalizedStringKey(row.title))
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.ink)
                if let detail = row.detail {
                    // A key that isn't in the catalogue renders as itself, so
                    // this is safe for the dynamic details (@username) too.
                    Text(LocalizedStringKey(detail))
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
                            Text(LocalizedStringKey(option.displayName))
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
            .kareCard()
            .padding(Theme.Spacing.lg)

            Text("Widgets on your home screen follow this language too.")
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

    private var appearanceSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(Array(AppAppearance.allCases.enumerated()), id: \.element.id) { index, option in
                    Button {
                        appearanceRaw = option.rawValue
                        showAppearancePicker = false
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: option.icon)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.Palette.subtleText)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            Text(LocalizedStringKey(option.displayName))
                                .font(Theme.Typography.bodyLarge)
                                .foregroundStyle(Theme.Palette.ink)
                            Spacer()
                            if appearance == option {
                                Image(systemName: "checkmark")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Theme.Palette.accent)
                            }
                        }
                        .padding(Theme.Spacing.lg)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(appearance == option ? .isSelected : [])

                    if index < AppAppearance.allCases.count - 1 {
                        Divider().padding(.leading, Theme.Spacing.lg)
                    }
                }
            }
            .kareCard()
            .padding(Theme.Spacing.lg)

            Spacer()
        }
        .background(Theme.Palette.background)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func perform(_ action: Row.Action) {
        switch action {
        case .editProfile:
            showEditProfile = true
        case .chooseLanguage:
            showLanguagePicker = true
        case .chooseAppearance:
            showAppearancePicker = true
        case .addWidgetGuide:
            showAddGuide = true
        case .systemSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case let .open(url):
            UIApplication.shared.open(url)
        }
    }

    private var logOut: some View {
        Button {
            AuthService.signOut()
            withAnimation {
                displayName = ""
                username = ""
                // Cleared with the rest of the identity. Leaving it set would
                // let the next person through onboarding as a guest and still
                // find the review composer unlocked.
                hasAccount = false
                completed = false   // returns to onboarding via RootGate (sign-in, slides skipped)
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                // A guest never logged in, so offering to log them out names
                // something that did not happen.
                Text(hasAccount ? "Log Out" : "Start over")
            }
            .font(Theme.Typography.title)
            .foregroundStyle(Theme.Palette.ink)
        }
        .buttonStyle(.plain)
    }

    /// Read from the bundle, so the footer never disagrees with the App Store.
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Image("KareWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
                .opacity(0.5)
            Text(verbatim: "VERSION \(appVersion)")
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
