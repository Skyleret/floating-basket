//
//  OriginalFileConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 10/19/26.
//


//
//  OriginalFileConverter.swift
//  FloatingBasket
//
//  Created by Skyler on 19/10/2026.
//

import Foundation

public final class OriginalFileConverter: FileConverter, Sendable {
    public let id = "original-file-converter"
    public let keyShortcut = "0"
    public let targetExtension: String
    
    private let fileURL: URL
    
    public init(url: URL) {
        self.fileURL = url
        self.targetExtension = url.pathExtension.lowercased()
    }
    
    public func canHandle(payload: BasketPayload) -> Bool {
        if case .file(let url) = payload, url == fileURL {
            return true
        }
        return false
    }
    
    public func convert(payload: BasketPayload) throws -> URL {
        guard case .file(let url) = payload else {
            throw NSError(domain: "FloatingBasket", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid payload type for Original File converter"])
        }
        
        // Optional: If you want to copy it to a temp directory or just return the original URL
        return url
    }
}