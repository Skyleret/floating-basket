//
//  MarkdownConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 10/19/26.
//


//
//  MarkdownConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation

public final class MarkdownConverter: FileConverter, Sendable {
    public let id = "markdown-converter"
    public let keyShortcut = "1"
    public let targetExtension = "md"
    
    public init() {}
    
    public func canHandle(payload: BasketPayload) -> Bool {
        if case .text = payload { return true }
        return false
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        guard case .text(let content, _) = payload else {
            throw NSError(domain: "FloatingBasket", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid payload type for Markdown converter"])
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let fileName = "snippet-\(UUID().uuidString).md"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}