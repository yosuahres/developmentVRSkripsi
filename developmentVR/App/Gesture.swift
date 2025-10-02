//
//  Gesture.swift
//  developmentVR
//
//  Created by HARES on 9/15/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct Gestures {

    static func dragGesture(modelEntity: Binding<ModelEntity?>, lastTranslation: Binding<CGSize>) -> some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { drag in
                guard let model = modelEntity.wrappedValue else { return }
                let dx = Float(drag.translation.width - lastTranslation.wrappedValue.width) * 0.002
                let dy = Float(drag.translation.height - lastTranslation.wrappedValue.height) * 0.002
                let dz = Float(drag.translation.height - lastTranslation.wrappedValue.height) * 0.002
                model.position += [dx, dy, dz]
                lastTranslation.wrappedValue = drag.translation
            }
            .onEnded { _ in
                lastTranslation.wrappedValue = .zero
            }
    }

    static func rotationGesture(modelEntity: Binding<ModelEntity?>, currentAngle: Binding<Float>) -> some Gesture {
        RotationGesture()
            .onChanged { value in
                guard let model = modelEntity.wrappedValue else { return }
                model.transform.rotation = simd_quatf(angle: currentAngle.wrappedValue + Float(value.radians), axis: [0, 1, 0])
            }
            .onEnded { value in
                currentAngle.wrappedValue += Float(value.radians)
            }
    }

    static func tapGesture(modelEntity: Binding<ModelEntity?>, appState: AppState, mandibleAnchorWorldPosition: SIMD3<Float>) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                print("Tap gesture ended.")
            }
    }
    
    static func performMandibleRaycast(modelEntity: ModelEntity?, content: RealityViewContent, mandibleAnchorWorldPosition: SIMD3<Float>) {
        guard let mandible = modelEntity else {
            print("❌ No mandible model entity found")
            return
        }
        
        mandible.generateCollisionShapes(recursive: true)
        
        let bounds = mandible.visualBounds(relativeTo: nil)
        let actualMandibleCenter = bounds.center
        
        print("🎯 Mandible actual center: \(actualMandibleCenter)")
        print("🎯 Mandible bounds extents: \(bounds.extents)")
        let rayConfigs: [(origin: SIMD3<Float>, direction: SIMD3<Float>)] = [
            // Ray from above center
            (
                origin: actualMandibleCenter + SIMD3<Float>(0, bounds.extents.y * 0.8, 0),
                direction: SIMD3<Float>(0, -1, 0)
            ),
            // Ray from left side
            (
                origin: actualMandibleCenter + SIMD3<Float>(-bounds.extents.x * 0.8, 0, 0),
                direction: SIMD3<Float>(1, 0, 0)
            ),
            // Ray from right side
            (
                origin: actualMandibleCenter + SIMD3<Float>(bounds.extents.x * 0.8, 0, 0),
                direction: SIMD3<Float>(-1, 0, 0)
            ),
            // Ray from front
            (
                origin: actualMandibleCenter + SIMD3<Float>(0, 0, bounds.extents.z * 0.8),
                direction: SIMD3<Float>(0, 0, -1)
            ),
            // Ray from back
            (
                origin: actualMandibleCenter + SIMD3<Float>(0, 0, -bounds.extents.z * 0.8),
                direction: SIMD3<Float>(0, 0, 1)
            )
        ]
        
        var planesCreated = 0
        
        for (index, config) in rayConfigs.enumerated() {
            let rayOrigin = config.origin
            let rayDirection = normalize(config.direction)
            
            print("🔫 Ray \(index + 1): Origin=\(rayOrigin), Direction=\(rayDirection)")
            
            if let scene = content.entities.first?.scene {
                let rayEndPoint = rayOrigin + rayDirection * 2.0
                let raycastResults = scene.raycast(from: rayOrigin, to: rayEndPoint)
                
                print("🎯 Scene raycast found \(raycastResults.count) hits for ray \(index + 1)")
                
                // Look for hit on the mandible specifically
                if let hit = raycastResults.first(where: { result in
                    var entity: Entity? = result.entity
                    while entity != nil {
                        if entity === mandible {
                            return true
                        }
                        entity = entity?.parent
                    }
                    return false
                }) {
                    let hitPosition = hit.position
                    let surfaceNormal = hit.normal
                    let plane = ModelEntity(
                        mesh: .generatePlane(width: 0.015, height: 0.015),
                        materials: [SimpleMaterial(color: .blue.withAlphaComponent(0.9), isMetallic: false)]
                    )
                    let quat = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: surfaceNormal)
                    plane.orientation = quat
                    
                    let planeAnchor = AnchorEntity(world: hitPosition)
                    planeAnchor.addChild(plane)
                    content.add(planeAnchor)
                    
                    planesCreated += 1
                    print("✅ RAYCAST HIT! Created plane \(index + 1) at: \(hitPosition) with normal: \(surfaceNormal)")
                } else {
                    print("⚠️ No mandible hit detected for ray \(index + 1)")
                    if let anyHit = raycastResults.first {
                        let plane = ModelEntity(
                            mesh: .generatePlane(width: 0.015, height: 0.015),
                            materials: [SimpleMaterial(color: .orange.withAlphaComponent(0.7), isMetallic: false)]
                        )
                        
                        let planeAnchor = AnchorEntity(world: anyHit.position)
                        planeAnchor.addChild(plane)
                        content.add(planeAnchor)
                        
                        planesCreated += 1
                        print("🔶 SCENE HIT! Created fallback plane \(index + 1) at: \(anyHit.position)")
                    }
                }
            }
        }
        
        print("🎯 Raycast complete! Created \(planesCreated) planes")
    }
    /*
    // Pinch to scale (disabled for now)
    static func pinchGesture(modelEntity: Binding<ModelEntity?>, currentScale: Binding<Float>) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard let model = modelEntity.wrappedValue else { return }
                model.scale = [currentScale.wrappedValue * Float(value),
                               currentScale.wrappedValue * Float(value),
                               currentScale.wrappedValue * Float(value)]
            }
            .onEnded { value in
                currentScale.wrappedValue *= Float(value)
            }
    }
    */
}
