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

    static func tapGesture(modelEntity: Binding<ModelEntity?>, appState: AppState, mandibleAnchorWorldPosition: SIMD3<Float>) -> some Gesture {
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
                // let rayEndPoint = cameraPosition + direction * 1.0
                let rayEndPoint = cameraPosition + direction
                print("Raycast from cameraPosition: \(cameraPosition) to rayEndPoint: \(rayEndPoint)")

                let raycastResults = scene.raycast(from: cameraPosition, to: rayEndPoint, query: .nearest, mask: .all)
                print("Raycast performed. Number of results: \(raycastResults.count)")

                if let result = raycastResults.first {
                    print("First raycast result entity: \(result.entity.name)")
                    if result.entity == mandible {
                        print("Raycast hit the mandible!")
                        
                        let worldHitPosition = result.position
                        let worldNormal = result.normal
                        print("World hit position (original): \(worldHitPosition)")
                        print("World hit normal: \(worldNormal)")
                        
                        // Get the actual scale - check if the mandible itself is scaled or its parent
                        var actualScale: Float = 1.0
                        if let parent = mandible.parent {
                            // If mandible has a parent that's scaled, use parent's scale
                            actualScale = parent.scale.x
                            print("Using parent scale: \(actualScale)")
                        } else {
                            // Otherwise use mandible's own scale
                            actualScale = mandible.scale.x
                            print("Using mandible scale: \(actualScale)")
                        }
                        
                        // Transform the hit position to account for the mandible's scaling
                        // First, get position relative to mandible anchor
                        let relativeHitPosition = worldHitPosition - mandibleAnchorWorldPosition
                        // Scale it down to match the visual representation
                        let scaledRelativePosition = relativeHitPosition * actualScale
                        // Transform back to world coordinates
                        let scaledWorldHitPosition = mandibleAnchorWorldPosition + scaledRelativePosition
                        
                        print("Scaled world hit position: \(scaledWorldHitPosition)")
                        
                        // Place the plane exactly at the scaled hit position on the surface
                        // Only add a tiny offset (0.001m = 1mm) to prevent z-fighting
                        let offset: Float = 0.001 
                        let planeWorldPosition = scaledWorldHitPosition + worldNormal * offset
                        
                        print("Mandible anchor world position (passed): \(mandibleAnchorWorldPosition)")
                        print("Plane world position: \(planeWorldPosition)")
                        
                        // Create an OstoetomyPlan and add it to appState
                        // Fix: RealityKit plane mesh has normal pointing in Y direction (0, 1, 0), not Z direction
                        let newPlane = OstoetomyPlan(position: planeWorldPosition, rotation: simd_quatf(from: SIMD3<Float>(1, 0, 0), to: worldNormal))
                        
                        Task { @MainActor in
                            appState.osteotomyPlanes.append(newPlane)
                            print("Created OstoetomyPlan and added to appState.osteotomyPlanes at world position: \(planeWorldPosition)")
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
