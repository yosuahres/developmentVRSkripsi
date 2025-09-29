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
                
                // Toggle("Show Main Window", isOn: $isMainWindowVisible)
                //     .onChange(of: isMainWindowVisible) { _, newValue in
                //         if newValue {
                //             openWindow(id: "main")
                //         } else {
                //             dismissWindow(id: "main")
                //         }
                //     }
                
                // Spacer()
                
                HStack {
                    Button(action: {
                        let allPlanesAreVisible = appState.osteotomyPlanes.allSatisfy { $0.isVisible }
                        for i in 0..<appState.osteotomyPlanes.count {
                            appState.osteotomyPlanes[i].isVisible = !allPlanesAreVisible
                        }
                    }) {
                        Image(systemName: appState.osteotomyPlanes.allSatisfy { $0.isVisible } ? "eye" : "eye.slash")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        if appState.osteotomyPlanes.count > 1 {
                            appState.osteotomyPlanes.removeLast()
                        }
                    }) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.osteotomyPlanes.count <= 1)
                    
                    Button(action: {
                        let modelPosition = appState.currentModelPosition
                        
                        // randomise
                        let planeCount = appState.osteotomyPlanes.count
                        let angle = Float(planeCount) * Float.pi / 3.0  
                        let radius: Float = 0.3  
                        
                        let offsetX = cos(angle) * radius
                        let offsetZ = sin(angle) * radius
                        let offsetY = Float.random(in: -0.1...0.1)  
                        let spawnPosition = modelPosition + [offsetX, offsetY, offsetZ]
                        
                        print("🔵 Creating new plane at position: \(spawnPosition)")
                        
                        appState.osteotomyPlanes.append(
                            OstoetomyPlan(position: spawnPosition, rotation: simd_quatf(angle: 0, axis: [0,1,0]))
                        )
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button("Close Immersive Space") {
                    Task {
                        await appState.closeControlsWindow(dismissWindow: dismissWindow)
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
