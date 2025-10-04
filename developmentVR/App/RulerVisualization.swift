//
//  RulerVisualization.swift
//  developmentVR
//
//  Created by HARES on 10/4/25.
//

import RealityKit
import SwiftUI

class RulerVisualization {
    
    static let defaultRealWorldScale: Float = 100.0
    /// - Parameters:
    ///   - startPosition: Starting position of the ruler line
    ///   - endPosition: Ending position of the ruler line
    ///   - distanceMM: Distance in millimeters to display
    ///   - lineColor: Color of the ruler line (default: systemRed)
    ///   - lineThickness: Thickness of the ruler line (default: 0.002)
    ///   - textHeight: Height of the measurement text (default: 0.025)
    /// - Returns: Entity containing the complete ruler visualization
    static func createRulerLine(
        from startPosition: SIMD3<Float>, 
        to endPosition: SIMD3<Float>, 
        distanceMM: Float,
        lineColor: UIColor = .systemRed,
        lineThickness: Float = 0.002,
        textHeight: Float = 0.025
    ) -> Entity {
        let entity = Entity()
        
        let direction = endPosition - startPosition
        let distance = length(direction)
        let midpoint = (startPosition + endPosition) / 2
        let lineMesh = MeshResource.generateBox(
            size: SIMD3<Float>(distance, lineThickness, lineThickness)
        )
        let lineMaterial = SimpleMaterial(color: lineColor, isMetallic: false)
        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
        lineEntity.name = "RulerLine"
        lineEntity.position = midpoint
        
        if distance > 0 {
            let normalizedDirection = normalize(direction)
            let defaultDirection = SIMD3<Float>(1, 0, 0)
            
            if length(cross(defaultDirection, normalizedDirection)) > 0.001 {
                let axis = normalize(cross(defaultDirection, normalizedDirection))
                let angle = acos(dot(defaultDirection, normalizedDirection))
                lineEntity.transform.rotation = simd_quatf(angle: angle, axis: axis)
            }
        }
        
        entity.addChild(lineEntity)
        
        let measurementText = String(format: "%.1f mm", distanceMM)
        let textEntity = createMeasurementText(measurementText, height: textHeight)

        textEntity.position = midpoint
        textEntity.position.y += 0.04 
        
        textEntity.look(at: midpoint + SIMD3<Float>(0, 0, 1), from: textEntity.position, upVector: SIMD3<Float>(0, 1, 0), relativeTo: nil)
        entity.addChild(textEntity)

        let endpointRadius: Float = 0.005
        let startSphere = createEndpointSphere(at: startPosition, color: lineColor, radius: endpointRadius)
        let endSphere = createEndpointSphere(at: endPosition, color: lineColor, radius: endpointRadius)
        
        entity.addChild(startSphere)
        entity.addChild(endSphere)
        
        return entity
    }
    
    /// Calculates the distance between two positions and converts it to millimeters
    /// - Parameters:
    ///   - startPosition: Starting position
    ///   - endPosition: Ending position
    ///   - realWorldScale: Scale factor for unit conversion (default: 100.0)
    /// - Returns: Distance in millimeters
    static func calculateDistanceInMM(
        from startPosition: SIMD3<Float>, 
        to endPosition: SIMD3<Float>, 
        realWorldScale: Float = defaultRealWorldScale
    ) -> Float {
        let distance3D = length(endPosition - startPosition)
        return distance3D * realWorldScale
    }
    
    /// Creates a complete ruler with automatic distance calculation
    /// - Parameters:
    ///   - startPosition: Starting position of the ruler
    ///   - endPosition: Ending position of the ruler
    ///   - realWorldScale: Scale factor for unit conversion
    ///   - lineColor: Color of the ruler line
    /// - Returns: Entity containing the complete ruler visualization
    static func createRuler(
        from startPosition: SIMD3<Float>,
        to endPosition: SIMD3<Float>,
        realWorldScale: Float = defaultRealWorldScale,
        lineColor: UIColor = .systemRed
    ) -> Entity {
        let distanceMM = calculateDistanceInMM(
            from: startPosition,
            to: endPosition,
            realWorldScale: realWorldScale
        )
        
        return createRulerLine(
            from: startPosition,
            to: endPosition,
            distanceMM: distanceMM,
            lineColor: lineColor
        )
    }
    
    // MARK: - Private Helper Methods
    
    private static func createMeasurementText(_ text: String, height: Float) -> Entity {
        let mesh = MeshResource.generateText(
            text, 
            extrusionDepth: height * 0.1, 
            font: .systemFont(ofSize: CGFloat(height))
        )
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        let entity = Entity()
        entity.addChild(modelEntity)

        let bounds = modelEntity.visualBounds(relativeTo: entity)
        modelEntity.position.x = -bounds.center.x
        return entity
    }
    
    private static func createEndpointSphere(at position: SIMD3<Float>, color: UIColor, radius: Float) -> Entity {
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [SimpleMaterial(color: color, isMetallic: false)]
        )
        sphere.position = position
        sphere.name = "RulerEndpoint"
        return sphere
    }
}

// MARK: - RulerManager Class

@MainActor
class RulerManager: ObservableObject {
    @Published var rulers: [Entity] = []
    @Published var isRulerMode: Bool = false
    @Published var selectedPlaneIndex: Int? = nil
    
    private let realWorldScale: Float
    
    init(realWorldScale: Float = RulerVisualization.defaultRealWorldScale) {
        self.realWorldScale = realWorldScale
    }
    
    func createRuler(from startPosition: SIMD3<Float>, to endPosition: SIMD3<Float>, in rootEntity: Entity) {
        let ruler = RulerVisualization.createRuler(
            from: startPosition,
            to: endPosition,
            realWorldScale: realWorldScale
        )
        
        rootEntity.addChild(ruler)
        rulers.append(ruler)
        
        let distanceMM = RulerVisualization.calculateDistanceInMM(
            from: startPosition,
            to: endPosition,
            realWorldScale: realWorldScale
        )
        
        print("📏 Created ruler: \(String(format: "%.1f", distanceMM)) mm")
    }
    
    func clearAllRulers() {
        for ruler in rulers {
            ruler.removeFromParent()
        }
        rulers.removeAll()
        selectedPlaneIndex = nil
        print("🗑️ Cleared all rulers")
    }
    
    func toggleRulerMode() {
        isRulerMode.toggle()
        selectedPlaneIndex = nil
        print(isRulerMode ? "📏 Ruler mode enabled" : "🎯 Plane creation mode enabled")
    }
    
    func findNearestPlaneIndex(to position: SIMD3<Float>, in planePositions: [SIMD3<Float>]) -> Int {
        guard !planePositions.isEmpty else { return 0 }
        
        var nearestIndex = 0
        var nearestDistance = length(planePositions[0] - position)
        
        for (index, planePosition) in planePositions.enumerated() {
            let distance = length(planePosition - position)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }
        
        return nearestIndex
    }
    
    func handleRulerTap(at position: SIMD3<Float>, planePositions: [SIMD3<Float>], rootEntity: Entity) {
        if let selectedIndex = selectedPlaneIndex {
            let startPosition = planePositions[selectedIndex]
            createRuler(from: startPosition, to: position, in: rootEntity)
            selectedPlaneIndex = nil
            print("📏 Created ruler from plane \(selectedIndex) to tap position")
        } else {
            guard !planePositions.isEmpty else {
                print("❌ No planes available for ruler measurement")
                return
            }
            
            let nearestIndex = findNearestPlaneIndex(to: position, in: planePositions)
            selectedPlaneIndex = nearestIndex
            print("📍 Selected plane \(nearestIndex) for ruler start point")
        }
    }
    
    func createRulerBetweenLastTwoPlanes(planePositions: [SIMD3<Float>], rootEntity: Entity) {
        guard planePositions.count >= 2 else { return }
        
        let lastIndex = planePositions.count - 1
        let secondLastIndex = lastIndex - 1
        
        createRuler(
            from: planePositions[secondLastIndex], 
            to: planePositions[lastIndex], 
            in: rootEntity
        )
    }
}