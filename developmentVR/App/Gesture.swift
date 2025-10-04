//
//  Gesture.swift
//  developmentVR
//
//  Created by HARES on 9/15/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct RaycastHitInfo {
    let position: SIMD3<Float>
    let normal: SIMD3<Float>
    let entity: Entity
}

struct Gestures {

    static func tapGesture(
        modelEntity: Binding<ModelEntity?>, 
        appState: AppState,
        mandibleAnchorWorldPosition: SIMD3<Float>,
        onHit: @escaping (RaycastHitInfo) -> Void
    ) -> some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                print("🔵 Tap detected at location: \(value.location3D)")
                
                guard let model = modelEntity.wrappedValue else { 
                    print("❌ No model entity found")
                    return 
                }
                print("✅ Model entity found: \(model.name)")
                
                // Use the actual 3D tap location in world space
                let tapWorldPosition = SIMD3<Float>(
                    Float(value.location3D.x), 
                    Float(value.location3D.y), 
                    Float(value.location3D.z)
                )
                
                // Calculate hit directly from tap position to mandible
                if let hitResult = calculateSurfaceHit(
                    tapPosition: tapWorldPosition,
                    mandibleCenter: mandibleAnchorWorldPosition,
                    entity: model
                ) {
                    print("🎯 Surface HIT! Position: \(hitResult.position), Normal: \(hitResult.normal)")
                    onHit(hitResult)
                } else {
                    print("❌ No surface hit calculated")
                }
            }
    }

    static func dragGesture(modelEntity: Binding<ModelEntity?>, lastTranslation: Binding<CGSize>) -> some Gesture {
        MagnificationGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let model = modelEntity.wrappedValue else { return }
                let pinchValue = value.gestureValue
                let movement = Float(pinchValue - 1.0) * 0.01
                model.position += [movement, movement, movement]
            }
            .onEnded { _ in
                lastTranslation.wrappedValue = .zero
            }
    }

    static func rotationGesture(modelEntity: Binding<ModelEntity?>, currentAngle: Binding<Float>) -> some Gesture {
        MagnificationGesture()
            .onChanged { pinchValue in
                guard let model = modelEntity.wrappedValue else { return }
                let rotationAngle = currentAngle.wrappedValue + Float(pinchValue - 1.0) * 2.0
                model.transform.rotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
            }
            .onEnded { pinchValue in
                currentAngle.wrappedValue += Float(pinchValue - 1.0) * 2.0
            }
    }
    
    private static func calculateSurfaceHit(
        tapPosition: SIMD3<Float>,
        mandibleCenter: SIMD3<Float>,
        entity: ModelEntity
    ) -> RaycastHitInfo? {
        
        print("📍 Tap world position: \(tapPosition)")
        print("🎯 Mandible center: \(mandibleCenter)")
        
        let rawDistance = length(tapPosition - mandibleCenter)
        print("📏 Raw distance from center to tap: \(rawDistance)")
        
        // Simple approach: use tap coordinates to create 8 distinct surface positions
        // Map the large coordinate space to 8 sectors around the mandible
        
        let xSector = (tapPosition.x > 400) ? 1 : -1  // Split at x=400
        let ySector = (tapPosition.y > -1550) ? 1 : -1  // Split at y=-1550  
        let zSector = (tapPosition.z > -2000) ? 1 : -1  // Split at z=-2000
        
        // Create 8 distinct directions based on sectors
        let directionMagnitude: Float = 0.7  // Make directions more distinct
        let direction = normalize(SIMD3<Float>(
            Float(xSector) * directionMagnitude,
            Float(ySector) * directionMagnitude,
            Float(zSector) * directionMagnitude
        ))
        
        // Project onto mandible surface
        let mandibleRadius: Float = 0.18
        let surfacePosition = mandibleCenter + direction * mandibleRadius
        let normal = direction
        
        print("📐 Sector position: X=\(xSector), Y=\(ySector), Z=\(zSector)")
        print("📐 Generated direction: \(direction)")
        print("📏 Mandible radius: \(mandibleRadius)")
        print("✅ Surface position: \(surfacePosition)")
        print("🧭 Surface normal: \(normal)")
        
        return RaycastHitInfo(
            position: surfacePosition,
            normal: normal,
            entity: entity
        )
    }
}