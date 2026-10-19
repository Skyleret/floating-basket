//
//  TempCleanupService.swift
//  FloatingBasket
//
//  Created by Skyler on 10/19/26.
//

import Foundation

public final class TempCleanupService: Sendable {
    public static let shared = TempCleanupService()
    
    private let tempDirectoryName = "FloatingBasket"
    private let maxFileAge: TimeInterval = 3600 // 1 hour threshold
    
    private init() {}
    
    public func startPeriodicCleanup() {
        // Run initial cleanup on launch
        cleanupNow()
        
        // Schedule periodic cleanup every 30 minutes
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 30 * 60 * 1_000_000_000)
                cleanupNow()
            }
        }
    }
    
    public func cleanupNow() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(tempDirectoryName, isDirectory: true)
        
        guard fileManager.fileExists(atPath: tempDir.path) else { return }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
            let now = Date()
            
            for url in fileURLs {
                if let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey]),
                   let creationDate = resourceValues.creationDate {
                    if now.timeIntervalSince(creationDate) > maxFileAge {
                        try? fileManager.removeItem(at: url)
                    }
                } else {
                    // Fallback to modification date if creation date is unavailable
                    if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                       let modDate = attributes[.modificationDate] as? Date {
                        if now.timeIntervalSince(modDate) > maxFileAge {
                            try? fileManager.removeItem(at: url)
                        }
                    }
                }
            }
        } catch {
            print("FloatingBasket: Failed to clean up temp directory - \(error)")
        }
    }
}
