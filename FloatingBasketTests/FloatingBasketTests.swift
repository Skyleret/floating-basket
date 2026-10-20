//
//  FloatingBasketTests.swift
//  FloatingBasketTests
//
//  Created by Skyler on 18/10/2026.
//

import Testing
import AppKit
@testable import FloatingBasket

struct FloatingBasketTests {

    private func fileBackedTextPayload(for url: URL) -> BasketPayload {
        .text("print(\"hello\")", metadata: [
            "sourceFile": url.lastPathComponent,
            BasketPayload.sourceFileURLKey: url.path
        ])
    }

    @Test func originalFileOptionIsOfferedFirstForCodeFiles() throws {
        let url = URL(fileURLWithPath: "/tmp/example.py")
        let payload = fileBackedTextPayload(for: url)

        let converters = ConverterRegistry.shared.converters(for: payload)
        let original = try #require(converters.first)

        #expect(original.id == "original-file-converter")
        #expect(original.targetExtension == "py")
        #expect(try original.convert(payload: payload) == url)
    }

    @Test func originalFileOptionIsOfferedFirstForImageFiles() throws {
        let url = URL(fileURLWithPath: "/tmp/example.webp")
        let image = NSImage(size: NSSize(width: 1, height: 1))
        let payload = BasketPayload.image(image, metadata: [
            "sourceFile": url.lastPathComponent,
            BasketPayload.sourceFileURLKey: url.path
        ])

        let converters = ConverterRegistry.shared.converters(for: payload)
        let original = try #require(converters.first)

        #expect(original.id == "original-file-converter")
        #expect(original.targetExtension == "webp")
        #expect(payload.sourceFileURL == url)
        #expect(payload.displayTitle == "example.webp")
    }

    @Test func originalFileOptionIsOfferedForUnsupportedFiles() {
        let url = URL(fileURLWithPath: "/tmp/archive.bin")
        let converters = ConverterRegistry.shared.converters(for: .file(url))

        #expect(converters.count == 1)
        #expect(converters.first?.id == "original-file-converter")
        #expect(converters.first?.targetExtension == "bin")
    }

    @Test func ingestedCodeFileOffersOriginalFileOption() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("example-\(UUID().uuidString).py")
        try "print(\"hello\")".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let pasteboard = NSPasteboard(
            name: NSPasteboard.Name("FloatingBasketTests-\(UUID().uuidString)")
        )
        pasteboard.clearContents()
        pasteboard.writeObjects([url as NSURL])

        let payloads = IngestionService().parsePasteboard(pasteboard)
        let payload = try #require(payloads.first)

        #expect(payload.sourceFileURL == url)

        let converters = ConverterRegistry.shared.converters(for: payload)
        let original = try #require(converters.first)
        #expect(original.id == "original-file-converter")
        #expect(original.targetExtension == "py")
    }

    @Test func clipboardTextHasNoOriginalFileOption() {
        let converters = ConverterRegistry.shared.converters(for: .text("hello"))

        #expect(converters.contains { $0.id == "original-file-converter" } == false)
    }

    @MainActor
    @Test func droppedCodeFileKeepsItsSourceFormatAndOffersOriginalFirst() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dropped-\\(UUID().uuidString).py")
        try "print(\"hello\")".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        // Simulates the payload produced by BasketIngestionWindowView.onDrop.
        let payload = BasketIngestionWindowView.payloadForDroppedFile(url)

        #expect(payload.sourceFileURL == url)

        let converters = ConverterRegistry.shared.converters(for: payload)
        let original = try #require(converters.first)
        #expect(original.id == "original-file-converter")
        #expect(original.targetExtension == "py")
        #expect(try original.convert(payload: payload) == url)
    }

    @Test func inMemoryImageHasNoOriginalFileOption() {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        let converters = ConverterRegistry.shared.converters(for: .image(image))

        #expect(converters.contains { $0.id == "original-file-converter" } == false)
    }
}
