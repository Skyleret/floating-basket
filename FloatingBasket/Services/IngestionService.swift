//
//  IngestionService.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation
import AppKit
internal import UniformTypeIdentifiers

public final class IngestionService: Sendable {
    public init() {}
    
    public func parsePasteboard(_ pasteboard: NSPasteboard) -> [BasketPayload] {
        var payloads: [BasketPayload] = []
        
        // 1. Check for File URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            for url in urls {
                payloads.append(.file(url))
            }
            return payloads
        }
        
        // 2. Check for Images
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], !images.isEmpty {
            for img in images {
                payloads.append(.image(img))
            }
            return payloads
        }
        
        // 3. Check for Plain Text / String content
        if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], !strings.isEmpty {
            for str in strings {
                payloads.append(.text(str))
            }
            return payloads
        }
        
        // Fallback: Check string types directly
        if let stringContent = pasteboard.string(forType: .string), !stringContent.isEmpty {
            payloads.append(.text(stringContent))
        }
        
        return payloads
    }
    
    public func loadPayload(from provider: NSItemProvider) async -> BasketPayload? {
        // 1. Check for File URL
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                return .file(url)
            } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) {
                return .file(url)
            }
        }
        
        // 2. Check for Image
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let image = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier) as? NSImage {
                return .image(image)
            } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier) as? Data,
                      let image = NSImage(data: data) {
                return .image(image)
            }
        }
        
        // 3. Check for Text
        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            if let text = try? await provider.loadItem(forTypeIdentifier: UTType.text.identifier) as? String {
                return .text(text)
            } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.text.identifier) as? Data,
                      let text = String(data: data, encoding: .utf8) {
                return .text(text)
            }
        }
        
        return nil
    }
}
