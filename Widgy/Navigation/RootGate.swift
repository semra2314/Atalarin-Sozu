//
//  RootGate.swift
//  Widgy
//
//  Shows onboarding on first launch, the app afterwards.
//

import SwiftUI
import SwiftData

struct RootGate: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(OnboardingKeys.completed) private var completed = false

    var body: some View {
        Group {
            if completed {
                RootView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        // Fill the library with the built-in widgets on the first run. Done
        // here rather than inside onboarding so it also covers anyone who
        // already finished onboarding on an earlier build.
        .task {
            try? LibraryStore(context: modelContext).seedBuiltInsIfNeeded()
        }
    }
}
