//
//  PNGConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//


import Foundation
import AppKit

public final class PNGConverter: FileConverter, Sendable {
    public let id = "png-converter"
    public let keyShortcut = "1"
    public let targetExtension = "png"
    
    public init() {}
    
    public func canHandle(payload: BasketPayload) -> Bool {
        if case .image = payload { return true }
        return false
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        guard case .image(let image) = payload else {
            throw NSError(domain: "FloatingBasket", code: 200, userInfo: [NSLocalizedDescriptionKey: "Invalid payload type for PNG converter"])
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "FloatingBasket", code: 201, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PNG representation"])
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let fileURL = tempDir.appendingPathComponent("image-\(UUID().uuidString).png")
        try pngData.write(to: fileURL)
        return fileURL
    }
}

public final class JPEGConverter: FileConverter, Sendable {
    public let id = "jpeg-converter"
    public let keyShortcut = "2"
    public let targetExtension = "jpg"
    
    public init() {}
    
    public func canHandle(payload: BasketPayload) -> Bool {
        if case .image = payload { return true }
        return false
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        guard case .image(let image) = payload else {
            throw NSError(domain: "FloatingBasket", code: 202, userInfo: [NSLocalizedDescriptionKey: "Invalid payload type for JPEG converter"])
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw NSError(domain: "FloatingBasket", code: 203, userInfo: [NSLocalizedDescriptionKey: "Failed to generate JPEG representation"])
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let fileURL = tempDir.appendingPathComponent("image-\(UUID().uuidString).jpg")
        try jpegData.write(to: fileURL)
        return fileURL
    }
}