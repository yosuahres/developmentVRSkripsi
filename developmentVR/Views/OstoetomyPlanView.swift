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
    @State private var mandibleModelEntity: ModelEntity?
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero 
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var currentScale: Float = 0.1

    var body: some View {
        RealityView { content in
            if let entity = try? await Entity(named: "Mandible", in: realityKitContentBundle) {
                if let mandible = entity as? ModelEntity {
                    let mandibleAnchor = AnchorEntity(world: [0, 1.5, -2])
                    mandibleAnchor.addChild(mandible)
                    mandible.scale = [currentScale, currentScale, currentScale]
                    //facing right
                    mandible.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])
                    
                    content.add(mandibleAnchor)
                    mandibleModelEntity = mandible
                    mandibleAnchorWorldPosition = SIMD3<Float>(0, 1.5, -2)
                }
            } else {
                if let selectedCaseGroup = appState.selectedCaseGroup,
                   let usdzURL = selectedCaseGroup.usdzURL {
                    do {
                        let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, scale: 1.0)
                        let anchor = AnchorEntity(world: [0, 1.5, -2])
                        anchor.addChild(visualization.entity)
                        visualization.entity.scale = [currentScale, currentScale, currentScale]
                        visualization.entity.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])
                        
                        content.add(anchor)
                        objectAnchorVisualization = visualization
                        mandibleModelEntity = visualization.modelEntity
                        mandibleAnchorWorldPosition = SIMD3<Float>(0, 1.5, -2)
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
            
        } update: { content in
            // No plane rendering logic here
        }
        .simultaneousGesture(Gestures.tapGesture(modelEntity: Binding(
            get: { mandibleModelEntity },
            set: { _ in }
        ), appState: appState, mandibleAnchorWorldPosition: mandibleAnchorWorldPosition))
        .simultaneousGesture(Gestures.dragGesture(modelEntity: Binding(
            get: { objectAnchorVisualization?.modelEntity },
            set: { _ in }
        ), lastTranslation: $lastDragTranslation))
        .simultaneousGesture(Gestures.rotationGesture(modelEntity: Binding(
            get: { objectAnchorVisualization?.modelEntity },
            set: { _ in }
        ), currentAngle: $currentAngle))
    }
}
