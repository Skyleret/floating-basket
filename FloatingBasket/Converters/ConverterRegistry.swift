//
//  ConverterRegistry.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import Foundation

public final class ConverterRegistry: Sendable {
    public static let shared = ConverterRegistry()
    
    private let registeredConverters: [FileConverter] = [
        MarkdownConverter(),
        DocxConverter(),
        PlainTextConverter(),
        PdfConverter(),
        PNGConverter(),
        JPEGConverter(),
        HeicConverter()
    ]
    
    public init() {}
    
    public func converters(for payload: BasketPayload) -> [FileConverter] {
        var converters = registeredConverters.filter { $0.canHandle(payload: payload) }
        
        // The original file converter is bound to a specific source URL, so it is
        // created per payload instead of living in the static registry. It is
        // offered for every payload that came from a file (not just unsupported
        // types) and is placed first so it stays visible in the format row.
        if let sourceURL = payload.sourceFileURL {
            converters.insert(OriginalFileConverter(url: sourceURL), at: 0)
        }
        
        return converters
    }
}
