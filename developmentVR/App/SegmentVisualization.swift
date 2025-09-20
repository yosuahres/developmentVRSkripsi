//
//  SegmentVisualization.swift
//  developmentVR
//
//  Created by HARES on 9/20/25.
//

import RealityKit
import ARKit
import SwiftUI

// Helper function to convert Euler angles to a quaternion
func quaternionFromEuler(xDeg: Float, yDeg: Float, zDeg: Float) -> simd_quatf {
    let xRad = xDeg * .pi / 180
    let yRad = yDeg * .pi / 180
    let zRad = zDeg * .pi / 180
    
    let qx = simd_quatf(angle: xRad, axis: SIMD3<Float>(1, 0, 0))
    let qy = simd_quatf(angle: yRad, axis: SIMD3<Float>(0, 1, 0))
    let qz = simd_quatf(angle: zRad, axis: SIMD3<Float>(0, 0, 1))
    
    return qz * qy * qx
}


// Placeholder extensions
extension Entity {
    static func createAxes(axisScale: Float, alpha: CGFloat) -> Entity {
        let entity = Entity()
        // X-axis
        let xAxis = ModelEntity(mesh: .generateBox(size: [axisScale, 0.005, 0.005]), materials: [SimpleMaterial(color: .red.withAlphaComponent(alpha), isMetallic: false)])
        xAxis.name = "X-Axis"
        entity.addChild(xAxis)
        // Y-axis
        let yAxis = ModelEntity(mesh: .generateBox(size: [0.005, axisScale, 0.005]), materials: [SimpleMaterial(color: .green.withAlphaComponent(alpha), isMetallic: false)])
        yAxis.name = "Y-Axis"
        entity.addChild(yAxis)
        // Z-axis
        let zAxis = ModelEntity(mesh: .generateBox(size: [0.005, 0.005, axisScale]), materials: [SimpleMaterial(color: .blue.withAlphaComponent(alpha), isMetallic: false)])
        zAxis.name = "Z-Axis"
        entity.addChild(zAxis)
        return entity
    }

    static func createText(_ text: String, height: Float) -> Entity {
        let mesh = MeshResource.generateText(text, extrusionDepth: height * 0.1, font: .systemFont(ofSize: CGFloat(height)))
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        let entity = Entity()
        entity.addChild(modelEntity)
        // Center the text
        let bounds = modelEntity.visualBounds(relativeTo: entity)
        modelEntity.position.x = -bounds.center.x
        return entity
    }
}


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
    var modelEntity: ModelEntity?
    var anchorId: UUID
    
    // Modified initializer to work with a USDZ model URL
    init(usdzURL: URL, fragmentGroup: LoadedFragmentGroup?, scale: Float = 1.0) async throws {
        let loadedModel = try await ModelEntity(contentsOf: usdzURL)
        loadedModel.name = usdzURL.lastPathComponent
        loadedModel.scale = [scale, scale, scale]
        self.anchorId = UUID()
        self.modelEntity = loadedModel
        
        // Create the bounding box outline visualization based on the loaded model
        let bounds = loadedModel.visualBounds(relativeTo: nil)
        boundingBoxOutline = BoundingBoxOutline(bounds: bounds, color: .yellow, alpha: alpha)
        
        let entity = Entity()
        
        let originVisualization = Entity.createAxes(axisScale: axisScale, alpha: 0.7)
        
        // Use the loaded model
        loadedModel.components.set(OpacityComponent(opacity: 0.7))
        entity.addChild(loadedModel)
        
        if let fragmentGroup = fragmentGroup {
            let xAxisLeftMostPoint = bounds.center - SIMD3(bounds.extents.x / 2, 0, 0)
            let xAxisDirection = SIMD3<Float>(1, 0, 0)
            
            let zAxisLeftMostPoint = bounds.center - SIMD3<Float>(0, 0, bounds.extents.z / 2)
            let zAxisDirection = SIMD3<Float>(0, 0, 1)
            
            let yAxisLeftMostPoint = bounds.center - SIMD3<Float>(0, bounds.extents.y / 2, 0)
            let yAxisDirection = SIMD3<Float>(0, 1, 0)
            
            for (index, fragment) in fragmentGroup.group.fragments.enumerated() {
                let color = fragmentColors[index % fragmentColors.count]
                
                for slice in [fragment.startSlice, fragment.endSlice] {
                    let (width, height, depth): (Float, Float, Float) = {
                        switch fragmentGroup.group.orientation {
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
                        switch fragmentGroup.group.orientation {
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
        }
        
        boundingBoxOutline.entity.isEnabled = fragmentGroup == nil
        originVisualization.isEnabled = fragmentGroup == nil
        
        entity.addChild(originVisualization)
        entity.addChild(boundingBoxOutline.entity)
        
        let descriptionEntity = Entity.createText(loadedModel.name, height: textBaseHeight * axisScale)
        descriptionEntity.transform.translation.x = bounds.center.x + bounds.extents.x / 2 + 0.01
        descriptionEntity.transform.translation.y = bounds.center.y + bounds.extents.y / 2
        entity.addChild(descriptionEntity)
        self.entity = entity
    }
    
    // This update function is no longer driven by an ARKit anchor.
    // It can be adapted for manual updates if needed.
    func update() {
        // If position is locked, don't update the transform
        if isPositionLocked, let locked = lockedTransform {
            entity.transform = locked
            return
        }
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
        
        fileprivate init(bounds: BoundingBox, color: UIColor = .yellow, alpha: CGFloat = 1.0) {
            let entity = Entity()
            
            let material = UnlitMaterial(color: color.withAlphaComponent(alpha))
            let mesh = MeshResource.generateBox(size: [1, 1, 1]) 
            
            for _ in 0..<rectangularSides {
                let wire = ModelEntity(mesh: mesh, materials: [material])
                wires.append(wire)
                entity.addChild(wire)
            }
            
            self.entity = entity
            self.update(with: bounds)
        }
        
        fileprivate func update(with bounds: BoundingBox) {
            entity.transform.translation = bounds.center
            
            guard bounds.extents != extent else { return }
            extent = bounds.extents
            
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
