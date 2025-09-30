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

    static func tapGesture(modelEntity: Binding<ModelEntity?>, appState: AppState) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                print("Tap gesture ended.")
                guard let mandible = modelEntity.wrappedValue,
                      let scene = mandible.scene else {
                    print("ERROR: Mandible model or scene not available.")
                    return
                }
                print("Mandible and scene are available.")

                let tapLocation3D = value.location3D
                let tapLocation = SIMD3<Float>(Float(tapLocation3D.x), Float(tapLocation3D.y), Float(tapLocation3D.z))
                print("Tap location 3D: \(tapLocation3D)")
                print("Tap location (SIMD3): \(tapLocation)")
                
                // In an immersive space, the camera is at the origin of the scene.
                let cameraPosition = SIMD3<Float>.zero
                print("Camera position: \(cameraPosition)")
                
                // Calculate a direction vector from camera to tap location
                let direction = normalize(tapLocation - cameraPosition)
                // Extend the ray to a reasonable distance (e.g., 1 meter)
                let rayEndPoint = cameraPosition + direction * 1.0 // 1 meter in front of camera along tap direction
                print("Raycast from cameraPosition: \(cameraPosition) to rayEndPoint: \(rayEndPoint)")

                let raycastResults = scene.raycast(from: cameraPosition, to: rayEndPoint, query: .nearest, mask: .all)
                print("Raycast performed. Number of results: \(raycastResults.count)")

                if let result = raycastResults.first {
                    print("First raycast result entity: \(result.entity.name)")
                    if result.entity == mandible {
                        print("Raycast hit the mandible!")
                        
                        // Use the center of the mandible's visual bounds as the local position
                        let localPosition = mandible.visualBounds(relativeTo: mandible).center
                        let worldNormal = result.normal
                        print("Using mandible's local bounds center as localPosition: \(localPosition)")
                        print("World hit normal: \(worldNormal)")
                        
                        // Scale down the local position by the mandible's current scale
                        let scaledLocalPosition = localPosition * mandible.scale.x // Assuming uniform scale
                        
                        let mandibleTransform = mandible.transformMatrix(relativeTo: nil)
                        let inverseMandibleTransform = mandibleTransform.inverse
                        let transformedNormal4 = inverseMandibleTransform * SIMD4<Float>(worldNormal, 0)
                        let localNormal = normalize(SIMD3<Float>(transformedNormal4.x, transformedNormal4.y, transformedNormal4.z))
                        print("Local hit position (scaled): \(scaledLocalPosition)")
                        print("Local hit normal: \(localNormal)")
                        
                        // Create an OstoetomyPlan and add it to appState
                        let newPlane = OstoetomyPlan(position: scaledLocalPosition, rotation: simd_quatf(from: SIMD3<Float>(0, 0, 1), to: localNormal))
                        
                        Task { @MainActor in
                            appState.osteotomyPlanes.append(newPlane)
                            print("Created OstoetomyPlan and added to appState.osteotomyPlanes at scaled local position: \(scaledLocalPosition)")
                        }
                    } else {
                        print("Raycast hit an entity other than the mandible: \(result.entity.name)")
                    }
                } else {
                    print("Raycast did not hit any entity.")
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
