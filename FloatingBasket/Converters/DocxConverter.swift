//
//  DocxConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation
import AppKit

public final class DocxConverter: FileConverter, Sendable {
    public let id = "docx-converter"
    public let keyShortcut = "2"
    public let targetExtension = "docx"
    
    public init() {}
    
    public func canHandle(payload: BasketPayload) -> Bool {
        switch payload {
        case .text:
            return true
        case .file(let url):
            return url.pathExtension.lowercased() == "docx"
        default:
            return false
        }
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("document-\(UUID().uuidString).docx")
        
        let attributedString: NSAttributedString
        
        switch payload {
        case .text(let content, _):
            // Parse Markdown formatting tags into rich text for Word export
            attributedString = MarkdownParserUtility.attributedString(from: content)
            
        case .file(let url):
            if url.pathExtension.lowercased() == "docx" {
                try? FileManager.default.copyItem(at: url, to: fileURL)
                return fileURL
            }
            attributedString = NSAttributedString(string: "")
            
        default:
            throw NSError(domain: "FloatingBasket", code: 102, userInfo: [NSLocalizedDescriptionKey: "Invalid payload for DOCX converter"])
        }
        
        let range = NSRange(location: 0, length: attributedString.length)
        do {
            let data = try attributedString.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.officeOpenXML])
            try data.write(to: fileURL)
            return fileURL
        } catch {
            let rtfData = try attributedString.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            try rtfData.write(to: fileURL)
            return fileURL
        }
    }
}
