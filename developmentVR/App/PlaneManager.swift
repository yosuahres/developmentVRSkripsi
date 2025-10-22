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
    var rightIndexFingerTipEntity: ModelEntity?
    var leftIndexFingerTipEntity: ModelEntity?

    // add collision to model sphere and model mandible
    static let indexFingerCollisionGroup = CollisionGroup(rawValue: 1 << 0)
    static let modelCollisionGroup = CollisionGroup(rawValue: 1 << 1)

    init(appState: AppState, mandibleModel: ModelEntity? = nil, rootContentEntity: Entity? = nil, rightIndexFingerTipEntity: ModelEntity? = nil, leftIndexFingerTipEntity: ModelEntity? = nil) {
        self.appState = appState
        self.mandibleModel = mandibleModel
        self.rootContentEntity = rootContentEntity
        self.rightIndexFingerTipEntity = rightIndexFingerTipEntity
        self.leftIndexFingerTipEntity = leftIndexFingerTipEntity
    }

    // MODIFIED: This function now uses the event's contact manifold
    func handleIndexFingerCollision(event: CollisionEvents.Began, rootEntity: Entity, modelEntities: [ModelEntity?]) {
        guard let entityA = event.entityA as? ModelEntity,
              let entityB = event.entityB as? ModelEntity else { return }

        // Identify which is the finger and which is the model
        let (indexFingerSphere, collidedModel): (ModelEntity, ModelEntity)
        if entityA == rightIndexFingerTipEntity || entityA == leftIndexFingerTipEntity {
            indexFingerSphere = entityA
            collidedModel = entityB
        } else if entityB == rightIndexFingerTipEntity || entityB == leftIndexFingerTipEntity {
            indexFingerSphere = entityB
            collidedModel = entityA
        } else {
            return
        }

        guard modelEntities.contains(collidedModel) else { return }

        // 1. Get the contact manifold (the contacts array)
        // This is only populated if mode is .default
        guard let firstContact = event.contacts.first else {
            print("DEBUG: Collision detected, but no contact points. Did you set CollisionComponent.mode to .default on both entities?")
            return
        }

        // 2. Get the precise point from the contact
        let collisionPoint = firstContact.point // This is the exact hitpoint in world space

        // 3. Get the correct normal
        // The normal always points from entityB toward entityA.
        // We need it to point "out" of the collidedModel.
        let collisionNormal: SIMD3<Float>
        if entityA == collidedModel {
            // Normal points from finger (B) to model (A), so it's already correct
            collisionNormal = firstContact.normal
        } else {
            // Normal points from model (B) to finger (A), so we must flip it
            collisionNormal = -firstContact.normal
        }

        print("DEBUG: Collision contact point found! Spawning plane at \(collisionPoint) with normal \(collisionNormal)")

        // 4. Spawn the plane with the accurate data
        // The collisionPoint is in world space, so we spawn relative to the rootEntity
        spawnPlaneAtPoint(position: collisionPoint, normal: collisionNormal, rootEntity: rootEntity)
    }

    func spawnPlaneAtPoint(position: SIMD3<Float>, normal: SIMD3<Float>, rootEntity: Entity) {
        let planeSize: Float = 0.02 // 2cm x 2cm
        let planeMesh = MeshResource.generatePlane(width: planeSize, depth: planeSize)
        let material = SimpleMaterial(color: .red, isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])

        // perpendicular to the normal
        let zAxis = normal
        // Handle edge case where normal is parallel to (0, 1, 0)
        let arbitraryUp = (abs(zAxis.y) < 0.99) ? SIMD3<Float>(0, 1, 0) : SIMD3<Float>(1, 0, 0)
        let xAxis = normalize(cross(arbitraryUp, zAxis))
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
