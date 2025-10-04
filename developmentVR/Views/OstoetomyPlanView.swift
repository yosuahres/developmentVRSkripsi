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
    @StateObject private var rulerManager = RulerManager()
    @State private var objectAnchorVisualization: ObjectAnchorVisualization?
    @State private var mandibleModelEntity: ModelEntity?
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero 
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var currentScale: Float = 0.1
    @State private var cuttingPlanes: [Entity] = []
    @State private var hitDots: [Entity] = []
    @State private var planePositions: [SIMD3<Float>] = []
    @State private var rootContentEntity: Entity?
    
    private let realWorldScale: Float = 100.0

    var body: some View {
        ZStack {
            RealityView { content in
            let rootEntity = Entity()
            content.add(rootEntity)
            rootContentEntity = rootEntity
            
            if let entity = try? await Entity(named: "Mandible", in: realityKitContentBundle) {
                if let mandible = entity as? ModelEntity {
                    let mandibleAnchor = AnchorEntity(world: [0, 1.5, -2])
                    mandibleAnchor.addChild(mandible)
                    mandible.scale = [currentScale, currentScale, currentScale]
                    mandible.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])
                    
                    mandible.components.set(InputTargetComponent())
                    mandible.generateCollisionShapes(recursive: true)
                    
                    rootEntity.addChild(mandibleAnchor)
                    mandibleModelEntity = mandible
                    mandibleAnchorWorldPosition = SIMD3<Float>(0, 1.5, -2)
                }
            } else {
                if let selectedCaseGroup = appState.selectedCaseGroup,
                   let usdzURL = selectedCaseGroup.usdzURL {
                    do {
                        let visualization = try await ObjectAnchorVisualization(usdzURL: usdzURL, scale: 1.0)
                        let anchor = AnchorEntity(world: [0, 1.5, -2])
                        anchor.addChild(visualization.entity)
                        visualization.entity.scale = [currentScale, currentScale, currentScale]
                        visualization.entity.transform.rotation = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])
                        
                        if let model = visualization.modelEntity {
                            model.components.set(InputTargetComponent())
                            model.generateCollisionShapes(recursive: true)
                        }
                        
                        rootEntity.addChild(anchor)
                        objectAnchorVisualization = visualization
                        mandibleModelEntity = visualization.modelEntity
                        mandibleAnchorWorldPosition = SIMD3<Float>(0, 1.5, -2)
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
            }
            
        } update: { content in
            // Update existing cutting planes if needed
        }
        .simultaneousGesture(Gestures.tapGesture(
            modelEntity: Binding(
                get: { mandibleModelEntity },
                set: { _ in }
            ), 
            appState: appState, 
            mandibleAnchorWorldPosition: mandibleAnchorWorldPosition
        ) { hitInfo in
            if rulerManager.isRulerMode {
                handleRulerTap(at: hitInfo.position)
            } else {
                spawnHitDot(at: hitInfo.position)
                spawnCuttingPlane(at: hitInfo.position, normal: hitInfo.normal)
            }
        })
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
                    VStack(spacing: 15) {
                        Text("Measurement Tools")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Button(action: { rulerManager.toggleRulerMode() }) {
                            HStack {
                                Image(systemName: rulerManager.isRulerMode ? "ruler.fill" : "ruler")
                                Text(rulerManager.isRulerMode ? "Exit Ruler Mode" : "Ruler Mode")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(rulerManager.isRulerMode ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        
                        Button(action: { 
                            guard let rootEntity = rootContentEntity else { return }
                            rulerManager.clearAllRulers()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Rulers")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(Color.red)
                        .cornerRadius(10)
                        
                        if rulerManager.isRulerMode {
                            Text(rulerManager.selectedPlaneIndex != nil ? "Tap to set end point" : "Tap near a plane to start")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Tap to create planes")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Text("Planes: \(planePositions.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Rulers: \(rulerManager.rulers.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(15)
                    .padding(.trailing, 30)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private func spawnHitDot(at position: SIMD3<Float>) {
        print("🔴 Spawning hit dot at position: \(position)")
        
        let hitDot = Entity.createHitDot(at: position, color: .green)
        if let rootEntity = rootContentEntity {
            rootEntity.addChild(hitDot)
            hitDots.append(hitDot)
            print("✅ Added hit dot to scene. Total dots: \(hitDots.count)")
        } else {
            print("❌ Failed to add hit dot - no root entity")
        }
    }
    
    private func spawnCuttingPlane(at position: SIMD3<Float>, normal: SIMD3<Float>) {
        print("🎯 Spawning cutting plane at position: \(position), normal: \(normal)")
        
        planePositions.append(position)
        
        if normal.x.isNaN || normal.y.isNaN || normal.z.isNaN {
            print("❌ Invalid normal detected, using default upward normal")
            let safeNormal = SIMD3<Float>(0, 1, 0)
            let cuttingPlane = Entity.createCuttingPlane(at: position, normal: safeNormal, size: 0.2)
            
            if let rootEntity = rootContentEntity {
                rootEntity.addChild(cuttingPlane)
                cuttingPlanes.append(cuttingPlane)
                print("✅ Added cutting plane with safe normal to scene. Total planes: \(cuttingPlanes.count)")
            }
            return
        }
        
        let cuttingPlane = Entity.createCuttingPlane(at: position, normal: normal, size: 0.2)
        if let rootEntity = rootContentEntity {
            rootEntity.addChild(cuttingPlane)
            cuttingPlanes.append(cuttingPlane)
            print("✅ Added cutting plane to scene. Total planes: \(cuttingPlanes.count)")
            
            if planePositions.count >= 2 {
                rulerManager.createRulerBetweenLastTwoPlanes(planePositions: planePositions, rootEntity: rootEntity)
            }
        } else {
            print("❌ Failed to add cutting plane - no root entity")
        }
    }
    
    private func handleRulerTap(at position: SIMD3<Float>) {
        guard let rootEntity = rootContentEntity else {
            print("❌ No root entity available for ruler creation")
            return
        }
        
        rulerManager.handleRulerTap(
            at: position, 
            planePositions: planePositions, 
            rootEntity: rootEntity
        )
    }
}
