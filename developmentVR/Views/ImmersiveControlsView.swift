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
