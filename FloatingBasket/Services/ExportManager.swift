//
//  ExportManager.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//


import Foundation
import AppKit

@MainActor
public final class ExportManager {
    public static let shared = ExportManager()
    
    private let textConverters: [FileConverter] = [
        MarkdownConverter(),
        PlainTextConverter()
    ]
    
    private let imageConverters: [FileConverter] = [
        PNGConverter(),
        JPEGConverter()
    ]
    
    private init() {}
    
    public func converters(for payload: BasketPayload) -> [FileConverter] {
        switch payload {
        case .text:
            return textConverters
        case .image:
            return imageConverters
        case .file:
            return []
        }
    }
    
    public func export(payload: BasketPayload, using converter: FileConverter) throws -> URL {
        guard converter.canHandle(payload: payload) else {
            throw NSError(domain: "FloatingBasket", code: 300, userInfo: [NSLocalizedDescriptionKey: "Converter cannot handle this payload type"])
        }
        return try converter.convert(payload: payload)
    }
}
