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
            // Temporarily disable existing plane rendering
            /*
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
            */
        }
        .gesture(
            SpatialTapGesture()
                .onEnded { value in
                    guard let mandible = mandibleModelEntity,
                          let scene = mandible.scene else { return }

                    let tapLocation3D = value.location3D
                    let tapLocation = SIMD3<Float>(Float(tapLocation3D.x), Float(tapLocation3D.y), Float(tapLocation3D.z))
                    
                    // In an immersive space, the camera is at the origin of the scene.
                    let cameraPosition = SIMD3<Float>.zero
                    
                    if let result = scene.raycast(from: cameraPosition, to: tapLocation, query: .nearest, mask: .all).first,
                       result.entity == mandible {
                        
                        let worldPosition = result.position
                        let worldNormal = result.normal
                        
                        let mandibleTransform = mandible.transformMatrix(relativeTo: nil)
                        let inverseMandibleTransform = mandibleTransform.inverse
                        
                        let transformedPoint4 = inverseMandibleTransform * SIMD4<Float>(worldPosition, 1)
                        let localPosition = SIMD3<Float>(transformedPoint4.x, transformedPoint4.y, transformedPoint4.z)

                        let transformedNormal4 = inverseMandibleTransform * SIMD4<Float>(worldNormal, 0)
                        let localNormal = normalize(SIMD3<Float>(transformedNormal4.x, transformedNormal4.y, transformedNormal4.z))
                        
                        let plane = ModelEntity(
                            mesh: .generatePlane(width: 0.1, height: 0.1),
                            materials: [SimpleMaterial(color: .blue.withAlphaComponent(0.8), isMetallic: false)]
                        )
                        
                        plane.position = localPosition
                        
                        let upVector = SIMD3<Float>(0, 0, 1)
                        let quaternion = simd_quatf(from: upVector, to: localNormal)
                        plane.orientation = quaternion
                        
                        mandible.addChild(plane)
                    }
                }
        )
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
