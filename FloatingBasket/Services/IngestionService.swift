//
//  IngestionService.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//


import Foundation
import AppKit

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
}