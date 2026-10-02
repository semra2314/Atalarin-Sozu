//
//  RootGate.swift
//  Kare
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
        // The library starts empty. Tell the widget extension what is in it,
        // so the widget picker only offers widgets the user has added.
        .task {
            LibraryStore(context: modelContext).syncMirror()
        }
    }
}
