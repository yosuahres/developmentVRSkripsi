//
//  OstoetomyPlanView.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit // Import ARKit

struct OstoetomyPlanView: View {
    @ObservedObject var appState: AppState
    @State private var objectAnchorVisualizations: [ObjectAnchorVisualization] = []
    @State private var modelEntities: [ModelEntity?] = []
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var cuttingPlanes: [Entity] = []
    @State private var baseModel: ModelEntity?
    // Removed currentCameraTransform, will use deviceAnchorTransform directly
    
    // ARKit session and provider
    @State private var arkitSession = ARKitSession()
    @State private var worldTracking = WorldTrackingProvider()
    @State private var deviceAnchorTransform: Transform = .identity // New state for DeviceAnchor transform

    private let realWorldScale: Float = 100.0
    private let centerDeadZone: Float = 0.01

    var body: some View {
        ZStack {
            RealityView { content in
                let rootEntity = Entity()
                appState.rootContentEntity = rootEntity
                content.add(rootEntity)
                
                // The camera transform will be retrieved in the update closure.
                
                if let selectedCaseGroup = appState.selectedCaseGroup,
                   let loadedGroup = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroup.id }) {
                    
                    // spawn models in front of user
                    // Use a default transform for initial model placement, as cameraTransform is not yet available
                    let initialUserTransform = Transform(translation: [0, 1.5, -1])
                    let userForward = initialUserTransform.rotation.act(SIMD3<Float>(x: 0, y: 0, z: -1))
                    let spawnDistance: Float = 0.0
                    let spawnHeight: Float = 0.0
                    let spawnPosition = initialUserTransform.translation + (userForward * spawnDistance) + SIMD3<Float>(x: 0, y: spawnHeight, z: 0)
                    
                    let parentAnchor = AnchorEntity(world: spawnPosition)
                    rootEntity.addChild(parentAnchor)
                    
                    objectAnchorVisualizations = []
                    modelEntities = []
                    
                    for (index, _) in loadedGroup.usdzEntities.enumerated() { // Fixed: usdzEntity not used
                        if let usdzURL = loadedGroup.usdzURLs[index] { // Fixed: usdzEntity not used
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
                                        baseModel = model
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
                    if let baseModel = baseModel {
                        print("DEBUG: Base Model World Position (after adjustments): \(baseModel.position(relativeTo: nil))")
                    }
                } else {
                    if let fallbackScene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                        rootEntity.addChild(fallbackScene)
                    }
                }
                
            } update: { content in
                // No longer updating currentCameraTransform here to avoid "Modifying state during view update"
                // The deviceAnchorTransform will be updated in a separate .task block.
                
                if let selectedCaseGroup = appState.selectedCaseGroup,
                   let loadedGroup = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroup.id }) {
                    for (index, usdzEntity) in loadedGroup.usdzEntities.enumerated() {
                        if let model = modelEntities[index], let usdzURL = loadedGroup.usdzURLs[index] {
                            if usdzURL.lastPathComponent.contains("Maxilla") {
                                model.isEnabled = appState.isMaxillaVisible
                                model.components.set(OpacityComponent(opacity: appState.maxillaOpacity))
                            } else if usdzURL.lastPathComponent.contains("Mandibula") {
                                model.isEnabled = appState.isMandibleVisible
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
                        // The button is now in ImmersiveControlsView
                    }
                }
            }
            .onChange(of: appState.shouldSpawnPlane) { _, newValue in
                if newValue {
                    spawnPlaneOnSurface() // Call directly
                    appState.shouldSpawnPlane = false
                }
            }
            .task {
                do {
                    try await arkitSession.run([worldTracking])
                    // Continuously query for DeviceAnchor transform
                    for await update in worldTracking.anchorUpdates {
                        switch update.event {
                        case .added, .updated:
                            if let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
                                deviceAnchorTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
                                print("DEBUG: DeviceAnchor Transform (from task): \(deviceAnchorTransform)")
                            }
                        case .removed:
                            // Handle removed anchor if necessary
                            break
                        }
                    }
                } catch {
                    print("Error starting ARKit session or processing anchor updates: \(error)")
                }
            }
    }

    func spawnPlaneOnSurface() { // Removed realityContent parameter
        print("spawnPlaneOnSurface() called.")
        guard let baseModel = baseModel, let rootContentEntity = appState.rootContentEntity else { // Fixed: rootEntity not in scope, renamed for clarity
            print("DEBUG: baseModel or rootContentEntity is nil. Cannot spawn plane.")
            return
        }

        let cameraPosition = deviceAnchorTransform.translation // Use deviceAnchorTransform
        let cameraForwardDirection = normalize(deviceAnchorTransform.rotation.act(SIMD3<Float>(x: 0, y: 0, z: -1)))
        let cameraRightDirection = normalize(deviceAnchorTransform.rotation.act(SIMD3<Float>(x: 1, y: 0, z: 0))) // Camera's right vector

        print("DEBUG: Camera Position: \(cameraPosition), Forward Direction: \(cameraForwardDirection), Right Direction: \(cameraRightDirection)")

        // Perform raycast from camera position in forward direction, targeting only baseModel
        if let firstResult = rootContentEntity.scene?.raycast(from: cameraPosition, to: cameraPosition + cameraForwardDirection * 1000, query: .nearest, target: baseModel).first { // Changed to explicitly target baseModel
            print("DEBUG: Raycast hit detected at world position: \(firstResult.position)")
            print("DEBUG: Raycast hit entity: \(firstResult.entity.name)") // Added debug print
            print("DEBUG: Hit normal (world space): \(firstResult.normal)")

            let dotProductWithCameraRight = dot(firstResult.normal, cameraRightDirection)
            print("DEBUG: Dot product of hit normal and camera's right direction: \(dotProductWithCameraRight)")

            let isCorrectSide: Bool
            switch appState.currentTargetSide {
            case .left:
                isCorrectSide = dotProductWithCameraRight > 0.1 // Threshold to account for glancing angles
                print("DEBUG: Checking left side. Dot product (\(dotProductWithCameraRight)) > 0.1 is \(isCorrectSide)")
            case .right:
                isCorrectSide = dotProductWithCameraRight < -0.1 // Threshold
                print("DEBUG: Checking right side. Dot product (\(dotProductWithCameraRight)) < -0.1 is \(isCorrectSide)")
            }

            if isCorrectSide {
                print("DEBUG: Validation passed. Spawning plane.")
                spawnPlane(at: firstResult)
            } else {
                print("DEBUG: Wrong side hit based on normal direction. Please aim at the \(appState.currentTargetSide) side.")
            }
        } else {
            print("DEBUG: Raycast did not hit any surface on the base model.")
        }
    }

    func spawnPlane(at result: CollisionCastHit) {
        print("spawnPlane() called at result position: \(result.position)")
        // Adjust plane size to be more visible relative to the scaled model (assuming model is in mm)
        let planeSize: Float = 0.02 // This will create a 2cm x 2cm plane if 1 unit = 1 meter and scale is 0.001
        let planeMesh = MeshResource.generatePlane(width: planeSize, depth: planeSize)
        let color: UIColor = appState.currentTargetSide == .left ? .green : .red
        print("DEBUG: Plane color set to: \(color == .green ? "Green (Left)" : "Red (Right)")")
        let material = SimpleMaterial(color: color, isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])

        // Offset the plane slightly along its normal to prevent Z-fighting and ensure visibility
        let offset: Float = 0.001 // 1 mm offset
        planeEntity.position = result.position + result.normal * offset
        planeEntity.look(at: result.position + result.normal, from: result.position, relativeTo: nil)

        if let bm = baseModel { // Added debug check
            print("DEBUG: baseModel exists. World position: \(bm.position(relativeTo: nil))")
            bm.addChild(planeEntity)
            print("DEBUG: Plane added to baseModel. Plane world position: \(planeEntity.position(relativeTo: nil))")
        } else {
            print("DEBUG: baseModel is nil, cannot add plane.")
        }
        cuttingPlanes.append(planeEntity)
    }
}
