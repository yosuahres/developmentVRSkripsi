//
//  ObjectTrackingRealityView.swift
//  VisionOSFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 05/05/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ObjectTrackingView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        RealityView { content in
            // This RealityView will be initially blank as requested.
            // ARKitSession will be run in .onAppear.
        }
        .onAppear {
            Task {
                await appState.startTracking()
            }
        }
        .onDisappear {
            // Stop the ARKitSession when the view disappears
            appState.arKitSession?.stop()
            appState.isARSessionActive = false
        }
        .overlay(alignment: .bottom) {
            Button("Stop Tracking") {
                dismissWindow(id: "ar_session")
                appState.isARSessionActive = false
            }
            .font(.system(size: 40))
            .fontWeight(.bold)
            .padding(30)
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .hoverEffect()
        }
    }
}
