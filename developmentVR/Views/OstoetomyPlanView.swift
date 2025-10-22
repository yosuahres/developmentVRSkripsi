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

    @State private var modelEntities: [ModelEntity?] = []
    @State private var spawnedPlanes: [Entity] = []
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero
    @State private var initialTransform: Transform? = nil
    @State private var initialRotation: simd_quatf? = nil
    @State private var mandibleModel: ModelEntity?
    @State private var maxillaModel: ModelEntity?
    @State private var activeModel: ModelEntity?
    private let realWorldScale: Float = 100.0
    
    @State var arKitSession = ARKitSession()
    @State var handTrackingProvider = HandTrackingProvider()

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    init(appState: AppState) {
        self.appState = appState
        let initialPlaneManager: PlaneManager = PlaneManager(appState: appState)
        _planeManager = StateObject(wrappedValue: initialPlaneManager)
    }

    var body: some View {
        ZStack {
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
                    
                    modelEntities = []
                    
                    for (index, _) in loadedGroup.usdzEntities.enumerated() {
                        if let usdzURL = loadedGroup.usdzURLs[index] {
                            do {
                                let model = try await Entity(contentsOf: usdzURL)
                                model.scale = SIMD3<Float>(repeating: 0.001) // convert to mm from m
                                model.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])

                                model.components.set(InputTargetComponent())
                                model.generateCollisionShapes(recursive: true)
                                model.components.set(CollisionComponent(
                                    shapes: model.collision?.shapes ?? [.generateBox(size: .zero)],
                                    filter: .init(group: PlaneManager.modelCollisionGroup, mask: PlaneManager.indexFingerCollisionGroup)
                                ))

                                if usdzURL.lastPathComponent.contains("Maxilla") {
                                    model.isEnabled = appState.isMaxillaVisible
                                    // set initial opacity for Maxilla
                                    model.components.set(OpacityComponent(opacity: appState.maxillaOpacity))
                                    maxillaModel = (model as? ModelEntity) // Assign Maxilla model
                                } else if usdzURL.lastPathComponent.contains("Mandibula") {
                                    model.isEnabled = appState.isMandibleVisible
                                    // set initial opacity for Mandible
                                    model.components.set(OpacityComponent(opacity: appState.mandibleOpacity))
                                    mandibleModel = (model as? ModelEntity)
                                    planeManager.mandibleModel = (model as? ModelEntity)
                                }
                                
                                parentAnchor.addChild(model)
                                modelEntities.append((model as? ModelEntity))
                            } catch {
                                print("Error loading model \(index): \(error)")
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
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    if let rightSphere = planeManager.rightIndexFingerTipEntity {
                        print("DEBUG: Right hand sphere position: \(rightSphere.position(relativeTo: nil))")
                    }
                    if let leftSphere = planeManager.leftIndexFingerTipEntity {
                        print("DEBUG: Left hand sphere position: \(leftSphere.position(relativeTo: nil))")
                    }
                }

                if let scene = rootEntity.scene {
                    _ = scene.subscribe(to: CollisionEvents.Began.self, on: rightHandAnchor) { event in
                        self.planeManager.handleIndexFingerCollision(event: event, rootEntity: rootEntity, modelEntities: self.modelEntities)
                    }
                    _ = scene.subscribe(to: CollisionEvents.Began.self, on: leftHandAnchor) { event in
                        self.planeManager.handleIndexFingerCollision(event: event, rootEntity: rootEntity, modelEntities: self.modelEntities)
                    }
                }
            }
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
            .gestures(
                Gestures.dragGesture(modelEntity: $activeModel, initialTransform: $initialTransform),
                Gestures.rotationGesture(modelEntity: $activeModel, initialRotation: $initialRotation),
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged { value in
                        planeManager.handlePlaneDragChanged(value: value)
                    }
                    .onEnded { _ in
             
                        planeManager.handlePlaneDragEnded()
                    }
            )
            .task {
                do {
                    try await arKitSession.run([handTrackingProvider])
                    print("DEBUG: ARKitSession with HandTrackingProvider started.")
                } catch {
                    print("Error starting ARKitSession with HandTrackingProvider: \(error)")
                }
            }
            
            VStack {
                Spacer()
                Button("Start Tracking") {
                    Task {
                        await appState.startARSession(openWindow: openWindow, dismissImmersiveSpace: dismissImmersiveSpace)
                    }
                }
                .font(.headline)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 50)
            }
        }
    }

    private func createIndexFingerSphere() -> ModelEntity {
        let sphereMesh = MeshResource.generateSphere(radius: 0.01) //mm
        let sphereMaterial = SimpleMaterial(color: .cyan, isMetallic: false)
        let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
        sphereEntity.components.set(CollisionComponent(
            shapes: [.generateSphere(radius: 0.005)],
            filter: .init(group: PlaneManager.indexFingerCollisionGroup, mask: PlaneManager.modelCollisionGroup)
        ))
        sphereEntity.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic))
        return sphereEntity
    }
}

extension View {
    func gestures<G1: Gesture, G2: Gesture, G3: Gesture>(
        _ g1: G1, _ g2: G2, _ g3: G3
    ) -> some View {
        self
            .gesture(g1)
            .gesture(g2)
            .gesture(g3)
    }
}
