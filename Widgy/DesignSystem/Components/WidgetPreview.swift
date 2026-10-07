//
//  WidgetPreview.swift
//  Kare
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Renders a template's theme at the correct home-screen proportions.
/// This is the stand-in for the real WidgetKit render — the shape of the API
/// is deliberately close to what a live preview will need.
struct WidgetPreview: View {
    let template: WidgetTemplate
    var size: WidgetSize
    var showsLabel: Bool = true
    /// On the detail page: prefer the per-size product image (the S/M/L design).
    var preferSizeImage: Bool = false

    /// The per-size product image for this size, if it exists in the catalog.
    private var sizeImageName: String? {
        guard preferSizeImage, let base = template.sizePreviewBaseName else { return nil }
        let name = "\(base)_\(size.assetKey)"
        #if canImport(UIKit)
        return UIImage(named: name) != nil ? name : nil
        #else
        return name
        #endif
    }

    /// The store image, but only if it is really in the asset catalogue. A
    /// catalogue entry whose art has not been added yet falls through to the
    /// drawn preview instead of an empty box.
    private var resolvedImageName: String? {
        guard let name = sizeImageName ?? template.previewImageName else { return nil }
        #if canImport(UIKit)
        return UIImage(named: name) != nil ? name : nil
        #else
        return name
        #endif
    }

    var body: some View {
        if preferSizeImage, LiveWidgetRender.supportedIDs.contains(template.id) {
            // The detail page's size picker: the real widget at that size,
            // not the one marketing picture used everywhere else.
            LiveWidgetRender(templateID: template.id, size: size)
        } else if preferSizeImage, let designed = template.content {
            // Presets and Custom: the actual design at the picked size, not
            // their market picture.
            CustomWidgetView(content: designed, size: size)
        } else if let imageName = resolvedImageName {
            // A real store / per-size product image.
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .aspectRatio(size.aspectRatio, contentMode: .fit)
                .clipShape(.rect(cornerRadius: template.theme.cornerRadius))
        } else if LiveWidgetPreview.supportedIDs.contains(template.id) {
            // Kare+ live widgets have no store art yet; draw the real thing.
            LiveWidgetPreview(templateID: template.id, size: size)
        } else if let designed = template.content {
            // Render the ready-made design exactly as it will look on the home screen.
            CustomWidgetView(content: designed, size: size)
        } else {
            abstractPreview
        }
    }

    private var abstractPreview: some View {
        ZStack {
            template.theme.backgroundGradient

            if template.theme.usesGlassEffect {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.35)
            }

            if showsLabel {
                content
            }
        }
        .aspectRatio(size.aspectRatio, contentMode: .fit)
        .clipShape(.rect(cornerRadius: template.theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: template.theme.cornerRadius)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Image(systemName: template.category.symbolName)
                .font(.system(size: size == .small ? 18 : 22, weight: .semibold))
                .foregroundStyle(template.theme.accent)

            Spacer(minLength: 0)

            Text(LocalizedStringKey(template.name))
                .font(.system(size: size == .small ? 13 : 15, weight: .semibold))
                .foregroundStyle(template.theme.foreground)
                .lineLimit(2)

            if size != .small && !size.isLockScreen {
                Text(LocalizedStringKey(template.summary))
                    .font(.system(size: 11))
                    .foregroundStyle(template.theme.foreground.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(size == .small ? Theme.Spacing.md : Theme.Spacing.lg)
    }
}

#Preview {
    WidgetPreview(template: SampleCatalog.templates[0], size: .medium)
        .frame(width: 320)
        .padding()
}
