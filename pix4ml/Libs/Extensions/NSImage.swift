//
//  NSImage.swift
//  pix4ml
//
//  Created by Emre Kunt on 2.12.2022.
//  Copyright © 2022 Keyboarder Co. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {

    func resize(width: CGFloat) -> NSImage? {
        let ratio = self.size.width / width
        let height = self.size.height / ratio
        
        let frame = NSRect(x: 0, y: 0, width: width, height: height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: CGSize(width: width, height: height), flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })

        return image
    }
    
    func pngData(
        size: CGSize,
        imageInterpolation: NSImageInterpolation = .high
    ) -> Data? {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        bitmap.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = imageInterpolation
        draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()

        return bitmap.representation(using: .png, properties: [:])
    }
}
