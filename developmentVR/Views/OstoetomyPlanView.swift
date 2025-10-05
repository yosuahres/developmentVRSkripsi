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
    @State private var objectAnchorVisualization: ObjectAnchorVisualization?
    @State private var mandibleModelEntity: ModelEntity?
    @State private var headAnchorTransform: Transform = .identity 
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero 
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var cuttingPlanes: [Entity] = []
    
    private let realWorldScale: Float = 100.0

    var body: some View {
        ZStack {
            RealityView { content in
            let rootEntity = Entity()
            content.add(rootEntity)
            appState.rootContentEntity = rootEntity
            
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let usdzURL = selectedCaseGroup.usdzURL {
                do {
                    let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, scale: 1.0)
                    
                    let headAnchor = AnchorEntity(.head)
                    content.add(headAnchor)
                    headAnchorTransform = headAnchor.transform 
                    
                    // spawn model in front of user
                    let userTransform = headAnchor.transform
                    let userForward = userTransform.rotation.act(SIMD3<Float>(x: 0, y: 0, z: -1))
                    let spawnDistance: Float = 10.0
                    let spawnHeight: Float = 5.0
                    let spawnPosition = userTransform.translation + (userForward * spawnDistance) + SIMD3<Float>(x: 0, y: spawnHeight, z: 0)
                    
                    // look left rotate
                    let anchor = AnchorEntity(world: spawnPosition)
                    anchor.addChild(visualization.entity)
                    visualization.entity.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])
                    
                    if let model = visualization.modelEntity {
                        model.components.set(InputTargetComponent())
                        model.generateCollisionShapes(recursive: true)
                    }
                    
                    rootEntity.addChild(anchor)
                    objectAnchorVisualization = visualization
                    mandibleModelEntity = visualization.modelEntity
                    mandibleAnchorWorldPosition = spawnPosition
                } catch {
                    print("Error loading or creating visualization: \(error)")
                    if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                        rootEntity.addChild(fallbackScene)
                    }
                }
            } else {
                if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    rootEntity.addChild(fallbackScene)
                }
            }
            
        } update: { content in
            // Update existing cutting planes if needed
        }
        .simultaneousGesture(Gestures.dragGesture(modelEntity: Binding(
            get: { objectAnchorVisualization?.modelEntity },
            set: { _ in }
        ), lastTranslation: $lastDragTranslation))
        .simultaneousGesture(Gestures.rotationGesture(modelEntity: Binding(
            get: { objectAnchorVisualization?.modelEntity },
            set: { _ in }
        ), currentAngle: $currentAngle))
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    EmptyView()
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}
