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
        
        // Disable full-background window dragging so item drags work properly
        self.isMovableByWindowBackground = false
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

public struct BasketWindowView: View {
    @State private var items: [BasketPayload] = []
    private let ingestionService = IngestionService()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("FloatingBasket")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    NSApp.keyWindow?.orderOut(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Basket")
                
                Button(action: { items.removeAll() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .help("Clear Basket")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .contentShape(Rectangle()) // Make the whole header area act as a hit target for dragging
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if let window = NSApp.keyWindow {
                            var frame = window.frame
                            frame.origin.x += value.translation.width
                            frame.origin.y -= value.translation.height // AppKit vs SwiftUI coordinate flip
                            window.setFrame(frame, display: true)
                        }
                    }
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if items.isEmpty {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                            Text("Drop clips or files here")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 180, height: 80)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        ForEach(items) { item in
                            ItemThumbnailView(item: item)
                                .onDrag {
                                    let converters = ExportManager.shared.converters(for: item)
                                    if let converter = converters.first,
                                       let url = try? ExportManager.shared.export(payload: item, using: converter) {
                                        return NSItemProvider(object: url as NSURL)
                                    }
                                    
                                    switch item {
                                    case .text(let text, _):
                                        return NSItemProvider(object: text as NSString)
                                    case .image(let image):
                                        if let tiff = image.tiffRepresentation,
                                           let rep = NSBitmapImageRep(data: tiff),
                                           let png = rep.representation(using: .png, properties: [:]) {
                                            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FloatingBasket", isDirectory: true)
                                            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                                            let fileURL = tempDir.appendingPathComponent("image-\(UUID().uuidString).png")
                                            try? png.write(to: fileURL)
                                            return NSItemProvider(object: fileURL as NSURL)
                                        }
                                        return NSItemProvider()
                                    case .file(let url):
                                        return NSItemProvider(object: url as NSURL)
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 90)
            
            Spacer(minLength: 0)
        }
        .frame(width: 220, height: 130)
        // 1. Give the view an opaque visual background so mouse hit-testing registers drops cleanly
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        // 2. Use native Apple drop handling integrated directly with your IngestionService
        .onDrop(of: [.fileURL, .image, .text], isTargeted: nil) { providers in
            Task {
                for provider in providers {
                    // 1. Try loading as a File URL first
                    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                        if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                            await MainActor.run { items.append(.file(url)) }
                            continue
                        } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) {
                            await MainActor.run { items.append(.file(url)) }
                            continue
                        }
                    }
                    
                    // 2. Try loading as an Image
                    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        if let image = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier) as? NSImage {
                            await MainActor.run { items.append(.image(image)) }
                            continue
                        } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier) as? Data,
                                  let image = NSImage(data: data) {
                            await MainActor.run { items.append(.image(image)) }
                            continue
                        }
                    }
                    
                    // 3. Try loading as Text
                    if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                        if let text = try? await provider.loadItem(forTypeIdentifier: UTType.text.identifier) as? String {
                            await MainActor.run { items.append(.text(text)) }
                            continue
                        } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.text.identifier) as? Data,
                                  let text = String(data: data, encoding: .utf8) {
                            await MainActor.run { items.append(.text(text)) }
                            continue
                        }
                    }
                }
            }
            return true
        }
    }
}

private struct ItemThumbnailView: View {
    let item: BasketPayload
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
            
            VStack(spacing: 4) {
                switch item {
                case .text:
                    Image(systemName: "doc.text")
                        .font(.system(size: 22))
                    Text(item.displayTitle)
                        .font(.system(size: 9))
                        .lineLimit(1)
                case .image:
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                    Text(item.displayTitle)
                        .font(.system(size: 9))
                        .lineLimit(1)
                case .file(let url):
                    Image(systemName: "doc")
                        .font(.system(size: 22))
                    Text(url.lastPathComponent)
                        .font(.system(size: 9))
                        .lineLimit(1)
                }
            }
            .padding(6)
        }
        .frame(width: 70, height: 70)
        .cornerRadius(8)
    }
}

#Preview {
    BasketWindowView()
        .padding()
        .background(Color.gray.opacity(0.3))
}
