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
        
        ZStack {
            if let selectedCase = appState.selectedCaseGroup {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(selectedCase.group.name)
                                .font(.extraLargeTitle2)
                                .fontWeight(.semibold)
                            Text(selectedCase.group.description)
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    //controls
                    HStack {
                        HStack(spacing: 40) {
                            Button(action: { 
                                appState.rulerManager.toggleRulerMode()
                            }) {
                                Image(systemName: appState.rulerManager.isRulerMode ? "ruler.fill" : "ruler")
                                    .font(.system(size: 80))
                                    .foregroundColor(appState.rulerManager.isRulerMode ? .blue : .gray)
                            }
                            
                            Button(action: {
                                appState.rulerManager.toggleRulerVisibility()
                            }) {
                                Image(systemName: appState.rulerManager.isRulerVisible ? "eye.fill" : "eye.slash.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(appState.rulerManager.isRulerVisible ? .green : .red)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("Close") {
                        Task {
                            await appState.closeControlsWindow(dismissWindow: dismissWindow)
                            await dismissImmersiveSpace()
                            appState.immersiveSpaceState = .closed
                            openWindow(id: "main")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
        .padding()
        .frame(width: 1100, height: 1200)
        .glassBackgroundEffect()
    }
}
