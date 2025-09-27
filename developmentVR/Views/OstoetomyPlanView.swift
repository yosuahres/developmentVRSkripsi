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
        let planesState = appState.osteotomyPlanes 
        
        RealityView { content in
            print("🔵 OstoetomyPlanView: Initial RealityView setup")
            if let entity = try? await Entity(named: "Mandible", in: realityKitContentBundle) {
                if let mandible = entity as? ModelEntity {
                    let mandibleAnchor = AnchorEntity(world: .zero)
                    mandibleAnchor.addChild(mandible)
                    content.add(mandibleAnchor)
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
            let removedCount = content.entities.filter { $0.name.hasPrefix("PlaneAnchor_") }.count
            content.entities.removeAll { entity in
                entity.name.hasPrefix("PlaneAnchor_")
            }
            
            let visiblePlanes = planesState.filter { $0.isVisible }
            
            for planeDef in visiblePlanes {
                let plane = ModelEntity(
                    mesh: .generatePlane(width: 0.1, height: 0.1),
                    materials: [SimpleMaterial(color: .red.withAlphaComponent(0.7), isMetallic: false)]
                )
                plane.position = SIMD3<Float>(0, 0, 0)
                plane.orientation = planeDef.rotation
                
                plane.components.set(InputTargetComponent())
                plane.generateCollisionShapes(recursive: true)
                
                let planeAnchor = AnchorEntity(world: planeDef.position)
                planeAnchor.name = "PlaneAnchor_\(planeDef.id.uuidString)"
                planeAnchor.addChild(plane)
                content.add(planeAnchor)
            }
        }
        .gesture(Gestures.dragGesture(modelEntity: Binding(
            get: { objectAnchorVisualization?.modelEntity },
            set: { _ in }
        ), lastTranslation: $lastDragTranslation))
        .simultaneousGesture(Gestures.rotationGesture(modelEntity: Binding(
            get: { objectAnchorVisualization?.modelEntity },
            set: { _ in }
        ), currentAngle: $currentAngle))
    }
}
