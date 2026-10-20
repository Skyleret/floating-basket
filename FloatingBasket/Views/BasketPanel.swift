//
//  BasketPanel.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers


/// AppKit drop destination used to read Finder's raw dragging pasteboard.
/// SwiftUI's NSItemProvider representation can omit the file URL even when
/// the underlying Finder drag pasteboard contains one.
private struct AppKitDropTarget: NSViewRepresentable {
    @Binding var isTargeted: Bool
    let onDrop: (NSPasteboard) -> Bool

    func makeNSView(context: Context) -> DropView {
        let view = DropView()
        view.onTargetedChange = { targeted in
            DispatchQueue.main.async {
                self.isTargeted = targeted
            }
        }
        view.onDrop = onDrop
        return view
    }

    func updateNSView(_ nsView: DropView, context: Context) {
        nsView.onDrop = onDrop
        nsView.onTargetedChange = { targeted in
            DispatchQueue.main.async {
                self.isTargeted = targeted
            }
        }
    }

    final class DropView: NSView {
        var onDrop: ((NSPasteboard) -> Bool)?
        var onTargetedChange: ((Bool) -> Void)?

        private let supportedTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            .string,
            NSPasteboard.PasteboardType("public.plain-text"),
            .tiff,
            .png
        ]

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            registerForDraggedTypes(supportedTypes)
        }

        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            guard accepts(sender.draggingPasteboard) else {
                onTargetedChange?(false)
                return []
            }

            onTargetedChange?(true)
            return .copy
        }

        override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
            guard accepts(sender.draggingPasteboard) else {
                onTargetedChange?(false)
                return []
            }

            onTargetedChange?(true)
            return .copy
        }

        override func draggingExited(_ sender: NSDraggingInfo?) {
            onTargetedChange?(false)
        }

        override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
            accepts(sender.draggingPasteboard)
        }

        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            defer { onTargetedChange?(false) }
            return onDrop?(sender.draggingPasteboard) ?? false
        }

        private func accepts(_ pasteboard: NSPasteboard) -> Bool {
            guard let types = pasteboard.types else { return false }
            return types.contains(.fileURL)
                || types.contains(.string)
                || types.contains(NSPasteboard.PasteboardType("public.plain-text"))
                || types.contains(.tiff)
                || types.contains(.png)
        }
    }
}

public final class BasketPanel: NSPanel {
    public init(contentRect: NSRect, backing: NSPanel.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .borderless, .titled, .closable, .fullSizeContentView], backing: backing, defer: flag)
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
    @State private var payload: BasketPayload?
    @State private var isExpanded = false
    @State private var isHoveredOrTargeted = false
    @State private var mouseUpMonitor: Any?
    
    private let exportManager = ExportManager.shared
    
    public init(payload: BasketPayload? = nil) {
        _payload = State(initialValue: payload)
    }
    
    public var body: some View {
        Group {
            if isExpanded, let payload = payload {
                SingleItemWindowView(payload: payload)
            } else {
                dropboxView
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        //.animation(.easeInOut(duration: 0.2), value: isHoveredOrTargeted)
        .onAppear {
            setupMouseUpMonitor()
        }
        .onDisappear {
            removeMouseUpMonitor()
        }
    }
    
    private var dropboxView: some View {
        VStack(spacing: 8) {
            Image(systemName: "basket.fill")
                .font(.system(size: 32))
                .foregroundColor(isHoveredOrTargeted ? .white : .accentColor)
            
            Text("Drop here to open")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isHoveredOrTargeted ? .white : .primary)
            
            Text(payload?.displayTitle ?? "Drag a file here")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 240, height: 115) // Same size as the expanded window
        .background(
            isHoveredOrTargeted
                ? AnyShapeStyle(Color.accentColor)
                : AnyShapeStyle(.ultraThinMaterial)
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isHoveredOrTargeted ? Color.primary : Color.accentColor.opacity(0.5), lineWidth: isHoveredOrTargeted ? 2 : 1.5)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        .contentShape(Rectangle()) // Ensures the entire box catches drops smoothly without gaps
        .background(
            AppKitDropTarget(isTargeted: $isHoveredOrTargeted) { pasteboard in
                // Prefer Finder's original file URL before considering text or image data.
                if let objects = pasteboard.readObjects(
                    forClasses: [NSURL.self],
                    options: [.urlReadingFileURLsOnly: true]
                ) as? [NSURL], let nsURL = objects.first {
                    // Finder may provide a file-reference URL. Convert it to a
                    // path-based file URL before passing it to the existing pipeline.
                    let fileURL = nsURL as URL
                    let url = fileURL.standardizedFileURL
                    let newPayload = Self.payloadForDroppedFile(url)
                    DispatchQueue.main.async {
                        self.payload = newPayload
                        self.expandWindow()
                    }
                    return true
                }

                // Preserve support for text dragged from apps that provide text only.
                let plainTextType = NSPasteboard.PasteboardType("public.plain-text")
                if let string = pasteboard.string(forType: .string)
                    ?? pasteboard.string(forType: plainTextType), !string.isEmpty {
                    DispatchQueue.main.async {
                        self.payload = BasketPayload.text(string)
                        self.expandWindow()
                    }
                    return true
                }

                // Preserve support for in-memory image drops.
                if let images = pasteboard.readObjects(
                    forClasses: [NSImage.self],
                    options: nil
                ) as? [NSImage], let image = images.first {
                    DispatchQueue.main.async {
                        self.payload = BasketPayload.image(image)
                        self.expandWindow()
                    }
                    return true
                }

                return false
            }
        )
    }
    
    static func payloadForDroppedFile(_ url: URL) -> BasketPayload {
        let ext = url.pathExtension.lowercased()

        // Word documents: extract their text.
        if ext == "docx",
           let attributed = try? NSAttributedString(
               url: url,
               options: [.documentType: NSAttributedString.DocumentType.officeOpenXML],
               documentAttributes: nil
           ) {
            return .text(
                attributed.string,
                metadata: [
                    "sourceFile": url.lastPathComponent,
                    BasketPayload.sourceFileURLKey: url.path
                ]
            )
        }

        // Images: preserve them as image payloads, keeping the source path so the
        // original file can still be exported.
        if ["png", "jpg", "jpeg", "heic", "webp"].contains(ext),
           let image = NSImage(contentsOf: url) {
            return .image(
                image,
                metadata: [
                    "sourceFile": url.lastPathComponent,
                    BasketPayload.sourceFileURLKey: url.path
                ]
            )
        }

        // Text and code files: read their contents, not their path or clipboard.
        if textExtensions.contains(ext),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            return .text(
                content,
                metadata: [
                    "sourceFile": url.lastPathComponent,
                    BasketPayload.sourceFileURLKey: url.path
                ]
            )
        }

        // Rich-text files need decoding rather than reading their raw bytes as text.
        if ext == "rtf",
           let attributed = try? NSAttributedString(
               url: url,
               options: [.documentType: NSAttributedString.DocumentType.rtf],
               documentAttributes: nil
           ) {
            return .text(
                attributed.string,
                metadata: [
                    "sourceFile": url.lastPathComponent,
                    BasketPayload.sourceFileURLKey: url.path
                ]
            )
        }

        // Preserve unsupported file types as original files.
        return .file(url)
    }

    private static let textExtensions: Set<String> = [
        "txt", "md", "markdown", "html", "htm", "xml",
        "json", "yml", "yaml", "toml", "ini", "cfg", "csv", "tsv",
        "py", "swift", "js", "jsx", "ts", "tsx", "c", "h", "cpp", "hpp",
        "m", "mm", "cs", "java", "kt", "kts", "go", "rs", "rb", "php",
        "sh", "bash", "zsh", "sql", "css", "scss"
    ]
    
    private func expandWindow() {
        guard !isExpanded else { return }
        isExpanded = true
        removeMouseUpMonitor()
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
            let isInsideBasket = NSApp.windows.contains {
                $0 is BasketPanel && $0.frame.contains(mouseLocation)
            }
            
            // A mouse-up inside the dropbox is handled by onDrop, which ingests
            // the dragged item and expands the window. Only discard the window
            // when the drag ended outside of it.
            guard !isInsideBasket else { return }
            
            NSApp.windows.forEach { window in
                if window is BasketPanel {
                    window.orderOut(nil)
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
                                title: converter is OriginalFileConverter ? "Original" : "[\(converter.keyShortcut)]",
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
                // `contentsOf:` registers the file's actual UTI (e.g.
                // public.python-script) in addition to public.file-url, so the
                // dragged item keeps its original format instead of becoming a
                // generic URL/plain-text item.
                return NSItemProvider(contentsOf: fileURL)
                    ?? NSItemProvider(object: fileURL as NSURL)
            }
            return NSItemProvider()
        }
    }
}
