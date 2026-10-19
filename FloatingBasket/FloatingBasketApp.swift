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
    private var intakePanel: BasketPanel?
    private let ingestionService = IngestionService()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        TempCleanupService.shared.startPeriodicCleanup()
        setupIntakeWindow()
        
        // Show intake basket when shaking while dragging
        MouseShakeDetector.shared.onShakeWhileDraggingDetected = { [weak self] in
            guard let self = self, let panel = self.intakePanel, !panel.isVisible else { return }
            panel.center()
            panel.orderFrontRegardless()
            panel.makeKey()
        }
        MouseShakeDetector.shared.startMonitoring()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        MouseShakeDetector.shared.stopMonitoring()
    }
    

    private var mouseUpMonitor: Any?

    private func setupIntakeWindow() {
        let panel = BasketPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 86),
            backing: .buffered,
            defer: false
        )
        
        let rootView = BasketWindowView { [weak self, weak panel] payload in
            panel?.orderOut(nil)
            self?.spawnSingleItemWindow(with: payload)
        }
        
        panel.contentView = NSHostingView(rootView: rootView)
        panel.orderOut(nil)
        self.intakePanel = panel
    }
    
    public func handlePasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        let payloads = ingestionService.parsePasteboard(pasteboard)
        for payload in payloads {
            spawnSingleItemWindow(with: payload)
        }
    }
    
    public func spawnSingleItemWindow(with payload: BasketPayload) {
        let panel = BasketPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 115),
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: SingleItemWindowView(payload: payload))
        panel.center()
        panel.orderFrontRegardless()
        panel.makeKey()
    }
}
