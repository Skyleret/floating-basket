//
//  BasketWindow.swift
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

// MARK: - Intake Basket View (The Drop Zone)
// Replace your BasketWindowView struct in Views/BasketWindow.swift with this updated version:

// Replace BasketWindowView in Views/BasketWindow.swift with this:

public struct BasketWindowView: View {
    private let ingestionService = IngestionService()
    public var onPayloadDropped: ((BasketPayload) -> Void)?
    @State private var isHovering = false
    
    public init(onPayloadDropped: ((BasketPayload) -> Void)? = nil) {
        self.onPayloadDropped = onPayloadDropped
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isHovering ? "arrow.down.doc.fill" : "square.and.arrow.down")
                .font(.system(size: 24))
                .foregroundColor(isHovering ? .white : .accentColor)
            Text(isHovering ? "Release to convert" : "Drop clips or files here")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isHovering ? .white : .primary)
        }
        .frame(width: 180, height: 70)
        .background(isHovering ? Color.accentColor : Color.primary.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovering ? Color.white : Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: isHovering ? [] : [4]))
        )
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        .onDrop(of: [.fileURL, .image, .text, .data], isTargeted: $isHovering) { providers in
            Task {
                for provider in providers {
                    if let payload = await ingestionService.loadPayload(from: provider) {
                        await MainActor.run {
                            onPayloadDropped?(payload)
                        }
                        break
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Single Item Format Icon Window View (One Window, One File)
public struct SingleItemWindowView: View {
    public let payload: BasketPayload
    private let exportManager = ExportManager.shared
    
    public init(payload: BasketPayload) {
        self.payload = payload
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(payload.displayTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                Button(action: { NSApp.keyWindow?.orderOut(nil) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .contentShape(Rectangle())
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    let converters = exportManager.converters(for: payload)
                    if converters.isEmpty {
                        FormatIconView(title: "Original", extensionLabel: "file", systemImage: "doc.fill") {
                            if case .file(let url) = payload { return url }
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
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .contentShape(Rectangle())
        .onDrag {
            if let fileURL = exportAction() {
                DispatchQueue.main.async { NSApp.keyWindow?.orderOut(nil) }
                return NSItemProvider(object: fileURL as NSURL)
            }
            return NSItemProvider()
        }
    }
}
