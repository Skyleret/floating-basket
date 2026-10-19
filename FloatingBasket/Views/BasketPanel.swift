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
        self.isMovableByWindowBackground = false // Disabled so items can be dragged out without moving window
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

public struct BasketWindowView: View {
    @State private var items: [BasketPayload] = []
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .help("Drag to move window")
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
            .gesture(
                            DragGesture().onChanged { value in
                                if let window = NSApp.keyWindow {
                                    let currentOrigin = window.frame.origin
                                    let newOrigin = NSPoint(x: currentOrigin.x + value.translation.width, y: currentOrigin.y - value.translation.height)
                                    window.setFrameOrigin(newOrigin)
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
                                    // Export item using available converters or fall back to raw data
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
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        .onDrop(of: [.fileURL, .image, .text], isTargeted: nil) { providers in
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, _) in
                        var fileURL: URL?
                        if let url = urlData as? URL {
                            fileURL = url
                        } else if let data = urlData as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            fileURL = url
                        } else if let path = urlData as? String {
                            fileURL = URL(fileURLWithPath: path)
                        }
                        if let fileURL = fileURL {
                            Task { @MainActor in
                                items.append(.file(fileURL))
                            }
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier("public.image") {
                    provider.loadObject(ofClass: NSImage.self) { image, _ in
                        if let img = image as? NSImage {
                            Task { @MainActor in
                                items.append(.image(img))
                            }
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") || provider.hasItemConformingToTypeIdentifier("public.text") {
                    provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { (textData, _) in
                        var textContent: String?
                        if let str = textData as? String {
                            textContent = str
                        } else if let data = textData as? Data {
                            textContent = String(data: data, encoding: .utf8)
                        }
                        if let text = textContent {
                            Task { @MainActor in
                                items.append(.text(text))
                            }
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
