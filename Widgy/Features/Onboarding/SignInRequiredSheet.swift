//
//  SignInRequiredSheet.swift
//  Kare
//
//  Shown when a guest reaches something that needs an account.
//
//  Kare opens without an account on purpose, so this is the other half of that
//  decision: the moment the account starts to mean something, we ask for it,
//  and we say which thing asked. A prompt that only says "sign in required"
//  makes the app look like it is collecting people. Naming the reason makes it
//  an answer to a question the user just asked themselves.
//
//  Nothing is lost by accepting. The widget library lives in SwiftData and
//  survives the trip through onboarding, so this drops the user at the sign-in
//  screen and brings them straight back.
//

import SwiftUI

struct SignInRequiredSheet: View {
    let action: AccountPolicy.GatedAction

    @Environment(\.dismiss) private var dismiss
    @AppStorage(OnboardingKeys.completed) private var completed = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Palette.accent)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Create your account")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)

                Text(action.reason)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Button {
                    // hasOnboardedBefore is already true, so the flow reopens
                    // at sign-in rather than replaying the intro slides.
                    dismiss()
                    completed = false
                } label: {
                    Text("Create account")
                        .font(Theme.Typography.title)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Theme.Palette.accent, in: .capsule)
                }
                .buttonStyle(.plain)

                Button("Not now") { dismiss() }
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)

            Text("Your widgets stay exactly where they are.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText.opacity(0.8))
                .padding(.bottom, Theme.Spacing.lg)
        }
        .background(Theme.Palette.background)
    }
}

#Preview {
    SignInRequiredSheet(action: .writeReview)
}
