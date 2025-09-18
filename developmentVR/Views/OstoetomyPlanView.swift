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
    @State private var lastDragTranslation: CGSize = .zero
    @State private var currentAngle: Float = 90 //ngadep samping
    // @State private var currentScale: Float = 0.1      

    var body: some View {
        RealityView { content in
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let usdzURL = selectedCaseGroup.usdzURL {
                do {
                    let model = try await ModelEntity(contentsOf: usdzURL)

                    // initial scale
                    // model.scale = [currentScale, currentScale, currentScale]

                    // floating anchor
                    let anchor = AnchorEntity(world: [0, 1.5, 0])
                    anchor.addChild(model)

                    // enable interaction
                    model.generateCollisionShapes(recursive: true)
                    model.components.set(InputTargetComponent(allowedInputTypes: .all))

                    content.add(anchor)
                    modelEntity = model
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
        //.simultaneousGesture(ModelGestures.pinchGesture(modelEntity: $modelEntity, currentScale: $currentScale)) // disable pinch
    }
}
