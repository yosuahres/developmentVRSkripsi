//
//  CaseGroupLoader.swift
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

    static func tapGesture(modelEntity: Binding<ModelEntity?>) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard let mandible = modelEntity.wrappedValue,
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
