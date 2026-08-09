//
//  AuthorView.swift
//  Widgy
//

import SwiftUI

/// Creator profile. Intentionally thin for now — it becomes meaningful once
/// the backend can serve a creator's full catalog and follower count.
struct AuthorView: View {
    let authorID: String

    var body: some View {
        ContentUnavailableView {
            Label("Creator profiles", systemImage: "person.crop.circle")
        } description: {
            Text("Coming next: every widget from this creator, in one place.")
        }
        .navigationTitle("Creator")
        .navigationBarTitleDisplayMode(.inline)
    }
}
