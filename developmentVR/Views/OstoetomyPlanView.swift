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
    @State private var objectAnchorVisualizations: [ObjectAnchorVisualization] = []
    @State private var modelEntities: [ModelEntity?] = []
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
               let loadedGroup = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroup.id }) { 
                
                let headAnchor = AnchorEntity(.head)
                content.add(headAnchor)
                headAnchorTransform = headAnchor.transform
                
                // spawn models in front of user
                let userTransform = headAnchor.transform
                let userForward = userTransform.rotation.act(SIMD3<Float>(x: 0, y: 0, z: -1))
                let spawnDistance: Float = 1.0
                let spawnHeight: Float = 1.5
                let spawnPosition = userTransform.translation + (userForward * spawnDistance) + SIMD3<Float>(x: 0, y: spawnHeight, z: 0)
                
                let parentAnchor = AnchorEntity(world: spawnPosition)
                rootEntity.addChild(parentAnchor)
                
                objectAnchorVisualizations = []
                modelEntities = []
                
                for (index, usdzEntity) in loadedGroup.usdzEntities.enumerated() {
                    if let _ = usdzEntity, let usdzURL = loadedGroup.usdzURLs[index] {
                        do {
                            let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, scale: 0.001) //convert to mm, idk what it should be

                            // apply rotation look left
                            visualization.entity.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])

                            if let model = visualization.modelEntity {
                                model.components.set(InputTargetComponent())
                                model.generateCollisionShapes(recursive: true)

                                if usdzURL.lastPathComponent.contains("Maxilla") {
                                    model.isEnabled = appState.isMaxillaVisible
                                    // Set initial opacity for Maxilla
                                    model.components.set(OpacityComponent(opacity: appState.maxillaOpacity))
                                } else if usdzURL.lastPathComponent.contains("Mandibula") {
                                    model.isEnabled = appState.isMandibleVisible
                                    // Set initial opacity for Mandible
                                    model.components.set(OpacityComponent(opacity: appState.mandibleOpacity))
                                }
                            }

                            parentAnchor.addChild(visualization.entity)
                            objectAnchorVisualizations.append(visualization)
                            modelEntities.append(visualization.modelEntity)
                        } catch {
                            print("Error loading or creating visualization for model \(index): \(error)")
                        }
                    }
                }
                var combinedBounds: BoundingBox?
                for modelEntity in modelEntities {
                    if let model = modelEntity {
                        let modelBounds = model.visualBounds(relativeTo: parentAnchor)
                        if combinedBounds == nil {
                            combinedBounds = modelBounds
                        } else {
                            combinedBounds = combinedBounds?.union(modelBounds)
                        }
                    }
                }
                
                if let bounds = combinedBounds {
                    parentAnchor.transform.translation -= bounds.center
                }

                mandibleAnchorWorldPosition = spawnPosition 
            } else {
                if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    rootEntity.addChild(fallbackScene)
                }
            }
            
        } update: { content in
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let loadedGroup = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroup.id }) {
                for (index, usdzEntity) in loadedGroup.usdzEntities.enumerated() {
                    if let model = modelEntities[index], let usdzURL = loadedGroup.usdzURLs[index] {
                        if usdzURL.lastPathComponent.contains("Maxilla") {
                            model.isEnabled = appState.isMaxillaVisible
                            // Apply opacity changes for Maxilla
                            model.components.set(OpacityComponent(opacity: appState.maxillaOpacity))
                        } else if usdzURL.lastPathComponent.contains("Mandibula") {
                            model.isEnabled = appState.isMandibleVisible
                            // Apply opacity changes for Mandible
                            model.components.set(OpacityComponent(opacity: appState.mandibleOpacity))
                        }
                    }
                }
            }
        }
        .simultaneousGesture(Gestures.dragGesture(modelEntity: Binding(
            get: { modelEntities.first ?? nil },
            set: { _ in }
        ), lastTranslation: $lastDragTranslation))
        .simultaneousGesture(Gestures.rotationGesture(modelEntity: Binding(
            get: { modelEntities.first ?? nil }, 
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
