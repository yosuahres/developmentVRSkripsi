//
//  OstoetomyPlanView.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct OstoetomyPlanView: View {
    @ObservedObject var appState: AppState
    @State private var modelEntity: ModelEntity?
    @State private var rectangleEntity: ModelEntity?
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var currentScale: Float = 0.001

    var body: some View {
        RealityView { content in
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let usdzURL = selectedCaseGroup.usdzURL {
                do {
                    let model = try await ModelEntity(contentsOf: usdzURL)
                    model.scale = [currentScale, currentScale, currentScale]

                    let anchor = AnchorEntity(world: [0, 1.5, -2])
                    anchor.addChild(model)

                    model.generateCollisionShapes(recursive: true)
                    model.components.set(InputTargetComponent(allowedInputTypes: .all))

                    content.add(anchor)
                    modelEntity = model

                    let bounds = model.visualBounds(relativeTo: model)
                    let rectSize: Float = max(0.2, Float(bounds.extents.x) * 0.3) 
                    
                    let rect = ModelEntity(
                        mesh: .generateBox(size: [rectSize, 0.005, rectSize]), 
                        materials: [SimpleMaterial(color: .red, roughness: 0.0, isMetallic: false)]
                    )
                    
                    var material = UnlitMaterial(color: .red)
                    material.color = .init(tint: .red, texture: nil)
                    rect.model?.materials = [material]
                    
                    rect.generateCollisionShapes(recursive: true)
                    rect.components.set(InputTargetComponent(allowedInputTypes: .direct))
                    
                    model.addChild(rect)
                    rectangleEntity = rect

                    let yOffset = max(0.2, Float(bounds.extents.y/2) + 0.15)
                    rect.position = [0, yOffset, 0]
                    
                    print("Rectangle created - Size: \(rectSize), Position: \(rect.position), Model bounds: \(bounds)")
                    print("Rectangle scale matches model scale: \(model.scale)")
                    
                } catch {
                    print("Error loading USDZ model: \(error)")
                    if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                        content.add(fallbackScene)
                    }
                }
            } else {
                if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(fallbackScene)
                }
            }
        }
        .gesture(Gestures.dragGesture(modelEntity: $modelEntity, lastTranslation: $lastDragTranslation))
        .simultaneousGesture(Gestures.rotationGesture(modelEntity: $modelEntity, currentAngle: $currentAngle))
        .simultaneousGesture(Gestures.rectangleDragGesture(rectangleEntity: $rectangleEntity, modelEntity: $modelEntity))
    }
}


