//
//  PdfConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation
import AppKit
import CoreGraphics
import PDFKit

public final class PdfConverter: FileConverter, Sendable {
    public let id = "pdf-converter"
    public let keyShortcut = "4"
    public let targetExtension = "pdf"
    
    public init() {}
    
    public func canHandle(payload: BasketPayload) -> Bool {
        switch payload {
        case .text, .image:
            return true
        default:
            return false
        }
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("document-\(UUID().uuidString).pdf")
        
        switch payload {
        case .text(let content, _):
            let attrStr = MarkdownParserUtility.attributedString(from: content)
            let pdfDocument = PDFDocument()
            
            // Create a printable text view / page renderer for rich text content
            let textStorage = NSTextStorage(attributedString: attrStr)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)
            
            let textContainer = NSTextContainer(containerSize: CGSize(width: 595.28, height: 841.89)) // A4 size
            textContainer.lineFragmentPadding = 20.0
            layoutManager.addTextContainer(textContainer)
            layoutManager.glyphRange(for: textContainer)
            
            let pdfData = NSMutableData()
            var mediaBox = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
            
            guard let consumer = CGDataConsumer(data: pdfData as NSMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                throw NSError(domain: "FloatingBasket", code: 104, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF context for text"])
            }
            
            let pageRange = layoutManager.glyphRange(for: textContainer)
            var glyphIndex = 0
            
            while glyphIndex < pageRange.location + pageRange.length {
                context.beginPage(mediaBox: &mediaBox)
                context.saveGState()
                // Flip coordinate system for AppKit / CoreText drawing
                context.translateBy(x: 0, y: mediaBox.height)
                context.scaleBy(x: 1.0, y: -1.0)
                
                let glyphsToDraw = layoutManager.glyphRange(for: textContainer).length
                // Draw text container slice onto PDF context
                let rangeOfGlyphs = NSRange(location: glyphIndex, length: min(1000, pageRange.length - glyphIndex))
                if rangeOfGlyphs.length <= 0 { break }
                
                layoutManager.drawBackground(forGlyphRange: rangeOfGlyphs, at: CGPoint(x: 40, y: 40))
                layoutManager.drawGlyphs(forGlyphRange: rangeOfGlyphs, at: CGPoint(x: 40, y: 40))
                
                glyphIndex += rangeOfGlyphs.length
                context.restoreGState()
                context.endPage()
            }
            
            context.closePDF()
            try (pdfData as Data).write(to: fileURL)
            return fileURL
            
        case .image(let nsImage, _):
            guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw NSError(domain: "FloatingBasket", code: 104, userInfo: [NSLocalizedDescriptionKey: "Failed to extract image for PDF conversion"])
            }
            
            let pdfData = NSMutableData()
            var mediaBox = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
            
            guard let consumer = CGDataConsumer(data: pdfData as NSMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                throw NSError(domain: "FloatingBasket", code: 105, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF context"])
            }
            
            context.beginPage(mediaBox: &mediaBox)
            context.draw(cgImage, in: mediaBox)
            context.endPage()
            context.closePDF()
            
            try (pdfData as Data).write(to: fileURL)
            return fileURL
            
        default:
            throw NSError(domain: "FloatingBasket", code: 103, userInfo: [NSLocalizedDescriptionKey: "Unsupported payload for PDF converter"])
        }
    }
}
