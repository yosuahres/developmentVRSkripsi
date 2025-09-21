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
    @State private var planeAnchors: [UUID: AnchorEntity] = [:]

    var body: some View {
        RealityView { content in
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
            let currentPlaneIDs = Set(appState.osteotomyPlanes.map { $0.id })
            let existingPlaneIDs = Set(planeAnchors.keys)
            
            for planeID in existingPlaneIDs.subtracting(currentPlaneIDs) {
                if let anchor = planeAnchors[planeID] {
                    content.remove(anchor)
                    planeAnchors.removeValue(forKey: planeID)
                }
            }
            
            for planeDef in appState.osteotomyPlanes {
                if let existingAnchor = planeAnchors[planeDef.id] {
                    existingAnchor.position = planeDef.position
                    if let plane = existingAnchor.children.first as? ModelEntity {
                        plane.orientation = planeDef.rotation
                    }
                } else {
                    let plane = ModelEntity(
                        mesh: .generatePlane(width: 0.1, height: 0.1),
                        materials: [SimpleMaterial(color: .red.withAlphaComponent(0.7), isMetallic: false)]
                    )
                    plane.position = SIMD3<Float>(0, 0, 0)
                    plane.orientation = planeDef.rotation
                    
                    plane.components.set(InputTargetComponent())
                    plane.generateCollisionShapes(recursive: true)
                    
                    let planeAnchor = AnchorEntity(world: planeDef.position)
                    planeAnchor.addChild(plane)
                    content.add(planeAnchor)
                    planeAnchors[planeDef.id] = planeAnchor
                }
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
