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
                Text("FloatingBasket")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { items.removeAll() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .help("Clear Basket")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            
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
                                    let provider = NSItemProvider()
                                    // Handle drag out behavior or item reference
                                    return provider
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
            let ingestion = IngestionService()
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    _ = provider.loadObject(ofClass: NSURL.self) { url, _ in
                        if let fileURL = url as? URL {
                            Task { @MainActor in
                                items.append(.file(fileURL))
                            }
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") {
                    _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                        if let text = string as? String {
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
