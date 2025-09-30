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
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var currentScale: Float = 0.001

    var body: some View {
        let planesState = appState.osteotomyPlanes

        RealityView { content in
            if let entity = try? await Entity(named: "Mandible", in: realityKitContentBundle) {
                if let mandible = entity as? ModelEntity {
                    let mandibleAnchor = AnchorEntity(world: .zero)
                    mandibleAnchor.addChild(mandible)
                    content.add(mandibleAnchor)
                    mandibleModelEntity = mandible
                }
            } else {
                if let selectedCaseGroup = appState.selectedCaseGroup,
                   let usdzURL = selectedCaseGroup.usdzURL {
                    do {
                        let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, scale: currentScale)
                        let anchor = AnchorEntity(world: [0, 1.5, -2])
                        anchor.addChild(visualization.entity)
                        content.add(anchor)
                        objectAnchorVisualization = visualization
                        mandibleModelEntity = visualization.modelEntity
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
            // Remove existing planes to prevent duplicates
            content.entities.removeAll { entity in
                entity.name.hasPrefix("PlaneAnchor_")
            }
            
            let visiblePlanes = planesState.filter { $0.isVisible }
            
            for planeDef in visiblePlanes {
                let plane = ModelEntity(
                    mesh: .generatePlane(width: 0.1, height: 0.1), // 10cm x 10cm
                    materials: [SimpleMaterial(color: .red, isMetallic: false)] // Opaque red for visibility
                )
                plane.position = SIMD3<Float>(0, 0, 0) // Position relative to its anchor
                plane.orientation = planeDef.rotation
                
                plane.components.set(InputTargetComponent())
                plane.generateCollisionShapes(recursive: true)
                
                let planeAnchor = AnchorEntity(world: planeDef.position)
                planeAnchor.name = "PlaneAnchor_\(planeDef.id.uuidString)"
                planeAnchor.addChild(plane)
                content.add(planeAnchor)
            }
        }
        .simultaneousGesture(Gestures.tapGesture(modelEntity: Binding(
            get: { mandibleModelEntity },
            set: { _ in }
        ), appState: appState))
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
