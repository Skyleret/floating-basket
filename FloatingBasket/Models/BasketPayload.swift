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
    case image(NSImage, metadata: [String: String] = [:])
    case file(URL)

    public var id: String {
        switch self {
        case .text(let content, _):
            return "text-\(content.hashValue)"
        case .image(let img, _):
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
        case .image(_, let metadata):
            return Self.fileURL(from: metadata)?.lastPathComponent ?? "Image Item"
        case .file(let url):
            return url.lastPathComponent
        }
    }
    
    /// The on-disk file this payload originated from, when there is one.
    /// `.file` payloads are the file itself; `.text` and `.image` payloads carry
    /// the path in metadata so the original file can still be exported.
    public var sourceFileURL: URL? {
        switch self {
        case .file(let url):
            return url
        case .text(_, let metadata), .image(_, let metadata):
            return Self.fileURL(from: metadata)
        }
    }
    
    private static func fileURL(from metadata: [String: String]) -> URL? {
        guard let path = metadata[sourceFileURLKey], !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}
