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

    static let indexFingerCollisionGroup = CollisionGroup(rawValue: 1 << 0)
    static let modelCollisionGroup = CollisionGroup(rawValue: 1 << 1)

    init(appState: AppState, mandibleModel: ModelEntity? = nil, rootContentEntity: Entity? = nil, rightIndexFingerTipEntity: ModelEntity? = nil, leftIndexFingerTipEntity: ModelEntity? = nil) {
        self.appState = appState
        self.mandibleModel = mandibleModel
        self.rootContentEntity = rootContentEntity
        self.rightIndexFingerTipEntity = rightIndexFingerTipEntity
        self.leftIndexFingerTipEntity = leftIndexFingerTipEntity
    }

    func handleIndexFingerCollision(event: CollisionEvents.Began, rootEntity: Entity, modelEntities: [ModelEntity?]) {
        guard let collidedModel = event.entityB as? ModelEntity else { return}

        guard modelEntities.contains(collidedModel) else{
            print ("DEBUG: Collision detected with an unknown entity")
            return
        }
        
        guard let firstContact = event.contacts.first else {
            print("DEBUG: Collision detected, but no contact points. (This shouldn't happen with .default mode)")
            return
        }
        
        let collisionPoint = firstContact.point
        let collisionNormal = firstContact.normal
        
        print("DEBUG: Collision contact point found! Spawning plane at \(collisionPoint) with normal \(collisionNormal)")
        
        spawnPlaneAtPoint(position: collisionPoint, normal: collisionNormal, rootEntity: rootEntity)
    }

    func spawnPlaneAtPoint(position: SIMD3<Float>, normal: SIMD3<Float>, rootEntity: Entity) {
        let planeSize: Float = 0.02
        let planeMesh = MeshResource.generatePlane(width: planeSize, depth: planeSize)
        var material = SimpleMaterial(color: .red, isMetallic: false)
        material.faceCulling = .none
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])

        let zAxis = normal
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
