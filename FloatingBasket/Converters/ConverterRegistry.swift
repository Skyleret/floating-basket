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
        HeicConverter()
    ]
    
    public init() {}
    
    public func converters(for payload: BasketPayload) -> [FileConverter] {
        return registeredConverters.filter { $0.canHandle(payload: payload) }
    }
}
