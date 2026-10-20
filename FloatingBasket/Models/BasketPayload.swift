//
//  BasketPayload.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//


import Foundation
import AppKit

public enum BasketPayload: Identifiable, Sendable {
    /// Metadata key holding the full path of the file a text payload was ingested from.
    public static let sourceFileURLKey = "sourceFileURL"
    
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
    
    /// The on-disk file this payload originated from, when there is one.
    /// `.file` payloads are the file itself; `.text` payloads carry the path in metadata.
    public var sourceFileURL: URL? {
        switch self {
        case .file(let url):
            return url
        case .text(_, let metadata):
            guard let path = metadata[Self.sourceFileURLKey], !path.isEmpty else {
                return nil
            }
            return URL(fileURLWithPath: path)
        case .image:
            return nil
        }
    }
}