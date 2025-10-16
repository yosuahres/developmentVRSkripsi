//
//  PlaneManager.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
class PlaneManager: ObservableObject {
    @Published var cuttingPlanes: [Entity] = []
    @Published var draggedPlane: Entity?
    
    var appState: AppState
    var mandibleModel: ModelEntity?
    var rootContentEntity: Entity?
    var indexFingerTipEntity: ModelEntity?

    // collision
    static let indexFingerCollisionGroup = CollisionGroup(rawValue: 1 << 0)
    static let modelCollisionGroup = CollisionGroup(rawValue: 1 << 1)

    init(appState: AppState, mandibleModel: ModelEntity? = nil, rootContentEntity: Entity? = nil, indexFingerTipEntity: ModelEntity? = nil) {
        self.appState = appState
        self.mandibleModel = mandibleModel
        self.rootContentEntity = rootContentEntity
        self.indexFingerTipEntity = indexFingerTipEntity
    }

    func handleIndexFingerCollision(event: CollisionEvents.Began, rootEntity: Entity, modelEntities: [ModelEntity?]) {
        guard let entityA = event.entityA as? ModelEntity,
              let entityB = event.entityB as? ModelEntity else { return }

        let indexFingerSphere: ModelEntity
        let collidedModel: ModelEntity

        if entityA == appState.indexFingerTipEntity {
            indexFingerSphere = entityA
            collidedModel = entityB
        } else if entityB == appState.indexFingerTipEntity {
            indexFingerSphere = entityB
            collidedModel = entityA
        } else {
            return 
        }

        guard modelEntities.contains(collidedModel) else { return }

        let collisionPoint = indexFingerSphere.position(relativeTo: rootEntity) 
        let collisionNormal = normalize(collidedModel.position(relativeTo: rootEntity) - indexFingerSphere.position(relativeTo: rootEntity)) 

        spawnPlaneAtPoint(position: collisionPoint, normal: collisionNormal, rootEntity: rootEntity)
    }

    func spawnPlaneAtPoint(position: SIMD3<Float>, normal: SIMD3<Float>, rootEntity: Entity) {
        let planeSize: Float = 0.02 // 2cm x 2cm
        let planeMesh = MeshResource.generatePlane(width: planeSize, depth: planeSize)
        let material = SimpleMaterial(color: .red, isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])

        // Orient the plane to be perpendicular to the normal
        let zAxis = normal
        let xAxis = normalize(cross(SIMD3<Float>(0, 1, 0), zAxis)) 
        let yAxis = normalize(cross(zAxis, xAxis))

        let rotationMatrix = simd_float3x3(columns: (xAxis, yAxis, zAxis))
        let planeRotation = simd_quatf(rotationMatrix)

        planeEntity.transform = Transform(rotation: planeRotation, translation: position)
        
        planeEntity.components.set(InputTargetComponent())
        planeEntity.generateCollisionShapes(recursive: false)

        rootEntity.addChild(planeEntity)
        cuttingPlanes.append(planeEntity)
        print("DEBUG: Plane spawned at \(position) with normal \(normal)")
    }

    func handlePlaneDragChanged(value: EntityTargetValue<DragGesture.Value>) {
        if draggedPlane == nil {
            if cuttingPlanes.contains(where: { $0 == value.entity }) {
                draggedPlane = value.entity
            }
        }
        
        if let plane = draggedPlane {
            let dragTranslation = value.translation3D
            plane.position += SIMD3<Float>(dragTranslation)
            
            let rotationAngle = Float(value.translation.width * .pi / 180) 
            let rotation = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0)) 
            plane.orientation *= rotation
        }
    }

    func handlePlaneDragEnded() {
        draggedPlane = nil
    }
}
