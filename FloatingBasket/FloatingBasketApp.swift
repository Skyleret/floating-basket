//
//  FloatingBasketApp 2.swift
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
            Button("Toggle Basket") {
                appDelegate.toggleBasketWindow()
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var basketPanel: BasketPanel?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupBasketWindow()
        
        // Only show up when shaking mouse AND dragging something
        MouseShakeDetector.shared.onShakeWhileDraggingDetected = { [weak self] in
            guard let self = self, let panel = self.basketPanel, !panel.isVisible else { return }
            panel.orderFront(nil)
        }
        MouseShakeDetector.shared.startMonitoring()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        MouseShakeDetector.shared.stopMonitoring()
    }
    
    private func setupBasketWindow() {
        let panel = BasketPanel(
            contentRect: NSRect(x: 100, y: 100, width: 220, height: 130),
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: BasketWindowView())
        panel.center()
        panel.orderOut(nil)
        self.basketPanel = panel
    }
    
    public func toggleBasketWindow() {
        guard let panel = basketPanel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFront(nil)
        }
    }
}
