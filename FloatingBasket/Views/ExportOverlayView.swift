//
//  ExportOverlayView.swift
//  FloatingBasket
//
//  Created by Skyler on 18/10/2026.
//


import SwiftUI

public struct ExportOverlayView: View {
    public let payload: BasketPayload
    public let converters: [FileConverter]
    
    public init(payload: BasketPayload, converters: [FileConverter]) {
        self.payload = payload
        self.converters = converters
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Export As:")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            
            if converters.isEmpty {
                Text("Original File / No conversion needed")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            } else {
                ForEach(converters, id: \.id) { converter in
                    HStack(spacing: 8) {
                        Text("[\(converter.keyShortcut)]")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(".\(converter.targetExtension)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}