//
//  MarkdownParserUtility.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation
import AppKit

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
