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
                let ext = url.pathExtension.lowercased()
                
                // Handle Word Documents (.docx) -> Ingest as Text with markdown/formatting
                if ext == "docx",
                   let attrStr = try? NSAttributedString(url: url, options: [.documentType: NSAttributedString.DocumentType.officeOpenXML], documentAttributes: nil) {
                    payloads.append(.text(attrStr.string, metadata: ["sourceFile": url.lastPathComponent]))
                    continue
                }
                
                // Handle Image Files (.png, .jpg, .jpeg, .heic, .webp) -> Ingest as Image payload
                if ["png", "jpg", "jpeg", "heic", "webp"].contains(ext),
                   let image = NSImage(contentsOf: url) {
                    payloads.append(.image(image))
                    continue
                }
                
                let textExtensions = ["txt", "md", "rtf", "docx", "html", "xml"]
                // Handle Text/Code Files (.txt, .md, .swift, .json, .html, etc.) -> Ingest as Text payload
                if textExtensions.contains(ext) {
                    if ext == "docx",
                       let attrStr = try? NSAttributedString(url: url, options: [.documentType: NSAttributedString.DocumentType.officeOpenXML], documentAttributes: nil) {
                        payloads.append(.text(attrStr.string, metadata: ["sourceFile": url.lastPathComponent]))
                        continue
                    }
                    
                    if let textContent = try? String(contentsOf: url, encoding: .utf8) {
                        payloads.append(.text(textContent, metadata: ["sourceFile": url.lastPathComponent]))
                        continue
                    }
                }
                
                // Fallback for general files
                payloads.append(.file(url))
            }
            return payloads
        }
        
        // 2. Check for Direct In-Memory Images
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], !images.isEmpty {
            for img in images {
                payloads.append(.image(img))
            }
            return payloads
        }
        
        // 3. Check for Plain Text / String content
        if let stringContent = pasteboard.string(forType: .string), !stringContent.isEmpty {
            payloads.append(.text(stringContent))
            return payloads
        }
        
        return payloads
    }
}
