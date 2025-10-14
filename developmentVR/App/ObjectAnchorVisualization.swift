//
//  ObjectAnchorVisualization.swift
//  developmentVR
//
//  Created by HARES on 10/14/25.
//

import RealityKit
import SwiftUI

@MainActor
class ObjectAnchorVisualization: ObservableObject {
    private let textBaseHeight: Float = 0.08
    private let alpha: CGFloat = 0.7
    private let axisScale: Float = 0.05
    
    var entity: Entity
    var modelEntity: ModelEntity?
    
    var usdzAnchorId: UUID //for VR
//    var realAnchorId: UUID //for AR
    
    var hasPlacedFragment: Bool  = false
//    var boundingBoxOutline: BoundingBoxOutline
    
    //position locking properties
    @Published var isPositionLocked: Bool = false
    private var lockedTransform: Transform?
    
    let fragmentColors: [SimpleMaterial.Color] = [
        SimpleMaterial.Color(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0), //pure orange
        SimpleMaterial.Color(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0), //red orange
        SimpleMaterial.Color(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0), //light orange
        SimpleMaterial.Color(red: 0.9, green: 0.3, blue: 0.0, alpha: 1.0), //dark orange
        SimpleMaterial.Color(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0), //peach orange
        SimpleMaterial.Color(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0), //burnt orange
     ]
    
    init(usdzURL: URL, scale: Float = 1.0) async throws {
        let loadedModel = try await ModelEntity(contentsOf: usdzURL)
        loadedModel.name = usdzURL.lastPathComponent
        self.usdzAnchorId = UUID()
        self.modelEntity = loadedModel
        
        let entity = Entity()
        let originVisualization = Entity.createAxes(axisScale: axisScale, alpha: 0.7)
        
        loadedModel.components.set(OpacityComponent(opacity: 0.7))
        loadedModel.components.set(InputTargetComponent())
        loadedModel.generateCollisionShapes(recursive: true)
        entity.addChild(loadedModel)
        entity.transform.scale = SIMD3<Float>(repeating: scale)
        
        print("📍 Configured for virtual model anchoring")
        print(" Model loaded at original scale, scaling applied to parent entity")
        
        originVisualization.isEnabled = true
        
        entity.addChild(originVisualization)
        
        self.entity = entity
    }
    
    func update() {
    }
    
    var anchoringStatus: String {
        return "Anchored to Virtual USDZ Model"
    }
    
    
//    @MainActor
//    class BoundingBoxOutline {
//        private let rectangularSides = 12
//        private let thickness: Float = 0.0025
//        private var extent: SIMD3<Float> = .zero
//        private var wires: [Entity] = []
//        
//        var entity: Entity
//    }
}



