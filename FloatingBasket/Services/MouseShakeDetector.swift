//
//  MouseShakeDetector.swift
//  FloatingBasket
//
//  Created by Skyler on 19/10/2026.
//

import Foundation
import AppKit
import QuartzCore

public final class MouseShakeDetector {
    public static let shared = MouseShakeDetector()

    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    private var lastPositions: [(point: NSPoint, time: TimeInterval)] = []
    private var shakeCount = 0
    private var lastDirection: CGFloat = 0

    // A drag is considered eligible only after the system drag pasteboard
    // changes during the current mouse gesture. This avoids stale contents
    // making ordinary text selections/canvas drags trigger the basket.
    private let dragPasteboard = NSPasteboard(name: .drag)
    private var dragPasteboardChangeCountAtMouseDown: Int?
    private var isCurrentGestureDraggingItem = false
    private var didTriggerForCurrentGesture = false

    // The activation zone is centered along the top of the screen's visible
    // area. Using visibleFrame makes this portable across notched and non-notched
    // Macs, different resolutions, and external displays.
    private let pinZoneWidth: CGFloat = 180
    private let pinZoneHeight: CGFloat = 48
    private let pinZoneTopInset: CGFloat = 4

    public var onShakeWhileDraggingDetected: (() -> Void)?

    private init() {}

    public func startMonitoring() {
        guard globalEventMonitor == nil, localEventMonitor == nil else {
            return
        }

        let events: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .leftMouseUp,
            .mouseMoved,
            .leftMouseDragged
        ]

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: events
        ) { [weak self] event in
            self?.processEvent(event)
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: events
        ) { [weak self] event in
            self?.processEvent(event)
            return event
        }
    }

    public func stopMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }

        resetGesture()
        dragPasteboardChangeCountAtMouseDown = nil
    }

    private func processEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            resetGesture()
            dragPasteboardChangeCountAtMouseDown = dragPasteboard.changeCount
            return

        case .leftMouseUp:
            resetGesture()
            dragPasteboardChangeCountAtMouseDown = nil
            return

        case .mouseMoved, .leftMouseDragged:
            break

        default:
            return
        }

        // Require an active left-button drag.
        let isDragging =
            (NSEvent.pressedMouseButtons & 1) != 0
            || event.type == .leftMouseDragged

        guard isDragging else {
            resetGesture()
            return
        }

        // Do not count ordinary mouse movement or dragging.
        // Wait for the system drag pasteboard to change from its
        // mouse-down baseline during this particular gesture.
        guard let baseline = dragPasteboardChangeCountAtMouseDown else {
            return
        }

        if !isCurrentGestureDraggingItem {
            guard dragPasteboard.changeCount != baseline else {
                return
            }

            isCurrentGestureDraggingItem = true
        }

        guard !didTriggerForCurrentGesture else {
            return
        }

        let currentPoint = NSEvent.mouseLocation

        // Entering the top-center pin zone summons the normal empty intake
        // window. The item is still dropped into that window through AppKitDropTarget.
        if isInsidePinZone(currentPoint) {
            triggerBasket()
            return
        }

        detectShake(at: currentPoint)
    }

    private func isInsidePinZone(_ point: NSPoint) -> Bool {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) })
                ?? NSScreen.main else {
            return false
        }

        let visible = screen.visibleFrame
        let width = min(pinZoneWidth, visible.width)
        let height = min(pinZoneHeight, visible.height)

        let zone = NSRect(
            x: visible.midX - width / 2,
            y: visible.maxY - height - pinZoneTopInset,
            width: width,
            height: height
        )

        return zone.contains(point)
    }

    private func detectShake(at currentPoint: NSPoint) {
        let currentTime = CACurrentMediaTime()

        lastPositions.append((point: currentPoint, time: currentTime))
        lastPositions.removeAll { currentTime - $0.time >= 0.5 }

        guard lastPositions.count > 5 else {
            return
        }

        let previousPoint = lastPositions[lastPositions.count - 2].point
        let deltaX = currentPoint.x - previousPoint.x

        guard abs(deltaX) > 5.0 else {
            return
        }

        let currentDirection: CGFloat = deltaX > 0 ? 1 : -1

        if lastDirection != 0 && currentDirection != lastDirection {
            shakeCount += 1

            if shakeCount >= 4 {
                triggerBasket()
                return
            }
        }

        lastDirection = currentDirection
    }

    private func triggerBasket() {
        guard !didTriggerForCurrentGesture else {
            return
        }

        didTriggerForCurrentGesture = true
        resetShakeDetection()

        DispatchQueue.main.async { [weak self] in
            self?.onShakeWhileDraggingDetected?()
        }
    }

    private func resetShakeDetection() {
        lastPositions.removeAll()
        shakeCount = 0
        lastDirection = 0
    }

    private func resetGesture() {
        resetShakeDetection()
        isCurrentGestureDraggingItem = false
        didTriggerForCurrentGesture = false
    }
}
