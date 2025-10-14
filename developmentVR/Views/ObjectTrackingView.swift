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
    var appState: AppState
    var root = Entity()
    
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    @State private var currentVisualization: ObjectAnchorVisualization?
    
    var body: some View {
        RealityView { content, attachments in
            content.add (root)
            
            Task {
//                guard let objectTracking = await appState.startTracking
            }
        }
    }
}
