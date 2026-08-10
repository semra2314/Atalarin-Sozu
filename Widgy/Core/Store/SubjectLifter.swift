//
//  SubjectLifter.swift
//  Widgy
//
//  Turns a photo into a sticker by cutting the subject out of its background —
//  the same trick as iOS's "lift subject from background", done with Vision.
//
//  This exists because apps can't read the user's Messages sticker drawer;
//  there's no API for it. Rather than pretend otherwise, this lets them make
//  their own stickers out of their own photos, which is the better feature
//  anyway: their cat, their coffee, their face.
//

import Foundation
import Vision
import CoreImage
#if canImport(UIKit)
import UIKit
#endif

enum SubjectLifter {

    enum LiftError: Error, LocalizedError {
        case unreadableImage
        case noSubjectFound
        case renderFailed

        var errorDescription: String? {
            switch self {
            case .unreadableImage: "That image couldn't be read."
            case .noSubjectFound: "Couldn't find a clear subject in that photo. Try one where the subject stands out from the background."
            case .renderFailed: "Couldn't create the sticker."
            }
        }
    }

    /// Cuts the most prominent subject out of `data` and returns a transparent
    /// PNG, trimmed to the subject's bounds and downscaled for the widget's
    /// memory budget.
    ///
    /// Runs off the main actor: the mask request is genuinely slow on a big
    /// photo and would visibly stall the editor otherwise.
    static func liftSubject(from data: Data, maxDimension: CGFloat = 500) async throws -> Data {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage else {
            throw LiftError.unreadableImage
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: uiImage.cgOrientation)
        let request = VNGenerateForegroundInstanceMaskRequest()

        try handler.perform([request])

        guard let result = request.results?.first, !result.allInstances.isEmpty else {
            throw LiftError.noSubjectFound
        }

        // `allInstances` masks every subject it found. Taking all of them keeps
        // a photo of two people from silently losing one.
        let masked = try result.generateMaskedImage(
            ofInstances: result.allInstances,
            from: handler,
            croppedToInstancesExtent: true
        )

        let ciImage = CIImage(cvPixelBuffer: masked)
        let context = CIContext()
        guard let cropped = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw LiftError.renderFailed
        }

        return try downscaledPNG(cropped, maxDimension: maxDimension)
        #else
        throw LiftError.unreadableImage
        #endif
    }

    #if canImport(UIKit)
    /// PNG, not JPEG — the cutout's transparency is the whole point, and JPEG
    /// would fill it with black.
    private static func downscaledPNG(_ cgImage: CGImage, maxDimension: CGFloat) throws -> Data {
        let image = UIImage(cgImage: cgImage)
        let longest = max(image.size.width, image.size.height)
        let factor = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: image.size.width * factor, height: image.size.height * factor)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }

        guard let data = resized.pngData() else { throw LiftError.renderFailed }
        return data
    }
    #endif
}

#if canImport(UIKit)
private extension UIImage {
    /// Vision needs the orientation separately; a photo shot in portrait is
    /// stored landscape with an orientation flag, and ignoring it masks the
    /// wrong part of the image.
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
#endif
