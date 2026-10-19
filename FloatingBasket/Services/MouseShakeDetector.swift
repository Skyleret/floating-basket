//
//  MouseShakeDetector.swift
//  FloatingBasket
//
//  Created by Skyler on 19/10/2026.
//


import Foundation
import AppKit

public final class MouseShakeDetector {
    public static let shared = MouseShakeDetector()
    
    private var eventMonitor: Any?
    private var lastPositions: [(point: NSPoint, time: TimeInterval)] = []
    private var shakeCount = 0
    private var lastDirection: CGFloat = 0
    
    public var onShakeWhileDraggingDetected: (() -> Void)?
    
    private init() {}
    
    public func startMonitoring() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.processEvent(event)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.processEvent(event)
            return event
        }
    }
    
    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func processEvent(_ event: NSEvent) {
        // REQUIREMENT: Only trigger if the user is actively dragging/holding down the left mouse button
        let isDragging = (NSEvent.pressedMouseButtons & 1) != 0 || event.type == .leftMouseDragged
        guard isDragging else {
            // Reset shake counters immediately if they aren't dragging
            shakeCount = 0
            lastPositions.removeAll()
            return
        }
        
        let currentPoint = NSEvent.mouseLocation
        let currentTime = CACurrentMediaTime()
        
        lastPositions.append((point: currentPoint, time: currentTime))
        lastPositions = lastPositions.filter { currentTime - $0.time < 0.5 }
        
        guard lastPositions.count > 5 else { return }
        
        let deltaX = currentPoint.x - lastPositions[lastPositions.count - 2].point.x
        
        if abs(deltaX) > 5.0 {
            let currentDirection = deltaX > 0 ? 1.0 : -1.0
            if lastDirection != 0 && currentDirection != lastDirection {
                shakeCount += 1
                if shakeCount >= 4 { // 4 rapid back-and-forth reversals while dragging
                    shakeCount = 0
                    lastPositions.removeAll()
                    DispatchQueue.main.async {
                        self.onShakeWhileDraggingDetected?()
                    }
                }
            }
            lastDirection = currentDirection
        }
    }
}
