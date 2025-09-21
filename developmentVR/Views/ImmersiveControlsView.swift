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
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var isMainWindowVisible = false
    
    var body: some View {
        RealityView { content in
            let anchor = AnchorEntity(.head)
            anchor.position = [0, 0, 0] 
            content.add(anchor)
        }
        
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
                
                Divider()
                
                Toggle("Show Main Window", isOn: $isMainWindowVisible)
                    .onChange(of: isMainWindowVisible) { _, newValue in
                        if newValue {
                            openWindow(id: "main")
                        } else {
                            dismissWindow(id: "main")
                        }
                    }
                
                Spacer()
                
                Button("Add Osteotomy Plane") {
                    let modelPosition = appState.currentModelPosition
                    
                    // Add some variety to spawn positions around the model
                    let planeCount = appState.osteotomyPlanes.count
                    let angle = Float(planeCount) * 0.5 // Spread planes around
                    let radius: Float = 0.15 // Distance from model
                    
                    let offsetX = cos(angle) * radius
                    let offsetZ = sin(angle) * radius
                    let spawnPosition = modelPosition + [offsetX, 0.05, offsetZ]
                    
                    appState.osteotomyPlanes.append(
                        OstoetomyPlan(position: spawnPosition, rotation: simd_quatf(angle: 0, axis: [0,1,0]))
                    )
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close Immersive Space") {
                    Task {
                        await dismissImmersiveSpace()
                        appState.immersiveSpaceState = .closed
                        openWindow(id: "main")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .glassBackgroundEffect()
    }
}
