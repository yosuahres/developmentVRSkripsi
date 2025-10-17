//
//  Gesture.swift
//  developmentVR
//
//  Created by HARES on 9/15/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct Gestures {
    static func dragGesture(modelEntity: Binding<ModelEntity?>, initialTransform: Binding<Transform?>) -> some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                if modelEntity.wrappedValue == nil {
                    modelEntity.wrappedValue = value.entity as? ModelEntity
                }

                guard let model = modelEntity.wrappedValue else { return }

                if initialTransform.wrappedValue == nil {
                    initialTransform.wrappedValue = model.transform
                }

                // Convert the translation from the local coordinate space of the gesture
                // to the coordinate space of the model's parent.
                let convertedTranslation = value.convert(value.translation3D, from: .local, to: model.parent!)

                var newTransform = initialTransform.wrappedValue!
                newTransform.translation += SIMD3<Float>(convertedTranslation)
                model.transform = newTransform
            }
            .onEnded { _ in
                initialTransform.wrappedValue = nil
                modelEntity.wrappedValue = nil
            }
    }

    static func rotationGesture(modelEntity: Binding<ModelEntity?>, initialRotation: Binding<simd_quatf?>) -> some Gesture {
        RotateGesture3D(constrainedToAxis: .z, minimumAngleDelta: .degrees(1)) // Constrain to X-axis
            .targetedToAnyEntity()
            .onChanged { value in
                if modelEntity.wrappedValue == nil {
                    modelEntity.wrappedValue = value.entity as? ModelEntity
                }
                
                guard let model = modelEntity.wrappedValue else { return }

                if initialRotation.wrappedValue == nil {
                    initialRotation.wrappedValue = model.transform.rotation
                }

                // Create a quaternion that represents the total rotation of the gesture
                // from its starting point. Since the gesture is constrained to the X-axis,
                // this rotation will only be around the X-axis.
                let gestureRotation = simd_quatf(value.rotation)
                
                // Apply the gesture's rotation to the initial rotation of the model.
                // Multiplying the initial rotation by the gesture's rotation applies
                // the change relative to the model's orientation at the start of the gesture.
                model.transform.rotation = initialRotation.wrappedValue! * gestureRotation
            }
            .onEnded { _ in
                initialRotation.wrappedValue = nil
                modelEntity.wrappedValue = nil
            }
    }
}
