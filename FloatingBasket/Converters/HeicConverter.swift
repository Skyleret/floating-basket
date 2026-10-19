//
//  HeicConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 10/19/26.
//


//
//  HeicConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation
import AppKit
import ImageIO
internal import UniformTypeIdentifiers

public final class HeicConverter: FileConverter, Sendable {
    public let id = "heic-converter"
    public let keyShortcut = "3"
    public let targetExtension = "heic"
    
    public init() {}
    
    public func canHandle(payload: BasketPayload) -> Bool {
        if case .image = payload { return true }
        return false
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        guard case .image(let nsImage) = payload else {
            throw NSError(domain: "FloatingBasket", code: 106, userInfo: [NSLocalizedDescriptionKey: "Invalid payload type for HEIC converter"])
        }
        
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else {
            throw NSError(domain: "FloatingBasket", code: 107, userInfo: [NSLocalizedDescriptionKey: "Failed to extract CGImage for HEIC conversion"])
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("image-\(UUID().uuidString).heic")
        
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.heic.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FloatingBasket", code: 108, userInfo: [NSLocalizedDescriptionKey: "Failed to create HEIC image destination"])
        }
        
        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FloatingBasket", code: 109, userInfo: [NSLocalizedDescriptionKey: "Failed to write HEIC image data"])
        }
        
        return fileURL
    }
}
