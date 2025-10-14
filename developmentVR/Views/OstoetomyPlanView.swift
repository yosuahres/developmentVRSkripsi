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

extension Point3D {
    var vector: SIMD3<Float> {
        SIMD3<Float>(Float(x), Float(y), Float(z))
    }
}

struct OstoetomyPlanView: View {
    @ObservedObject var appState: AppState
    @State private var objectAnchorVisualizations: [ObjectAnchorVisualization] = []
    @State private var modelEntities: [ModelEntity?] = []
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero
    @State private var cuttingPlanes: [Entity] = []
    @State private var initialTransform: Transform? = nil
    @State private var initialRotation: simd_quatf? = nil
    @State private var initialScale: SIMD3<Float>? = nil
    @State private var mandibleModel: ModelEntity?
    @State private var maxillaModel: ModelEntity?
    @State private var activeModel: ModelEntity?
    @State private var draggedPlane: Entity?
    

    enum TapPhase {
        case waitingForFirstTap
        case waitingForSecondTap
        case readyToSpawn
    }
    @State private var tapPhase: TapPhase = .waitingForFirstTap
    @State private var firstTapPoint: SIMD3<Float>?
    @State private var firstTapNormal: SIMD3<Float>?
    @State private var secondTapPoint: SIMD3<Float>?
    @State private var secondTapNormal: SIMD3<Float>?
    @State private var tapMarkers: [ModelEntity] = [] // For visual feedback

    // ARKit session and provider
    @State private var arkitSession = ARKitSession()
    @State private var worldTracking = WorldTrackingProvider()
    @State private var deviceAnchorTransform: Transform = .identity 

    private let realWorldScale: Float = 100.0
    private let centerDeadZone: Float = 0.01

    var body: some View {
        ZStack {
            RealityView { content in
                let rootEntity = Entity()
                appState.rootContentEntity = rootEntity
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
                                let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, scale: 0.001) //convert to mm, idk what it should be

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
                                        mandibleModel = model
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
                
            } update: { content in
                // No longer updating currentCameraTransform here to avoid "Modifying state during view update"
                // The deviceAnchorTransform will be updated in a separate .task block.
                
                if let selectedCaseGroup = appState.selectedCaseGroup,
                   let loadedGroup = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroup.id }) {
                    for (index, usdzEntity) in loadedGroup.usdzEntities.enumerated() {
                            if modelEntities.indices.contains(index), loadedGroup.usdzURLs.indices.contains(index),
                               let model = modelEntities[index], let usdzURL = loadedGroup.usdzURLs[index] {
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
            .gesture(Gestures.dragGesture(modelEntity: $activeModel, initialTransform: $initialTransform))
            .gesture(Gestures.rotationGesture(modelEntity: $activeModel, initialRotation: $initialRotation))
            .gesture(Gestures.magnificationGesture(modelEntity: $activeModel, initialScale: $initialScale))
            .gesture(SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    handleTapWithEntityTarget(value: value)
                })
            .gesture(DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    if draggedPlane == nil {
                        if cuttingPlanes.contains(where: { $0 == value.entity }) {
                            draggedPlane = value.entity
                        }
                    }
                    
                    if let plane = draggedPlane {
                        let dragTranslation = value.translation3D
                        plane.position += SIMD3<Float>(dragTranslation)
                        
                        let rotationAngle = Float(value.translation.width * .pi / 180) 
                        let rotation = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0)) 
                        plane.orientation *= rotation
                    }
                }
                .onEnded { _ in
                    draggedPlane = nil
                }
            )
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                    }
                }
            }
            .task {
                do {
                    try await arkitSession.run([worldTracking])
                    for await update in worldTracking.anchorUpdates {
                        switch update.event {
                        case .added, .updated:
                            if let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
                                deviceAnchorTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
                                print("DEBUG: DeviceAnchor Transform (from task): \(deviceAnchorTransform)")
                            }
                        case .removed:
                            break
                        }
                    }
                } catch {
                    print("Error starting ARKit session or processing anchor updates: \(error)")
                }
            }
    }

    func handleTapWithEntityTarget(value: EntityTargetValue<SpatialTapGesture.Value>) {
        let gestureValue = value.gestureValue
        handleTap(value: gestureValue)
    }

    func handleTap(value: SpatialTapGesture.Value) {
        print("DEBUG: Camera Transform on Tap: \(deviceAnchorTransform)")
        guard let rootContentEntity = appState.rootContentEntity else {
            print("DEBUG: rootContentEntity is nil. Cannot handle tap.")
            return
        }

        let tapWorldPosition = value.location3D.vector 

        let cameraPosition = deviceAnchorTransform.translation
        let vectorFromCamera = normalize(tapWorldPosition - cameraPosition)

        let rayOrigin = tapWorldPosition - vectorFromCamera * 0.1 
        let rayEnd = tapWorldPosition + vectorFromCamera * 0.1

        if let hitResult = rootContentEntity.scene?.raycast(from: rayOrigin, to: rayEnd, query: .any).first {
            
            var entity: Entity? = hitResult.entity
            var isMandibleHit = false
            while entity != nil {
                if entity == mandibleModel {
                    isMandibleHit = true
                    break
                }
                entity = entity?.parent
            }

            if isMandibleHit {
                let hitPosition = hitResult.position
                let hitNormal = hitResult.normal

                switch tapPhase {
                case .waitingForFirstTap:
                    firstTapPoint = hitPosition
                    firstTapNormal = hitNormal
                    tapPhase = .waitingForSecondTap
                    addTapMarker(at: hitPosition, color: .yellow) 
                    print("DEBUG: First tap recorded at \(hitPosition)")
                case .waitingForSecondTap:
                    secondTapPoint = hitPosition
                    secondTapNormal = hitNormal
                    tapPhase = .readyToSpawn
                    addTapMarker(at: hitPosition, color: .orange) 
                    print("DEBUG: Second tap recorded at \(hitPosition)")
                    spawnPlaneFromTwoTaps()
                    resetTapState()
                case .readyToSpawn:
                    resetTapState()
                    handleTap(value: value) 
                }
            } else {
                print("DEBUG: Tap did not hit the base model. Hit \(hitResult.entity.name) instead.")
            }
        } else {
            print("DEBUG: Raycast from tap did not hit any surface.")
        }
    }

    func addTapMarker(at position: SIMD3<Float>, color: UIColor) {
        let markerMesh = MeshResource.generateSphere(radius: 0.005) 
        let markerMaterial = SimpleMaterial(color: color, isMetallic: false)
        let markerEntity = ModelEntity(mesh: markerMesh, materials: [markerMaterial])
        markerEntity.position = position
        appState.rootContentEntity?.addChild(markerEntity)
        tapMarkers.append(markerEntity)
    }

    func spawnPlaneFromTwoTaps() {
        guard let p1 = firstTapPoint, let n1 = firstTapNormal,
              let p2 = secondTapPoint, let n2 = secondTapNormal,
              let bm = mandibleModel else { 
            print("DEBUG: Missing tap points or base model. Cannot spawn plane.")
            return
        }

        // Calculate center position
        let centerPosition = (p1 + p2) / 2.0

        // Calculate average normal
        let averageNormal = normalize(n1 + n2)

        // Calculate vector between tap points for plane orientation
        let tapVector = normalize(p2 - p1)

        // Construct orthonormal basis for the plane's rotation
        let zAxis = averageNormal // Plane's local Z-axis (normal)
        let xAxis = normalize(cross(averageNormal, tapVector)) // Plane's local X-axis (along the line between taps)
        let yAxis = normalize(cross(zAxis, xAxis)) // Plane's local Y-axis

        let rotationMatrix = simd_float3x3(columns: (xAxis, yAxis, zAxis))
        let planeRotation = simd_quatf(rotationMatrix)
        
        // Create a transform that aligns the plane
        let planeTransform = Transform(
            rotation: planeRotation,
            translation: centerPosition
        )

        // Adjust plane size to be more visible relative to the scaled model (assuming model is in mm)
        let planeSize: Float = 0.02 // 2cm x 2cm
        let planeMesh = MeshResource.generatePlane(width: planeSize, depth: planeSize)
        let color: UIColor = appState.currentTargetSide == .left ? .green : .red
        let material = SimpleMaterial(color: color, isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])

        // Apply the calculated transform
        planeEntity.transform = planeTransform
        
        // Make the plane interactive
        planeEntity.components.set(InputTargetComponent())
        planeEntity.generateCollisionShapes(recursive: false) // Use a simple shape
        
        // Offset the plane slightly along its normal to prevent Z-fighting and ensure visibility
        let offset: Float = 0.001 // 1 mm offset
        planeEntity.position += averageNormal * offset

        bm.addChild(planeEntity)
        cuttingPlanes.append(planeEntity)
        print("DEBUG: Plane spawned from two taps at \(centerPosition) with normal \(averageNormal)")
    }

    func resetTapState() {
        tapPhase = .waitingForFirstTap
        firstTapPoint = nil
        firstTapNormal = nil
        secondTapPoint = nil
        secondTapNormal = nil
        // Remove visual markers
        for marker in tapMarkers {
            marker.removeFromParent()
        }
        tapMarkers.removeAll()
        print("DEBUG: Tap state reset.")
    }
}
