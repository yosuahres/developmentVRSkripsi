//
//  Gesture.swift
//  developmentVR
//
//  Created by HARES on 9/15/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct Gestures {

    static func dragGesture(modelEntity: Binding<ModelEntity?>, lastTranslation: Binding<CGSize>) -> some Gesture {
        MagnificationGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let model = modelEntity.wrappedValue else { return }
                let pinchValue = value.gestureValue
                let movement = Float(pinchValue - 1.0) * 0.01
                model.position += [movement, movement, movement]
            }
            .onEnded { _ in
                lastTranslation.wrappedValue = .zero
            }
    }

    static func rotationGesture(modelEntity: Binding<ModelEntity?>, currentAngle: Binding<Float>) -> some Gesture {
        MagnificationGesture()
            .onChanged { pinchValue in
                guard let model = modelEntity.wrappedValue else { return }
                let rotationAngle = currentAngle.wrappedValue + Float(pinchValue - 1.0) * 2.0
                model.transform.rotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
            }
            .onEnded { pinchValue in
                currentAngle.wrappedValue += Float(pinchValue - 1.0) * 2.0
            }
    }
    
}
