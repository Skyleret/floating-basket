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
        // Keep the menu-bar app and its programmatically-created panels,
        // but omit FloatingBasket from the Dock and Command-Tab switcher.
        NSApp.setActivationPolicy(.accessory)

        TempCleanupService.shared.startPeriodicCleanup()

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

        // One Window, One File.
        for payload in payloads {
            spawnWindow(with: payload)
        }
    }

    /// Shows an empty basket at the cursor. A valid drag can be summoned by
    /// shaking or by entering the detector's top-center pin zone.
    public func handleShakeWhileDragging() {
        spawnWindow()
    }

    public func spawnWindow(with payload: BasketPayload? = nil) {
        let panel = BasketPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 115),
            backing: .buffered,
            defer: false
        )

        panel.contentView = NSHostingView(
            rootView: BasketIngestionWindowView(payload: payload)
        )

        let mouseLocation = NSEvent.mouseLocation
        let offset: CGFloat = 16

        // Prefer below/right of the cursor. Clamp to the visible screen so
        // the panel stays accessible on notched MacBooks and external displays.
        var origin = NSPoint(
            x: mouseLocation.x + offset,
            y: mouseLocation.y - panel.frame.height - offset
        )

        if let screen = NSScreen.screens.first(where: {
            $0.frame.contains(mouseLocation)
        }) ?? NSScreen.main {
            let visible = screen.visibleFrame

            origin.x = min(
                max(origin.x, visible.minX),
                max(visible.minX, visible.maxX - panel.frame.width)
            )
            origin.y = min(
                max(origin.y, visible.minY),
                max(visible.minY, visible.maxY - panel.frame.height)
            )
        }

        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
        panel.makeKey()
    }
}
