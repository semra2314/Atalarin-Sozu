//
//  RootGate.swift
//  Widgy
//
//  Shows onboarding on first launch, the app afterwards.
//

import SwiftUI

struct RootGate: View {
    @AppStorage(OnboardingKeys.completed) private var completed = false

    var body: some View {
        if completed {
            RootView()
                .transition(.opacity)
        } else {
            OnboardingView()
                .transition(.opacity)
        }
    }
}
