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
    @State private var mandibleAnchorWorldPosition: SIMD3<Float> = .zero 
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 0
    @State private var cuttingPlanes: [Entity] = []
    @State private var hitDots: [Entity] = []
    
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
                    let anchor = AnchorEntity(world: [0, 1.5, -2])
                    anchor.addChild(visualization.entity)
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
            if appState.rulerManager.isRulerMode {
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
                    EmptyView()
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                }
            }
        }
    }
    
    private func spawnHitDot(at position: SIMD3<Float>) {
        print("🔴 Spawning hit dot at position: \(position)")
        
        let hitDot = Entity.createHitDot(at: position, color: .green)
        if let rootEntity = appState.rootContentEntity {
            rootEntity.addChild(hitDot)
            hitDots.append(hitDot)
            print("✅ Added hit dot to scene. Total dots: \(hitDots.count)")
        } else {
            print("❌ Failed to add hit dot - no root entity")
        }
    }
    
    private func spawnCuttingPlane(at position: SIMD3<Float>, normal: SIMD3<Float>) {
        print("🎯 Spawning cutting plane at position: \(position), normal: \(normal)")
        
        appState.planePositions.append(position)
        
        if normal.x.isNaN || normal.y.isNaN || normal.z.isNaN {
            print("❌ Invalid normal detected, using default upward normal")
            let safeNormal = SIMD3<Float>(0, 1, 0)
            let cuttingPlane = Entity.createCuttingPlane(at: position, normal: safeNormal, size: 0.2)
            
            if let rootEntity = appState.rootContentEntity {
                rootEntity.addChild(cuttingPlane)
                cuttingPlanes.append(cuttingPlane)
                print("✅ Added cutting plane with safe normal to scene. Total planes: \(cuttingPlanes.count)")
            }
            return
        }
        
        let cuttingPlane = Entity.createCuttingPlane(at: position, normal: normal, size: 0.2)
        if let rootEntity = appState.rootContentEntity {
            rootEntity.addChild(cuttingPlane)
            cuttingPlanes.append(cuttingPlane)
            print("✅ Added cutting plane to scene. Total planes: \(cuttingPlanes.count)")
            
            if appState.planePositions.count >= 2 {
                appState.rulerManager.createRulerBetweenLastTwoPlanes(planePositions: appState.planePositions, rootEntity: rootEntity)
            }
        } else {
            print("❌ Failed to add cutting plane - no root entity")
        }
    }
    
    private func handleRulerTap(at position: SIMD3<Float>) {
        guard let rootEntity = appState.rootContentEntity else {
            print("❌ No root entity available for ruler creation")
            return
        }
        
        appState.rulerManager.handleRulerTap(
            at: position, 
            planePositions: appState.planePositions, 
            rootEntity: rootEntity
        )
    }
}
