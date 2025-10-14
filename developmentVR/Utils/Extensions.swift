//
//  Extensions.swift
//  VisionOSFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 09/05/25.
//

import RealityKit
import SwiftUI

extension Entity {
    static func createText(_ string: String, height: Float, color: UIColor = .white) -> ModelEntity {
        guard let font = MeshResource.Font(name: "Helvetica", size: CGFloat(height)) else {
            fatalError("Couldn't load font.")
        }
        
        let mesh = MeshResource.generateText(string, extrusionDepth: height * 0.05, font: font)
        let material = UnlitMaterial(color: color)
        let text = ModelEntity(mesh: mesh, materials: [material])
        return text
    }
    
    // create origin axis visualization
    static func createAxes(axisScale: Float, alpha: CGFloat = 1.0) -> Entity {
        let axisEntity = Entity()
        let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])
        
        let xAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1).withAlphaComponent(alpha))])
        let yAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).withAlphaComponent(alpha))])
        let zAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(alpha))])
        axisEntity.children.append(contentsOf: [xAxis, yAxis, zAxis])
        
        let axisMinorScale = axisScale / 20
        let axisAxisOffset = axisScale / 2.0 + axisMinorScale / 2.0
        
        xAxis.position = [axisAxisOffset, 0, 0]
        xAxis.scale = [axisScale, axisMinorScale, axisMinorScale]
        yAxis.position = [0, axisAxisOffset, 0]
        yAxis.scale = [axisMinorScale, axisScale, axisMinorScale]
        zAxis.position = [0, 0, axisAxisOffset]
        zAxis.scale = [axisMinorScale, axisMinorScale, axisScale]
        return axisEntity
    }
    
    func applyMaterialRecursively(_ material: RealityFoundation.Material) {
        if let modelEntity = self as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        
        for child in children {
            child.applyMaterialRecursively(material)
        }
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
        return entity
    }
}

extension Float {
    var degreesToRadians: Float { self * .pi / 180 }
}

func quaternionFromEuler(xDeg: Float, yDeg: Float, zDeg: Float) -> simd_quatf {
    let x = simd_quatf(angle: xDeg.degreesToRadians, axis: [1, 0, 0])
    let y = simd_quatf(angle: yDeg.degreesToRadians, axis: [0, 1, 0])
    let z = simd_quatf(angle: zDeg.degreesToRadians, axis: [0, 0, 1])
    return z * y * x // match with data from blender
}
