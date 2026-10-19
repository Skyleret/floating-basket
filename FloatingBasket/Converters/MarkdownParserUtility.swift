//
//  TextConverters.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation
import AppKit

// MARK: - Markdown Parser Utility
public enum MarkdownParserUtility {
    public static func attributedString(from markdown: String) -> NSAttributedString {
        let resultString = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let processedLine = parseLine(line)
            resultString.append(processedLine)
            if index < lines.count - 1 {
                resultString.append(NSAttributedString(string: "\n"))
            }
        }
        return resultString
    }
    
    private static func parseLine(_ line: String) -> NSAttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Headers
        if trimmed.hasPrefix("# ") {
            return NSAttributedString(string: String(trimmed.dropFirst(2)) + "\n", attributes: [.font: NSFont.boldSystemFont(ofSize: 22)])
        } else if trimmed.hasPrefix("## ") {
            return NSAttributedString(string: String(trimmed.dropFirst(3)) + "\n", attributes: [.font: NSFont.boldSystemFont(ofSize: 18)])
        } else if trimmed.hasPrefix("### ") {
            return NSAttributedString(string: String(trimmed.dropFirst(4)) + "\n", attributes: [.font: NSFont.boldSystemFont(ofSize: 14)])
        }
        
        // Bullet Lists
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return NSAttributedString(string: "• " + String(trimmed.dropFirst(2)), attributes: [.font: NSFont.systemFont(ofSize: 12)])
        }
        
        return NSAttributedString(string: line, attributes: [.font: NSFont.systemFont(ofSize: 12)])
    }
}

// MARK: - Markdown Converter (.md)
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
        let fileURL = tempDir.appendingPathComponent("snippet-\(UUID().uuidString).md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

// MARK: - Word / DOCX Converter (.docx)
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

// MARK: - Plain Text Converter (.txt)
public final class PlainTextConverter: FileConverter, Sendable {
    public let id = "plaintext-converter"
    public let keyShortcut = "3"
    public let targetExtension = "txt"
    
    public init() {}
    
    public func canHandle(payload: BasketPayload) -> Bool {
        if case .text = payload { return true }
        return false
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        guard case .text(let content, _) = payload else {
            throw NSError(domain: "FloatingBasket", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid payload type for Plain Text converter"])
        }
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("snippet-\(UUID().uuidString).txt")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
