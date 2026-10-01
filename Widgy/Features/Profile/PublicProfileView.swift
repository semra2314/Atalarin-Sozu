//
//  PublicProfileView.swift
//  Kare
//
//  Someone else's profile, as anyone in Kare sees it: photo, name, @handle
//  and the reviews they have written. Opened by tapping a reviewer.
//

import SwiftUI

/// A person's photo, or their initial while it loads or when there is none.
struct PublicAvatar: View {
    let uid: String?
    var fallbackName: String = ""
    var size: CGFloat = 36

    @State private var service = PublicProfileService.shared

    private var profile: PublicProfile? { uid.flatMap { service.profile(for: $0) } }

    private var initial: String {
        let name = profile?.displayName.isEmpty == false ? profile!.displayName : fallbackName
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
    }

    var body: some View {
        Group {
            if let data = profile?.avatarData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Theme.Palette.surfaceMuted
                    .overlay(
                        Text(initial)
                            .font(AppFont.serif(size: size * 0.42, weight: .bold))
                            .foregroundStyle(Theme.Palette.subtleText)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
        .task(id: uid) { if let uid { await service.load(uid) } }
    }
}

struct PublicProfileView: View {
    let uid: String
    var fallbackName: String = ""

    @Environment(\.dismiss) private var dismiss
    @State private var service = PublicProfileService.shared
    @State private var reviews: [Review] = []
    @State private var loading = true
    @State private var showReport = false
    @State private var notice: String?

    private var profile: PublicProfile? { service.profile(for: uid) }
    private var isMe: Bool { AuthService.currentUID == uid }
    private var name: String {
        if let n = profile?.displayName, !n.isEmpty { return n }
        return fallbackName.isEmpty ? String(localized: "Kare user") : fallbackName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    header
                    reviewList
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Palette.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                if !isMe {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Report profile", systemImage: "flag") { showReport = true }
                            Button("Block this person", systemImage: "hand.raised", role: .destructive) {
                                ReviewService.block(uid: uid)
                                reviews = []
                                notice = String(localized: "You won't see reviews from this person anymore.")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Profile options")
                    }
                }
            }
            .confirmationDialog("Report this profile", isPresented: $showReport, titleVisibility: .visible) {
                ForEach(ReviewService.ReportReason.allCases) { reason in
                    Button(reason.title) {
                        Task {
                            if let profile { await service.report(profile, reason: reason) }
                            notice = String(localized: "Thanks for telling us. We'll take a look.")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("We look at every report within 24 hours and remove reviews that break the rules.")
            }
            .alert(notice ?? "", isPresented: Binding(
                get: { notice != nil }, set: { if !$0 { notice = nil } }
            )) {
                Button("OK", role: .cancel) {}
            }
            .task {
                await service.load(uid, force: true)
                reviews = (try? await ReviewService.fetch(byUID: uid)) ?? []
                loading = false
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            PublicAvatar(uid: uid, fallbackName: name, size: 96)
                .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 4))
                .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
            Text(name)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
            if let handle = profile?.handle, !handle.isEmpty {
                Text(verbatim: handle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
            if !loading {
                Text("\(reviews.count) reviews")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var reviewList: some View {
        if loading {
            ProgressView().padding(.top, Theme.Spacing.lg)
        } else if reviews.isEmpty {
            Text("No reviews yet.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)
                .padding(.top, Theme.Spacing.lg)
        } else {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(reviews) { review in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Text(LocalizedStringKey(templateName(review.templateID)))
                                .font(Theme.Typography.title)
                                .foregroundStyle(Theme.Palette.ink)
                            Spacer()
                            Text(review.createdAt, format: .relative(presentation: .named, unitsStyle: .wide))
                                .font(Theme.Typography.label)
                                .foregroundStyle(Theme.Palette.subtleText)
                        }
                        StarRating(value: Double(review.stars), size: 12)
                        Text(review.text)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Palette.ink.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.lg)
                    .kareCard()
                }
            }
        }
    }

    private func templateName(_ id: String) -> String {
        SampleCatalog.templates.first { $0.id == id }?.name ?? id
    }
}
