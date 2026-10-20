
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

    // Snapshot the drag pasteboard when each mouse drag begins.
    // Old pasteboard contents must not qualify a new gesture as a drag.
    private let dragPasteboard = NSPasteboard(name: .drag)
    private var dragPasteboardChangeCountAtMouseDown: Int?
    private var isCurrentGestureDraggingItem = false

    public var onShakeWhileDraggingDetected: (() -> Void)?

    private init() {}

    public func startMonitoring() {
        // Avoid installing duplicate monitors.
        guard globalEventMonitor == nil, localEventMonitor == nil else {
            return
        }

        let events: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .leftMouseUp,
            .mouseMoved,
            .leftMouseDragged
        ]

        // Events from other applications.
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: events
        ) { [weak self] event in
            self?.processEvent(event)
        }

        // Events delivered to FloatingBasket itself.
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
            // Establish a fresh baseline for this gesture.
            resetGesture()
            dragPasteboardChangeCountAtMouseDown =
                dragPasteboard.changeCount
            isCurrentGestureDraggingItem = false
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

        detectShake(at: NSEvent.mouseLocation)
    }

    private func detectShake(at currentPoint: NSPoint) {
        let currentTime = CACurrentMediaTime()

        lastPositions.append((point: currentPoint, time: currentTime))
        lastPositions.removeAll {
            currentTime - $0.time >= 0.5
        }

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
                resetShakeDetection()

                DispatchQueue.main.async { [weak self] in
                    self?.onShakeWhileDraggingDetected?()
                }
            }
        }

        lastDirection = currentDirection
    }

    private func resetShakeDetection() {
        lastPositions.removeAll()
        shakeCount = 0
        lastDirection = 0
    }

    private func resetGesture() {
        resetShakeDetection()
        isCurrentGestureDraggingItem = false
    }
}
