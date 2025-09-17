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
    @State private var currentAngle: Float = 0        
    @State private var currentScale: Float = 0.5       

    var body: some View {
        let dragGesture = DragGesture()
            .targetedToAnyEntity()
            .onChanged { drag in
                guard let model = modelEntity else { return }
                let dx = Float(drag.translation.width - lastDragTranslation.width) * 0.002
                let dy = Float(drag.translation.height - lastDragTranslation.height) * 0.002
                let dz = Float(drag.translation.height - lastDragTranslation.height) * 0.002
                model.position += [dx, dy, dz]
                lastDragTranslation = drag.translation
            }
            .onEnded { _ in
                lastDragTranslation = .zero
            }

        let rotationGesture = RotationGesture()
            .onChanged { value in
                guard let model = modelEntity else { return }
                model.transform.rotation = simd_quatf(angle: currentAngle + Float(value.radians), axis: [0, 1, 0])
            }
            .onEnded { value in
                currentAngle += Float(value.radians)
            }

        /*
        // pinch to scale function
        let pinchGesture = MagnificationGesture()
            .onChanged { value in
                guard let model = modelEntity else { return }
                model.scale = [currentScale * Float(value), currentScale * Float(value), currentScale * Float(value)]
            }
            .onEnded { value in
                currentScale *= Float(value)
            }
        */

        return RealityView { content in
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let usdzURL = selectedCaseGroup.usdzURL {
                do {
                    let model = try await ModelEntity(contentsOf: usdzURL)

                    // initial scale
                    model.scale = [currentScale, currentScale, currentScale]

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
        .gesture(dragGesture)
        .simultaneousGesture(rotationGesture)
        //.simultaneousGesture(pinchGesture) 
    }
}
