//
//  OnboardingView.swift
//  Widgy
//
//  First impression + first-run flow: brand splash -> value slides -> taste
//  picker -> Sign in with Apple. On completion it flips the AppStorage flag and
//  RootGate reveals the app.
//

import SwiftUI
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

struct OnboardingView: View {
    @AppStorage(OnboardingKeys.completed) private var completed = false
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @AppStorage(OnboardingKeys.username) private var storedUsername = ""
    @AppStorage(OnboardingKeys.aesthetics) private var aesthetics = ""

    private enum Step { case language, slides, taste, signIn, username }
    @State private var step: Step
    @State private var selected: Set<String> = []
    @State private var showSplash = true
    @State private var authMessage: String?

    init() {
        let defaults = UserDefaults.standard
        // Returning users (logged out) skip the intro and go straight to sign-in.
        let before = defaults.bool(forKey: OnboardingKeys.hasOnboardedBefore)
        let chosenLanguage = defaults.bool(forKey: OnboardingKeys.languageChosen)

        // Language comes first, before any copy the user has to read: asking
        // in a language they may not speak is the wrong way round. Only ever
        // shown once, and never to someone who's onboarded before.
        if !before && !chosenLanguage {
            _step = State(initialValue: .language)
        } else {
            _step = State(initialValue: before ? .signIn : .slides)
        }
    }

    // Captured during auth, saved once the username is chosen.
    @State private var pendingName = ""
    @State private var username = ""

    var body: some View {
        ZStack {
            Theme.Palette.background.ignoresSafeArea()

            switch step {
            case .language:
                LanguageStep { step = .slides }
            case .slides:
                SlidesStep(onContinue: { step = .taste }, onSkip: { step = .signIn })
            case .taste:
                TasteStep(selected: $selected, onContinue: { step = .signIn })
            case .signIn:
                SignInStep(message: authMessage,
                           onApple: handleApple,
                           onEmailComplete: { name in advanceToUsername(name: name) },
                           onSkip: { advanceToUsername(name: "") })
            case .username:
                UsernameStep(suggested: suggestedUsername,
                             username: $username,
                             onDone: complete)
            }

            if showSplash {
                SplashOverlay()
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(for: .milliseconds(1300))
                        withAnimation(.easeOut(duration: 0.4)) { showSplash = false }
                    }
            }
        }
    }

    private var suggestedUsername: String {
        let base = pendingName.isEmpty ? "widgyfan" : pendingName
        return base.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == " " }
            .replacingOccurrences(of: " ", with: "_")
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(auth):
            if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                let name = [cred.fullName?.givenName, cred.fullName?.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                advanceToUsername(name: name)
            } else {
                advanceToUsername(name: "")
            }
        case .failure:
            authMessage = "Couldn't sign in. Try again, or continue for now."
        }
    }

    private func advanceToUsername(name: String) {
        pendingName = name
        withAnimation(.easeInOut) { step = .username }
    }

    private func complete() {
        displayName = pendingName.isEmpty ? "You" : pendingName
        let clean = username.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
        storedUsername = clean.isEmpty ? "you" : clean
        aesthetics = selected.sorted().joined(separator: ",")
        UserDefaults.standard.set(true, forKey: OnboardingKeys.hasOnboardedBefore)
        withAnimation(.easeInOut) { completed = true }
    }
}

// MARK: - Language

/// The first thing a new user sees, before any copy they'd have to read.
///
/// Each option is written in its own language — "Türkçe", "English" — rather
/// than translated into the current one. Someone who doesn't read the current
/// language still has to be able to find theirs.
private struct LanguageStep: View {
    var onContinue: () -> Void

    @AppStorage(OnboardingKeys.language) private var languageRaw = AppLanguage.system.rawValue
    @AppStorage(OnboardingKeys.languageChosen) private var languageChosen = false
    @State private var selection: AppLanguage = .system

    /// Start on whatever the phone is already set to, so most people just
    /// confirm rather than choose.
    private var deviceDefault: AppLanguage {
        (Locale.current.language.languageCode?.identifier == "tr") ? .turkish : .english
    }

    private let options: [AppLanguage] = [.turkish, .english]

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Image(systemName: "globe")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.Palette.accent)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Dilini seç")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Choose your language")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: Theme.Spacing.md) {
                ForEach(options) { option in
                    Button {
                        withAnimation(.snappy) { selection = option }
                    } label: {
                        HStack {
                            Text(option == .turkish ? "Türkçe" : "English")
                                .font(Theme.Typography.title)
                                .foregroundStyle(Theme.Palette.ink)
                            Spacer()
                            Image(systemName: selection == option ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selection == option
                                                 ? Theme.Palette.accent : Theme.Palette.hairline)
                        }
                        .padding(Theme.Spacing.lg)
                        .background(Theme.Palette.surface, in: .rect(cornerRadius: Theme.Radius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.card)
                                .stroke(selection == option ? Theme.Palette.accent : Theme.Palette.hairline,
                                        lineWidth: selection == option ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            Button {
                languageRaw = selection.rawValue
                languageChosen = true
                onContinue()
            } label: {
                Text(selection == .turkish ? "Devam et" : "Continue")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Theme.Palette.accent, in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .task { selection = deviceDefault }
    }
}

// MARK: - Splash

private struct SplashOverlay: View {
    @State private var shown = false
    var body: some View {
        ZStack {
            Theme.Palette.background.ignoresSafeArea()
            Image("WidgyWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .opacity(shown ? 1 : 0)
                .scaleEffect(shown ? 1 : 0.94)
                .onAppear { withAnimation(.spring(duration: 0.6).delay(0.15)) { shown = true } }
        }
    }
}

// MARK: - Slides

private struct SlidesStep: View {
    var onContinue: () -> Void
    var onSkip: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip", action: onSkip)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)

            TabView(selection: $page) {
                slide(visual: DualWidgetHero(),
                      title: "Ready-made widgets,\nbeautifully done",
                      subtitle: "Experience the ease of professional customization with our curated collection of widgets designed for your home screen.").tag(0)

                slide(visual: EditHero(),
                      title: "Make them\nyours",
                      subtitle: "Change the text, colours, fonts and stickers. Add your own photo in a tap.").tag(1)

                slide(visual: PhoneHero(),
                      title: "On your home\nscreen in seconds",
                      subtitle: "Design it, save it, and add it straight to your home screen.").tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.snappy, value: page)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.Palette.accent : Theme.Palette.hairline)
                        .frame(width: index == page ? 22 : 8, height: 8)
                        .animation(.snappy, value: page)
                }
            }
            .padding(.vertical, Theme.Spacing.lg)

            Button {
                if page < 2 { withAnimation { page += 1 } } else { onContinue() }
            } label: {
                Text(page < 2 ? "Next" : "Get Started")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Theme.Palette.accent, in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
        }
    }

    private func slide(visual: some View, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.Palette.accentTint)
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                visual.modifier(Floating())
            }
            .frame(height: 320)
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(title)
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
                Text(subtitle)
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

// MARK: - Slide heroes

private struct DualWidgetHero: View {
    var body: some View {
        ZStack {
            purpleCard
                .rotationEffect(.degrees(-5))
                .offset(x: -46, y: -22)
            darkCard
                .rotationEffect(.degrees(5))
                .offset(x: 46, y: 30)
        }
    }

    private var purpleCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: "A78BFA"), Color(hex: "7C3AED")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.22)).frame(width: 26, height: 26)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            Text("Good\nmorning")
                .font(AppFont.serif(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(2)
                .padding(18)
        }
        .frame(width: 168, height: 168)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .shadow(color: Color(hex: "7C3AED").opacity(0.35), radius: 22, y: 12)
    }

    private var darkCard: some View {
        ZStack(alignment: .leading) {
            Color(hex: "1D1D1F")
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("Deep work")
                        .font(AppFont.sans(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    Circle().fill(Theme.Palette.accent).frame(width: 8, height: 8)
                }
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule().fill(.white.opacity(0.45)).frame(width: 82)
                }
                .frame(width: 122, height: 5)
            }
            .padding(20)
        }
        .frame(width: 168, height: 168)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 22, y: 12)
    }
}

/// Gentle continuous float for onboarding hero art. Respects reduce-motion.
private struct Floating: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .offset(y: up ? -7 : 7)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                    up = true
                }
            }
    }
}

private struct EditHero: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image("focus_widget")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 168, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            HStack(spacing: Theme.Spacing.md) {
                ForEach(["d44a33", "7C3AED", "1D1D1F", "2A6F97"], id: \.self) { hex in
                    Circle().fill(Color(hex: hex)).frame(width: 26, height: 26)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
                Text("Aa")
                    .font(AppFont.serif(size: 15, weight: .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(width: 34, height: 26)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Palette.surface, in: .capsule)
            .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
        }
    }
}

private struct PhoneHero: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "EFE9E7"), Color(hex: "E2DAD8")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 182, height: 300)
                .overlay(RoundedRectangle(cornerRadius: 44, style: .continuous).stroke(Theme.Palette.hairline, lineWidth: 1))
            Image("aurora_widget")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .offset(y: -34)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.5))
                .frame(width: 150, height: 46)
                .offset(y: 112)
        }
    }
}

// MARK: - Taste

private struct TasteStep: View {
    @Binding var selected: Set<String>
    var onContinue: () -> Void

    private let options = ["Minimal", "Bold", "Playful", "Dark"]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("What's your\nstyle?")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Pick a vibe or two. We'll tune your Discover feed.")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.md),
                                    GridItem(.flexible(), spacing: Theme.Spacing.md)],
                          spacing: Theme.Spacing.md) {
                    ForEach(options, id: \.self) { style in
                        tasteCard(style)
                    }
                }
                .padding(.bottom, Theme.Spacing.sm)
            }
            .scrollIndicators(.hidden)

            Button(action: onContinue) {
                Text("Continue")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .background(selected.isEmpty ? Theme.Palette.subtleText : Theme.Palette.accent, in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(selected.isEmpty)
        }
        .padding(Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xxl)
    }

    private func tasteCard(_ style: String) -> some View {
        let isOn = selected.contains(style)
        return Button {
            withAnimation(.snappy) {
                if isOn { selected.remove(style) } else { selected.insert(style) }
            }
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ZStack(alignment: .topTrailing) {
                    StyleThumbnail(style: style)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Theme.Palette.accent, in: .circle)
                            .padding(8)
                    }
                }
                Text(style)
                    .font(Theme.Typography.headlineSmall)
                    .foregroundStyle(Theme.Palette.ink)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surface, in: .rect(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isOn ? Theme.Palette.accent : Theme.Palette.hairline, lineWidth: isOn ? 2 : 1)
            )
            .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
        }
        .buttonStyle(.plain)
    }
}

/// The little vibe preview inside each taste card.
private struct StyleThumbnail: View {
    let style: String

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(fill)
            .overlay(overlay)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.Palette.hairline, lineWidth: style == "Minimal" ? 1 : 0)
            )
    }

    private var fill: AnyShapeStyle {
        switch style {
        case "Bold", "Dark":
            return AnyShapeStyle(Color(hex: "1D1D1F"))
        case "Playful":
            return AnyShapeStyle(LinearGradient(colors: [Color(hex: "D8CBFB"), Color(hex: "C2B6F5")],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        default: // Minimal
            return AnyShapeStyle(Color(hex: "F7F3F2"))
        }
    }

    @ViewBuilder private var overlay: some View {
        switch style {
        case "Minimal":
            Capsule().fill(Theme.Palette.hairline).frame(width: 54, height: 3)
        case "Bold":
            ZStack(alignment: .bottomTrailing) {
                // Artwork inside a style swatch, not copy — `verbatim` keeps it
                // out of the string catalog, where it also collided with the
                // "Bold" font-weight label.
                Text(verbatim: "BOLD")
                    .font(AppFont.serif(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Circle().fill(Theme.Palette.accent).frame(width: 8, height: 8).padding(12)
            }
        case "Playful":
            Capsule().fill(.white)
                .frame(width: 62, height: 30)
                .overlay(
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "4C7DF0")).frame(width: 9, height: 9)
                        Circle().fill(Color(hex: "9B5DE5")).frame(width: 9, height: 9)
                    }
                )
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        case "Dark":
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                Capsule().fill(.white.opacity(0.35)).frame(width: 60, height: 5)
                Capsule().fill(.white.opacity(0.22)).frame(width: 40, height: 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(16)
        default:
            EmptyView()
        }
    }
}

// MARK: - Sign in

private struct SignInStep: View {
    var message: String?
    var onApple: (Result<ASAuthorization, Error>) -> Void
    var onEmailComplete: (String) -> Void
    var onSkip: () -> Void

    @State private var path = NavigationPath()
    private enum Route: Hashable { case signUp, login }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .signUp: EmailSignUpView(onComplete: onEmailComplete)
                    case .login: EmailLoginView(onComplete: onEmailComplete)
                    }
                }
        }
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image("WidgyWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 170)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Create your account")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Sign in once so your widgets and library follow you everywhere.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            if let message {
                Text(message)
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    onApple(result.mapError { $0 as Error })
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .clipShape(.capsule)

                Button {
                    path.append(Route.signUp)
                } label: {
                    Text("Sign up with email")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Theme.Palette.surface, in: .capsule)
                        .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(Theme.Palette.subtleText)
                    Button("Log in") { path.append(Route.login) }
                        .foregroundStyle(Theme.Palette.accent)
                }
                .font(Theme.Typography.label)
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Button("Continue without account", action: onSkip)
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Palette.subtleText)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .background(Theme.Palette.background)
    }
}

// MARK: - Email auth pages

/// Small styled field used by the email forms.
private struct AuthField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var secure = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title).widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            Group {
                if secure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(Theme.Typography.bodyLarge)
            .padding(Theme.Spacing.md)
            .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
        }
    }
}

// MARK: - Username

private struct UsernameStep: View {
    var suggested: String
    @Binding var username: String
    var onDone: () -> Void

    private var cleaned: String {
        username.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
    }
    private var valid: Bool { cleaned.count >= 3 && cleaned.count <= 20 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Pick a\nusername")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
                Text("This is how you'll appear in Widgy. You can change it later.")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            HStack(spacing: Theme.Spacing.xs) {
                Text("@")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.subtleText)
                TextField("username", text: $username)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(valid ? Theme.Palette.accent : Theme.Palette.hairline, lineWidth: valid ? 2 : 1)
            )

            Text(valid ? "Looks good." : "3-20 letters, numbers or underscores.")
                .font(Theme.Typography.label)
                .foregroundStyle(valid ? Theme.Palette.accent : Theme.Palette.subtleText)

            Spacer()

            Button {
                username = cleaned
                onDone()
            } label: {
                Text("Enter Widgy")
                    .font(Theme.Typography.title).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .background(valid ? Theme.Palette.accent : Theme.Palette.subtleText, in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(!valid)
        }
        .padding(Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xxl)
        .onAppear { if username.isEmpty { username = suggested } }
    }
}

private struct EmailSignUpView: View {
    var onComplete: (String) -> Void
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && email.contains("@") && email.contains(".")
        && password.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                Text("Sign up")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)

                VStack(spacing: Theme.Spacing.lg) {
                    AuthField(title: "Name", placeholder: "Alex Mercer", text: $name)
                    AuthField(title: "Email", placeholder: "you@email.com", text: $email, keyboard: .emailAddress)
                    AuthField(title: "Password", placeholder: "At least 6 characters", text: $password, secure: true)
                }

                Button {
                    onComplete(name.trimmingCharacters(in: .whitespaces))
                } label: {
                    Text("Create account")
                        .font(Theme.Typography.title).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(valid ? Theme.Palette.accent : Theme.Palette.subtleText, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(!valid)
            }
            .padding(Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EmailLoginView: View {
    var onComplete: (String) -> Void
    @State private var email = ""
    @State private var password = ""

    private var valid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                Text("Welcome\nback")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)

                VStack(spacing: Theme.Spacing.lg) {
                    AuthField(title: "Email", placeholder: "you@email.com", text: $email, keyboard: .emailAddress)
                    AuthField(title: "Password", placeholder: "Your password", text: $password, secure: true)
                }

                Button {
                    let handle = email.split(separator: "@").first.map(String.init) ?? "You"
                    onComplete(handle.capitalized)
                } label: {
                    Text("Log in")
                        .font(Theme.Typography.title).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(valid ? Theme.Palette.accent : Theme.Palette.subtleText, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(!valid)
            }
            .padding(Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Log in")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    OnboardingView()
}
