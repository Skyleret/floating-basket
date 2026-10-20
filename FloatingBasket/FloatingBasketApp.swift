//
//  FloatingBasketApp.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import SwiftUI
import AppKit

@main
public struct FloatingBasketApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        Settings {
            EmptyView()
        }
        
        MenuBarExtra("FloatingBasket", systemImage: "basket") {
            Button("Paste from Clipboard") {
                appDelegate.handlePasteFromClipboard()
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let ingestionService = IngestionService()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        TempCleanupService.shared.startPeriodicCleanup()
        
        // Triggered when mouse shake + drag is detected
        // Summon an empty drop target instead of reading the clipboard: the
        // dragged item never lands on NSPasteboard and is delivered via onDrop.
        MouseShakeDetector.shared.onShakeWhileDraggingDetected = { [weak self] in
            self?.handleShakeWhileDragging()
        }
        MouseShakeDetector.shared.startMonitoring()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        MouseShakeDetector.shared.stopMonitoring()
    }
    
    public func handlePasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        let payloads = ingestionService.parsePasteboard(pasteboard)
        
        // Enforce "One Window, One File": Spawn a separate floating panel for each payload found
        for payload in payloads {
            spawnWindow(with: payload)
        }
    }
    
    /// Shows an empty basket that acts purely as a drop target. The dragged
    /// item is delivered through the view's `onDrop` handler, so the clipboard
    /// (which is only populated by an explicit copy) must not be consulted here.
    public func handleShakeWhileDragging() {
        spawnWindow()
    }
    
    public func spawnWindow(with payload: BasketPayload? = nil) {
        let panel = BasketPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 115), // Matches BasketIngestionWindowView's frame
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: BasketIngestionWindowView(payload: payload))
        panel.center()
        panel.orderFrontRegardless()
        panel.makeKey()
    }
}
