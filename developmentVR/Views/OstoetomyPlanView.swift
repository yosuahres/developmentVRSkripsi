//
//  OstoetomyPlanView.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct OstoetomyPlanView: View {
    // state manager
    @ObservedObject var appState: AppState
    @StateObject private var planeManager: PlaneManager

    @State private var objectAnchorVisualizations: [ObjectAnchorVisualization] = []
    @State private var modelEntities: [ModelEntity?] = []
    @State private var spawnedPlanes: [Entity] = []
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero
    @State private var initialTransform: Transform? = nil
    @State private var initialRotation: simd_quatf? = nil
    @State private var mandibleModel: ModelEntity?
    @State private var maxillaModel: ModelEntity?
    @State private var activeModel: ModelEntity?
    private let realWorldScale: Float = 100.0
    
    init(appState: AppState) {
        self.appState = appState
        let initialPlaneManager: PlaneManager = PlaneManager(appState: appState)
        _planeManager = StateObject(wrappedValue: initialPlaneManager)
    }

    var body: some View {
        ZStack {
            realityViewContent 
                .onChange(of: appState.isMaxillaVisible) { _, newValue in
                    maxillaModel?.isEnabled = newValue
                }
                .onChange(of: appState.maxillaOpacity) { _, newValue in
                    maxillaModel?.components.set(OpacityComponent(opacity: newValue))
                }
                .onChange(of: appState.isMandibleVisible) { _, newValue in
                    mandibleModel?.isEnabled = newValue
                }
                .onChange(of: appState.mandibleOpacity) { _, newValue in
                    mandibleModel?.components.set(OpacityComponent(opacity: newValue))
                }
                .onChange(of: planeManager.cuttingPlanes) { _, newPlanes in
                    for plane in newPlanes {
                        if plane.parent == nil {
                            appState.rootContentEntity?.addChild(plane)
                        }
                    }
                }
                .gesture(
                    Gestures.dragGesture(modelEntity: $activeModel, initialTransform: $initialTransform)
                )
                .gesture(
                    Gestures.rotationGesture(modelEntity: $activeModel, initialRotation: $initialRotation)
                )
                .gesture(
                    planeDragGesture
                )
        }
    }

    private var realityViewContent: some View {
        RealityView { content in
            let rootEntity = Entity()
            appState.rootContentEntity = rootEntity
            planeManager.rootContentEntity = rootEntity
            content.add(rootEntity)
            
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let loadedGroup = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroup.id }) {
                
                let initialUserTransform = Transform(translation: [0, 1.5, -1])
                let userForward = initialUserTransform.rotation.act(SIMD3<Float>(x: 0, y: 0, z: -1))
                let spawnDistance: Float = 0.0
                let spawnHeight: Float = 0.0
                let spawnPosition = initialUserTransform.translation + (userForward * spawnDistance) + SIMD3<Float>(x: 0, y: spawnHeight, z: 0)
                
                let parentAnchor = AnchorEntity(world: spawnPosition)
                rootEntity.addChild(parentAnchor)
                
                objectAnchorVisualizations = []
                modelEntities = []
                
                for (index, _) in loadedGroup.usdzEntities.enumerated() {
                    if let usdzURL = loadedGroup.usdzURLs[index] {
                        do {
                            let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, scale: 0.001) //convert to mm from m
                            visualization.entity.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])

                            if let model = visualization.modelEntity {
                                model.components.set(InputTargetComponent())
                                
                                // MANDIBLE COLLIDER
                                model.generateCollisionShapes(recursive: true)
                                let generatedShapes = model.components[CollisionComponent.self]?.shapes ?? []
                                model.components.set(CollisionComponent(
                                    shapes: generatedShapes,
                                    mode: .default,
                                    filter: .init(group: PlaneManager.modelCollisionGroup, mask: PlaneManager.indexFingerCollisionGroup)
                                ))
                                
                                model.components.set(PhysicsBodyComponent(
                                    mode: .static
                                ))

                                if usdzURL.lastPathComponent.contains("Maxilla") {
                                    model.isEnabled = appState.isMaxillaVisible
                                    // set initial opacity for Maxilla
                                    model.components.set(OpacityComponent(opacity: appState.maxillaOpacity))
                                    maxillaModel = model 
                                } else if usdzURL.lastPathComponent.contains("Mandibula") {
                                    model.isEnabled = appState.isMandibleVisible
                                    // set initial opacity for Mandible
                                    model.components.set(OpacityComponent(opacity: appState.mandibleOpacity))
                                    mandibleModel = model
                                    planeManager.mandibleModel = model
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
                if let mandibleModel = mandibleModel {
                    print("DEBUG: Base Model World Position (after adjustments): \(mandibleModel.position(relativeTo: nil))")
                }
            } else {
                if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    rootEntity.addChild(fallbackScene)
                }
            }

            if let arKitSession = appState.arKitSession, let handTrackingProvider = appState.handTrackingProvider {
                let rightHandAnchor = AnchorEntity(.hand(.right, location: .indexFingerTip), trackingMode: .continuous)
                let rightSphere = createIndexFingerSphere()
                rightHandAnchor.addChild(rightSphere)
                rootEntity.addChild(rightHandAnchor)

                let leftHandAnchor = AnchorEntity(.hand(.left, location: .indexFingerTip), trackingMode: .continuous)
                let leftSphere = createIndexFingerSphere()
                leftHandAnchor.addChild(leftSphere)
                rootEntity.addChild(leftHandAnchor)

                planeManager.rightIndexFingerTipEntity = rightSphere
                planeManager.leftIndexFingerTipEntity = leftSphere

                // DEBUGGGG
//                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//                    Task { @MainActor in
//                        if let rightSphere = planeManager.rightIndexFingerTipEntity {
//                            print("DEBUG: Right hand sphere position: \(rightSphere.position(relativeTo: nil))")
//                        }
//                        if let leftSphere = planeManager.leftIndexFingerTipEntity {
//                            print("DEBUG: Left hand sphere position: \(leftSphere.position(relativeTo: nil))")
//                        }
//                    }
//                }
     
                if let scene = rootEntity.scene {
                    _ = scene.subscribe(to: CollisionEvents.Began.self, on: rightSphere) { event in
                        Task { @MainActor in
                            self.planeManager.handleIndexFingerCollision(event: event, rootEntity: rootEntity, modelEntities: self.modelEntities)
                        }
                    }
                    _ = scene.subscribe(to: CollisionEvents.Began.self, on: leftSphere) { event in
                        Task { @MainActor in
                            self.planeManager.handleIndexFingerCollision(event: event, rootEntity: rootEntity, modelEntities: self.modelEntities)
                        }
                    }
                }
            }
        }
    }

    private var planeDragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                planeManager.handlePlaneDragChanged(value: value)
            }
            .onEnded { _ in
                planeManager.handlePlaneDragEnded()
            }
    }

    // SPHERE COLLIDER
    private func createIndexFingerSphere() -> ModelEntity {
        let sphereMesh = MeshResource.generateSphere(radius: 0.01) // 1cm radius
        let sphereMaterial = SimpleMaterial(color: .cyan, isMetallic: false)
        let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])

        sphereEntity.components.set(CollisionComponent(
            shapes: [.generateSphere(radius: 0.01)],
            mode: .default,
            filter: .init(group: PlaneManager.indexFingerCollisionGroup,
                          mask: PlaneManager.modelCollisionGroup)
        ))
        
        sphereEntity.components.set(PhysicsBodyComponent(
            mode: .kinematic
        ))
        
        return sphereEntity
    }
}
