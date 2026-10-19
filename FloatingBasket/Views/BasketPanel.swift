//
//  BasketPanel.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

public final class BasketPanel: NSPanel {
    public init(contentRect: NSRect, backing: NSPanel.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView], backing: backing, defer: flag)
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = false
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

public struct BasketIngestionWindowView: View {
    public let payload: BasketPayload
    @State private var isExpanded = false
    @State private var mouseUpMonitor: Any?
    
    private let exportManager = ExportManager.shared
    
    public init(payload: BasketPayload) {
        self.payload = payload
    }
    
    public var body: some View {
        Group {
            if isExpanded {
                SingleItemWindowView(payload: payload)
            } else {
                dropboxView
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .onAppear {
            setupMouseUpMonitor()
        }
        .onDisappear {
            removeMouseUpMonitor()
        }
    }
    
    private var dropboxView: some View {
        VStack(spacing: 6) {
            Image(systemName: "basket.fill")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
            
            Text("Drop here")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
            
            Text(payload.displayTitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 120, height: 100)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .onDrop(of: [.item, .fileURL, .text, .image], isTargeted: nil) { _ in
            expandWindow()
            return true
        }
    }
    
    private func expandWindow() {
        guard !isExpanded else { return }
        isExpanded = true
        removeMouseUpMonitor()
        
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.contentView?.isDescendant(of: $0.contentView ?? NSView()) ?? false }) ?? NSApp.keyWindow {
                let currentFrame = window.frame
                let newSize = NSSize(width: 240, height: 115)
                let newFrame = NSRect(
                    x: currentFrame.origin.x - (newSize.width - currentFrame.width) / 2,
                    y: currentFrame.origin.y - (newSize.height - currentFrame.height) / 2,
                    width: newSize.width,
                    height: newSize.height
                )
                window.setFrame(newFrame, display: true, animate: true)
            }
        }
    }
    
    private func setupMouseUpMonitor() {
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { _ in
            handleMouseUp()
        }
    }
    
    private func removeMouseUpMonitor() {
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            mouseUpMonitor = nil
        }
    }
    
    private func handleMouseUp() {
        guard !isExpanded else { return }
        
        DispatchQueue.main.async {
            let mouseLocation = NSEvent.mouseLocation
            if let window = NSApp.windows.first(where: { $0.frame.contains(mouseLocation) && $0 is BasketPanel }) {
                // Dropped inside this window's frame
                expandWindow()
            } else {
                // Dropped outside all ingestion windows -> Discard
                NSApp.windows.forEach { window in
                    if window is BasketPanel {
                        window.orderOut(nil)
                    }
                }
            }
        }
    }
}

public struct SingleItemWindowView: View {
    public let payload: BasketPayload
    private let exportManager = ExportManager.shared
    
    public init(payload: BasketPayload) {
        self.payload = payload
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header bar for window dragging & closing
            HStack {
                Text(payload.displayTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    NSApp.keyWindow?.orderOut(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Window")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if let window = NSApp.keyWindow {
                            var frame = window.frame
                            frame.origin.x += value.translation.width
                            frame.origin.y -= value.translation.height
                            window.setFrame(frame, display: true)
                        }
                    }
            )
            
            // Format Icons Grid/Row (Drag any out)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    let converters = exportManager.converters(for: payload)
                    
                    if converters.isEmpty {
                        FormatIconView(title: "Original", extensionLabel: "file", systemImage: "doc.fill") {
                            if case .file(let url) = payload {
                                return url
                            }
                            return nil
                        }
                    } else {
                        ForEach(converters, id: \.id) { converter in
                            FormatIconView(
                                title: "[\(converter.keyShortcut)]",
                                extensionLabel: ".\(converter.targetExtension)",
                                systemImage: iconName(for: converter.targetExtension)
                            ) {
                                try? exportManager.export(payload: payload, using: converter)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 70)
            
            Spacer(minLength: 0)
        }
        .frame(width: 240, height: 115)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    private func iconName(for ext: String) -> String {
        switch ext.lowercased() {
        case "md", "txt": return "doc.text.fill"
        case "png", "jpg", "jpeg", "webp": return "photo.fill"
        default: return "doc.fill"
        }
    }
}

private struct FormatIconView: View {
    let title: String
    let extensionLabel: String
    let systemImage: String
    let exportAction: () -> URL?
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
            
            Text(extensionLabel)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(width: 55, height: 60)
        .background(Color.primary.opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onDrag {
            if let fileURL = exportAction() {
                DispatchQueue.main.async {
                    NSApp.keyWindow?.orderOut(nil)
                }
                return NSItemProvider(object: fileURL as NSURL)
            }
            return NSItemProvider()
        }
    }
}
