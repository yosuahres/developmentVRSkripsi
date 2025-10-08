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
                    
                    //controls
                    HStack {
                        VStack(alignment: .leading, spacing: 40) {

                            //ruler toggle
                            HStack(spacing: 40) {
                                Image(systemName: "ruler.fill")
                                    .font(.system(size: 80))
                                
                                Button(action: {
                                    self.appState.rulerManager.toggleRulerVisibility()
                                }) {
                                    Image(systemName: self.appState.rulerManager.isRulerVisible ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(self.appState.rulerManager.isRulerVisible ? .green : .red)
                                }
                                
                                Spacer()
                                    .frame(width: 85) 
                            }
                            
                            //maxilla model toggle
                            HStack(spacing: 40) {
                                Image(systemName: "cube.fill")
                                    .font(.system(size: 80))
                                
                                Button(action: {
                                    self.appState.toggleMaxillaVisibility()
                                }) {
                                    Image(systemName: self.appState.isMaxillaVisible ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(self.appState.isMaxillaVisible ? .orange : .gray)
                                }
                                
                                Button(action: {
                                    self.appState.toggleOpacityMaxilla()
                                }) {
                                    Image(systemName: self.appState.maxillaOpacityToggle ? "circle.lefthalf.filled" : "circle.dotted")
                                        .font(.system(size: 80))
                                        .foregroundColor(self.appState.maxillaOpacityToggle ? .blue : .gray)
                                }
                            }
                            
                            //mandible model toggle
                            HStack(spacing: 40) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 80))
                                
                                Button(action: {
                                    self.appState.toggleMandibleVisibility()
                                }) {
                                    Image(systemName: self.appState.isMandibleVisible ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(self.appState.isMandibleVisible ? .red : .gray)
                                }
                                
                                Button(action: {
                                    self.appState.toggleOpacityMandible()
                                }) {
                                    Image(systemName: self.appState.mandibleOpacityToggle ? "circle.lefthalf.filled" : "circle.dotted")
                                        .font(.system(size: 80))
                                        .foregroundColor(self.appState.mandibleOpacityToggle ? .purple : .gray)
                                }
                            }
                            
                            // Target Side Selector
                            Picker("Target Side", selection: $appState.currentTargetSide) {
                                Text("Left").tag(TargetSide.left)
                                Text("Right").tag(TargetSide.right)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                            .padding(.top, 20)
                            
                            Button("Spawn Plane") {
                                appState.triggerSpawnPlane()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .padding(.top, 20)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    HStack {
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
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .frame(width: 700, height: 800)
        .glassBackgroundEffect()
    }
}
