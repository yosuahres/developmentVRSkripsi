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
    @State var arKitSession = ARKitSession()

    var body: some View {
        RealityView { content in
            //empty
        }
        .onAppear {
            appState.isARSessionActive = true
        }
        .onDisappear {
            arKitSession.stop()
            appState.isARSessionActive = false
        }
        .overlay(alignment: .bottom) {
            Button("Stop Tracking") {
                arKitSession.stop()
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
