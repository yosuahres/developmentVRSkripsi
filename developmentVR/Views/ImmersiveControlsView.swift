//
//  ImmersiveControlsView.swift
//  developmentVR
//
//  Created by HARES on 9/17/25.
//

import SwiftUI
import RealityKit

struct ImmersiveControlsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var body: some View {
        VStack(spacing: 20) {
            if let selectedCase = appState.selectedCaseGroup {
                Text("Currently Viewing:")
                    .font(.headline)
                Text(selectedCase.group.name)
                    .font(.title2)
                Text(selectedCase.group.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                Text("Controls")
                    .font(.headline)
                Text("• Drag to move the model")
                Text("• Rotate gesture to rotate")
                    .padding(.vertical, 2)
                
                Spacer()
                
                Button("Close Immersive Space") {
                    Task {
                        await dismissImmersiveSpace()
                        appState.immersiveSpaceState = .closed
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 300)
        .glassBackgroundEffect()
    }
}