//
//  OstoetomyPlanView.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct OstoetomyPlanView: View {
    @ObservedObject var appState: AppState
    @State private var objectAnchorVisualization: ObjectAnchorVisualization?
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var currentScale: Float = 0.001

    var body: some View {
        RealityView { content in
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let usdzURL = selectedCaseGroup.usdzURL {
                do {
                    let fragmentGroup = selectedCaseGroup.loadedFragmentGroups.first
                    let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, fragmentGroup: fragmentGroup, scale: currentScale)
                    let anchor = AnchorEntity(world: [0, 1.5, -2])
                    anchor.addChild(visualization.entity)
                    content.add(anchor)
                    objectAnchorVisualization = visualization
                } catch {
                    print("Error loading or creating visualization: \(error)")
                    if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                        content.add(fallbackScene)
                    }
                }
            } else {
                if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(fallbackScene)
                }
            }
        }
        .gesture(Gestures.dragGesture(modelEntity: .constant(objectAnchorVisualization?.modelEntity), lastTranslation: $lastDragTranslation))
        .simultaneousGesture(Gestures.rotationGesture(modelEntity: .constant(objectAnchorVisualization?.modelEntity), currentAngle: $currentAngle))
    }
}
