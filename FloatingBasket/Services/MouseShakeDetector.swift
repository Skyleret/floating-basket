//
//  MouseShakeDetector.swift
//  FloatingBasket
//
//  Created by Skyler on 19/10/2026.
//


import Foundation
import AppKit

public final class MouseShakeDetector: ObservableObject {
    public static let shared = MouseShakeDetector()
    
    private var eventMonitor: Any?
    private var lastPositions: [(point: NSPoint, time: TimeInterval)] = []
    private var shakeCount = 0
    private var lastDirection: CGFloat = 0
    
    public var onShakeDetected: (() -> Void)?
    
    private init() {}
    
    public func startMonitoring() {
        // Monitor global or local mouse movements
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.processEvent(event)
        }
        
        // Also monitor local events just in case
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
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
        let currentPoint = NSEvent.mouseLocation
        let currentTime = CACurrentMediaTime()
        
        lastPositions.append((point: currentPoint, time: currentTime))
        
        // Keep only the last 0.5 seconds of movement
        lastPositions = lastPositions.filter { currentTime - $0.time < 0.5 }
        
        guard lastPositions.count > 5 else { return }
        
        let deltaX = currentPoint.x - lastPositions[lastPositions.count - 2].point.x
        
        // Check for significant horizontal movement and direction reversal
        if abs(deltaX) > 5.0 {
            let currentDirection = deltaX > 0 ? 1.0 : -1.0
            if lastDirection != 0 && currentDirection != lastDirection {
                shakeCount += 1
                if shakeCount >= 4 { // 4 rapid back-and-forth reversals trigger a shake
                    shakeCount = 0
                    DispatchQueue.main.async {
                        self.onShakeDetected?()
                    }
                }
            }
            lastDirection = currentDirection
        }
    }
}