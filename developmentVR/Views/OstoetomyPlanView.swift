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
    @State private var modelEntity: ModelEntity?      // keep reference
    @State private var lastDragTranslation: CGSize = .zero

    var body: some View {
        RealityView { content in
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let usdzURL = selectedCaseGroup.usdzURL {
                do {
                    let model = try await ModelEntity(contentsOf: usdzURL)

                    // create a floating anchor at x=0, y=1.5, z=0
                    let anchor = AnchorEntity(world: [0, 1.5, 0])
                    anchor.addChild(model)

                    // enable interactions
                    model.generateCollisionShapes(recursive: true)
                    model.components.set(InputTargetComponent(allowedInputTypes: .all))

                    content.add(anchor)
                    modelEntity = model
                } catch {
                    print("Error loading USDZ model from URL: \(error)")
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
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { drag in
                    guard let model = modelEntity else { return }
                    // map drag to 3D movement
                    let dx = Float(drag.translation.width - lastDragTranslation.width) * 0.002
                    let dy = Float(drag.translation.height - lastDragTranslation.height) * 0.002
                    let dz = Float(drag.translation.height - lastDragTranslation.height) * 0.002
                    model.position += [dx, dy, dz]
                    lastDragTranslation = drag.translation
                }
                .onEnded { _ in
                    lastDragTranslation = .zero
                }
        )
    }
}
