//
//  SegmentVisualization.swift
//  developmentVR
//
//  Created by HARES on 9/20/25.
//

import RealityKit
import ARKit
import SwiftUI

func quaternionFromEuler(xDeg: Float, yDeg: Float, zDeg: Float) -> simd_quatf {
    let xRad = xDeg * .pi / 180
    let yRad = yDeg * .pi / 180
    let zRad = zDeg * .pi / 180
    
    let qx = simd_quatf(angle: xRad, axis: SIMD3<Float>(1, 0, 0))
    let qy = simd_quatf(angle: yRad, axis: SIMD3<Float>(0, 1, 0))
    let qz = simd_quatf(angle: zRad, axis: SIMD3<Float>(0, 0, 1))
    
    return qz * qy * qx
}

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

        let bounds = modelEntity.visualBounds(relativeTo: entity)
        modelEntity.position.x = -bounds.center.x
        return entity
    }
    
    static func createCuttingPlane(at position: SIMD3<Float>, normal: SIMD3<Float>, size: Float = 0.1, scale: Float = 1.0) -> Entity {
        let entity = Entity()
        let mesh = MeshResource.generatePlane(width: size * scale, depth: size * scale)
        
        var material = UnlitMaterial(color: .systemYellow)
        material.color.tint = UIColor.systemYellow.withAlphaComponent(0.6)
        material.faceCulling = .none  
        material.blending = .transparent(opacity: .init(floatLiteral: 0.6))
        
        let planeEntity = ModelEntity(mesh: mesh, materials: [material])
        planeEntity.name = "CuttingPlane"
        entity.position = position
        
        let up = SIMD3<Float>(0, 1, 0)
        let rightVector = normalize(cross(up, normal))
        let actualUp = cross(normal, rightVector)
        
        let rotationMatrix = float3x3(rightVector, actualUp, normal)
        entity.transform.rotation = simd_quatf(rotationMatrix)
        
        entity.addChild(planeEntity)
        
        let centerIndicator = ModelEntity(
            mesh: .generateSphere(radius: 0.005 * scale),
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        entity.addChild(centerIndicator)

        let axes = createAxes(axisScale: 0.02 * scale, alpha: 0.8)
        entity.addChild(axes)
        
        return entity
    }
    
    static func createHitDot(at position: SIMD3<Float>, color: UIColor = .green, scale: Float = 1.0) -> Entity {
        let entity = Entity()
        let dot = ModelEntity(
            mesh: .generateSphere(radius: 0.01 * scale),
            materials: [SimpleMaterial(color: color, isMetallic: false)]
        )
        dot.name = "HitDot"
        entity.position = position
        entity.addChild(dot)
        
        // Add a small text label with coordinates
        let coordText = String(format: "(%.2f, %.2f, %.2f)", position.x, position.y, position.z)
        let textEntity = createText(coordText, height: 0.02 * scale)
        textEntity.position.y += 0.03 * scale
        entity.addChild(textEntity)
        
        return entity
    }
}


@MainActor
class ObjectAnchorVisualization: ObservableObject {
    private let textBaseHeight: Float = 0.08
    private let alpha: CGFloat = 0.7
    private let axisScale: Float = 0.05
    
    var boundingBoxOutline: BoundingBoxOutline
    
    var entity: Entity
    var modelEntity: ModelEntity?
    var anchorId: UUID
    
    init(usdzURL: URL, scale: Float = 1.0) async throws {
        let loadedModel = try await ModelEntity(contentsOf: usdzURL)
        loadedModel.name = usdzURL.lastPathComponent
        self.anchorId = UUID()
        self.modelEntity = loadedModel
        
        let bounds = loadedModel.visualBounds(relativeTo: nil)
        boundingBoxOutline = BoundingBoxOutline(bounds: bounds, color: .yellow, alpha: alpha)
        let entity = Entity()
        let originVisualization = Entity.createAxes(axisScale: axisScale, alpha: 0.7)
        
        loadedModel.components.set(OpacityComponent(opacity: 0.7))
        loadedModel.components.set(InputTargetComponent())
        loadedModel.generateCollisionShapes(recursive: true)
        entity.addChild(loadedModel)
        entity.transform.scale = SIMD3<Float>(repeating: scale)
        
        print("📍 Configured for virtual model anchoring")
        print("🔍 Model bounds: center=\(bounds.center), extents=\(bounds.extents)")
        print("📏 Model loaded at original scale, scaling applied to parent entity")
        
        boundingBoxOutline.entity.isEnabled = true
        originVisualization.isEnabled = true
        
        entity.addChild(originVisualization)
        entity.addChild(boundingBoxOutline.entity)
        
        let descriptionEntity = Entity.createText(loadedModel.name, height: textBaseHeight * axisScale)
        descriptionEntity.transform.translation.x = bounds.center.x + bounds.extents.x / 2 + 0.01
        descriptionEntity.transform.translation.y = bounds.center.y + bounds.extents.y / 2
        entity.addChild(descriptionEntity)
        self.entity = entity
    }
    
    func update() {
    }
    
    // MARK: - Virtual Model Anchoring
    
    func getModelBounds() -> BoundingBox? {
        return modelEntity?.visualBounds(relativeTo: nil)
    }
    
    var anchoringStatus: String {
        return "Anchored to Virtual USDZ Model"
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
