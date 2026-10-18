//
//  BasketPayload.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//


import Foundation
import AppKit

public enum BasketPayload: Identifiable, Sendable {
    case text(String, metadata: [String: String] = [:])
    case image(NSImage)
    case file(URL)

    public var id: String {
        switch self {
        case .text(let content, _):
            return "text-\(content.hashValue)"
        case .image(let img):
            return "image-\(Unmanaged.passUnretained(img).toOpaque())"
        case .file(let url):
            return "file-\(url.absoluteString)"
        }
    }
    
    public var displayTitle: String {
        switch self {
        case .text(let content, _):
            let prefix = content.prefix(20)
            return prefix.isEmpty ? "Empty Text" : String(prefix)
        case .image(_):
            return "Image Item"
        case .file(let url):
            return url.lastPathComponent
        }
    }
}