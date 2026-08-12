//
//  EditProfileView.swift
//  Widgy
//
//  Name, handle and avatar. Everything on the profile screen used to be fixed
//  text; this is where it becomes the user's.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @AppStorage(OnboardingKeys.username) private var username = ""

    @Environment(\.dismiss) private var dismiss
    @State private var profile = ProfileStore.shared
    @State private var photoItem: PhotosPickerItem?

    /// Edited locally and written on Save, so backing out leaves nothing changed.
    @State private var draftName = ""
    @State private var draftHandle = ""

    private var trimmedHandle: String {
        draftHandle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    avatarPicker

                    VStack(spacing: Theme.Spacing.lg) {
                        field("Name", text: $draftName, prompt: "Your name")
                        field("Username", text: $draftHandle, prompt: "yourname")
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Text("This is how you'll appear in Widgy. You can change it later.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)
                }
                .padding(.vertical, Theme.Spacing.xl)
            }
            .background(Theme.Palette.background)
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        displayName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        username = trimmedHandle
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(Theme.Palette.accent)
                }
            }
            .task {
                draftName = displayName
                draftHandle = username
            }
        }
    }

    private var avatarPicker: some View {
        VStack(spacing: Theme.Spacing.md) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatar(size: 110)

                    Circle()
                        .fill(Theme.Palette.accent)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.footnote)
                                .foregroundStyle(.white)
                        )
                        .overlay(Circle().stroke(Theme.Palette.background, lineWidth: 3))
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        profile.save(imageData: data)
                    }
                }
            }

            if profile.avatar() != nil {
                Button("Remove photo") { profile.removeAvatar() }
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.accent)
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(Theme.Typography.bodyLarge)
                .autocorrectionDisabled()
                .textInputAutocapitalization(title == "Username" ? .never : .words)
                .padding(Theme.Spacing.md)
                .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
        }
    }
}

/// The user's photo, or their initial when there isn't one. Shared by Profile,
/// Settings and the edit sheet so the avatar looks the same everywhere.
struct ProfileAvatar: View {
    var size: CGFloat = 100

    @AppStorage(OnboardingKeys.displayName) private var displayName = ""
    @State private var profile = ProfileStore.shared

    private var initial: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
    }

    var body: some View {
        Group {
            if let image = profile.avatar() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Theme.Palette.surfaceMuted
                    .overlay(
                        Text(initial)
                            .font(AppFont.serif(size: size * 0.4, weight: .bold))
                            .foregroundStyle(Theme.Palette.subtleText)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: size > 60 ? 4 : 2))
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
        // Redraw when the stored photo changes; the file path itself never does.
        .id(profile.revision)
    }
}

#Preview {
    EditProfileView()
}
