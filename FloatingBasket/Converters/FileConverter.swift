//
//  FileConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//


import Foundation

public protocol FileConverter: Sendable {
    var id: String { get }
    var keyShortcut: String { get } // e.g., "1", "2"
    var targetExtension: String { get } // e.g., "md", "docx"
    
    func canHandle(payload: BasketPayload) -> Bool
    func convert(payload: BasketPayload) throws -> URL
}