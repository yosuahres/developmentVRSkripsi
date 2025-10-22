//
//  ObjectAnchorVisualization.swift
//  developmentVR
//
//  Created by HARES on 08/05/25.
//

import RealityKit
import ARKit
import SwiftUI

@MainActor
class ObjectAnchorVisualization: ObservableObject {
    private let textBaseHeight: Float = 0.08
    private let alpha: CGFloat = 0.7
    private let axisScale: Float = 0.05
    
    var boundingBoxOutline: BoundingBoxOutline
    var hasPlacedFragments: Bool = false
    
    // Position locking properties
    @Published var isPositionLocked: Bool = false
    private var lockedTransform: Transform?
    
    let fragmentColors: [SimpleMaterial.Color] = [
        SimpleMaterial.Color(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),  // Pure orange
        SimpleMaterial.Color(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0),  // Red-orange
        SimpleMaterial.Color(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0),  // Light orange
        SimpleMaterial.Color(red: 0.9, green: 0.3, blue: 0.0, alpha: 1.0),  // Dark orange
        SimpleMaterial.Color(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0),  // Peach orange
        SimpleMaterial.Color(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)   // Burnt orange
    ]
    
    var entity: Entity
    var anchorId: UUID
    
    init(for anchor: ObjectAnchor, withModel model: Entity? = nil, caseGroup: LoadedCaseGroup) {
        self.anchorId = anchor.id
        
        // create the bounding box outline visualization
        boundingBoxOutline = BoundingBoxOutline(anchor: anchor, alpha: alpha)
        
        let entity = Entity()
        
        let originVisualization = Entity.createAxes(axisScale: axisScale, alpha: 0.7)
        
        if let model {
            model.components.set(OpacityComponent(opacity: 0.7))
            entity.addChild(model)
            
            let bounds = entity.visualBounds(relativeTo: entity)
            
            let xAxisLeftMostPoint = bounds.center - SIMD3(bounds.extents.x / 2, 0, 0)
            let xAxisDirection = SIMD3<Float>(1, 0, 0)
            
            let zAxisLeftMostPoint = bounds.center - SIMD3<Float>(0, 0, bounds.extents.z / 2)
            let zAxisDirection = SIMD3<Float>(0, 0, 1)
            
            let yAxisLeftMostPoint = bounds.center - SIMD3<Float>(0, bounds.extents.y / 2, 0)
            let yAxisDirection = SIMD3<Float>(0, 1, 0)
            
            // NOTE: The original code used `fragmentGroup.group.fragments` which is not present in `CaseGroup`.
            // For now, I'm commenting this out as the `CaseGroup` structure needs to be updated first.
            // Once `CaseGroup` is updated with fragment-like data, this section will need to be re-evaluated.
            /*
            for (index, fragment) in caseGroup.group.fragments.enumerated() {
                let color = fragmentColors[index % fragmentColors.count]
                
                for slice in [fragment.startSlice, fragment.endSlice] {
                    let (width, height, depth): (Float, Float, Float) = {
                        switch caseGroup.group.orientation {
                        case "x":
                            return (0.035, 0.035, 0.0005)
                        case "y":
                            return (0.035, 0.0005, 0.035)
                        case "z":
                            return (0.0005, 0.035, 0.035)
                        default:
                            print("⚠️ Invalid orientation, defaulting to thin X")
                            return (0.035, 0.035, 0.0005)
                        }
                    }()

                    let mesh = MeshResource.generateBox(width: width, height: height, depth: depth)
                    let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: false)
                    let sliceModel = ModelEntity(mesh: mesh, materials: [material])
                    
                    let sliceEntity = Entity()
                    sliceEntity.addChild(sliceModel)
                    
                    let (leftMostPoint, direction): (SIMD3<Float>, SIMD3<Float>) = {
                        switch caseGroup.group.orientation {
                        case "x":
                            return (xAxisLeftMostPoint, xAxisDirection)
                        case "y":
                            return (yAxisLeftMostPoint, yAxisDirection)
                        case "z":
                            return (zAxisLeftMostPoint, zAxisDirection)
                        default:
                            print("⚠️ Invalid orientation, defaulting to X-axis")
                            return (xAxisLeftMostPoint, xAxisDirection)
                        }
                    }()
                    
                    let offset = direction * slice.distanceFromLeftAnchor
                    sliceEntity.position = leftMostPoint + offset
                    
                    let eulerRotation = quaternionFromEuler(
                        xDeg: slice.xRotationDegrees,
                        yDeg: slice.yRotationDegrees,
                        zDeg: slice.zRotationDegrees
                    )
                    
                    sliceEntity.orientation = eulerRotation
                    
                    entity.addChild(sliceEntity)
                }
            }
            */
        }
        
        boundingBoxOutline.entity.isEnabled = model == nil
        originVisualization.isEnabled = model == nil
        
        entity.addChild(originVisualization)
        entity.addChild(boundingBoxOutline.entity)
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked
        
        let descriptionEntity = Entity.createText(anchor.referenceObject.name, height: textBaseHeight * axisScale)
        descriptionEntity.transform.translation.x = textBaseHeight * axisScale
        descriptionEntity.transform.translation.y = anchor.boundingBox.extent.y * 0.5
        entity.addChild(descriptionEntity)
        self.entity = entity
    }
    
    func update(with anchor: ObjectAnchor) {
        entity.isEnabled = anchor.isTracked
        guard anchor.isTracked else { return }
        
        // If position is locked, don't update the transform
        if isPositionLocked, let locked = lockedTransform {
            entity.transform = locked
            return
        }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        boundingBoxOutline.update(with: anchor)
    }
    
    // MARK: - Position Locking Methods
    
    func lockPosition() {
        isPositionLocked = true
        lockedTransform = entity.transform
        print("✅ Position locked for anchor: \(anchorId)")
    }
    
    func unlockPosition() {
        isPositionLocked = false
        lockedTransform = nil
        print("🔓 Position unlocked for anchor: \(anchorId)")
    }
    
    func togglePositionLock() {
        if isPositionLocked {
            unlockPosition()
        } else {
            lockPosition()
        }
    }
    
    @MainActor
    class BoundingBoxOutline {
        private let rectangularSides = 12
        private let thickness: Float = 0.0025
        private var extent: SIMD3<Float> = .zero
        private var wires: [Entity] = []
        
        var entity: Entity
        
        fileprivate init(anchor: ObjectAnchor, color: UIColor = .yellow, alpha: CGFloat = 1.0) {
            let entity = Entity()
            
            let material = UnlitMaterial(color: color.withAlphaComponent(alpha))
            // initial size, but later would be scaled to be longer in one of the needed axis
            let mesh = MeshResource.generateBox(size: [0.5, 0.5, 0.5])
            
            for _ in 0..<rectangularSides {
                let wire = ModelEntity(mesh: mesh, materials: [material])
                wires.append(wire)
                entity.addChild(wire)
            }
            
            self.entity = entity
        }
        
        fileprivate func update(with anchor: ObjectAnchor) {
            entity.transform.translation = anchor.boundingBox.center
            
            // Update the outline only if the extent has changed.
            guard anchor.boundingBox.extent != extent else { return }
            extent = anchor.boundingBox.extent
            
            // update for x-axis
            for index in 0...3 {
                wires[index].scale = SIMD3<Float>(extent.x, thickness, thickness)
                wires[index].position = [0, extent.y / 2 * (index % 2 == 0 ? -1 : 1), extent.z / 2 * (index < 2 ? -1 : 1)]
            }
            
            // update for y-axis
            for index in 4...7 {
                wires[index].scale = SIMD3<Float>(thickness, extent.y, thickness)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), 0, extent.z / 2 * (index < 6 ? -1 : 1)]
            }
            
            // update for z-axis
            for index in 8...11 {
                wires[index].scale = SIMD3<Float>(thickness, thickness, extent.z)
                wires[index].position = [extent.x / 2 * (index % 2 == 0 ? -1 : 1), extent.y / 2 * (index < 10 ? -1 : 1), 0]
            }
        }
    }
}
