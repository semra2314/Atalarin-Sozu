//
//  ImageDownscaler.swift
//  Kare
//
//  WidgetKit extensions have a very tight memory budget (~30MB). A full-size
//  photo embedded in the payload can blow it and leave the widget blank/gray.
//  Downscale + JPEG-encode before saving so the home-screen widget renders it
//  cheaply.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ImageDownscaler {
    static func downscaledJPEG(_ data: Data, maxDimension: CGFloat = 600, quality: CGFloat = 0.8) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        let factor = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: image.size.width * factor, height: image.size.height * factor)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
        #else
        return data
        #endif
    }
}
