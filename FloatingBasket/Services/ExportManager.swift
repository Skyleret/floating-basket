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
    
    private init() {}
    
    public func converters(for payload: BasketPayload) -> [FileConverter] {
        // Single source of truth: each converter decides whether it applies via
        // `canHandle(payload:)`, so new converters only need to be registered there.
        return ConverterRegistry.shared.converters(for: payload)
    }
    
    public func export(payload: BasketPayload, using converter: FileConverter) throws -> URL {
        guard converter.canHandle(payload: payload) else {
            throw NSError(domain: "FloatingBasket", code: 300, userInfo: [NSLocalizedDescriptionKey: "Converter cannot handle this payload type"])
        }
        return try converter.convert(payload: payload)
    }
}
