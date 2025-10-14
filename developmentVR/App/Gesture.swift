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

                let dragTranslation = value.translation3D
                var newTransform = initialTransform.wrappedValue!
                newTransform.translation += SIMD3<Float>(Float(dragTranslation.x), Float(dragTranslation.y), Float(dragTranslation.z))
                model.transform = newTransform
            }
            .onEnded { _ in
                initialTransform.wrappedValue = nil
                modelEntity.wrappedValue = nil
            }
    }

    static func rotationGesture(modelEntity: Binding<ModelEntity?>, initialRotation: Binding<simd_quatf?>) -> some Gesture {
        RotateGesture3D(minimumAngleDelta: .degrees(1))
            .targetedToAnyEntity()
            .onChanged { value in
                if modelEntity.wrappedValue == nil {
                    modelEntity.wrappedValue = value.entity as? ModelEntity
                }
                
                guard let model = modelEntity.wrappedValue else { return }

                if initialRotation.wrappedValue == nil {
                    initialRotation.wrappedValue = model.transform.rotation
                }

                let rotation = value.rotation
                let qd = rotation.quaternion
                let qf = simd_quatf(ix: Float(qd.imag.x), iy: Float(qd.imag.y), iz: Float(qd.imag.z), r: Float(qd.real))
                let newRotation = initialRotation.wrappedValue! * qf
                model.transform.rotation = newRotation
            }
            .onEnded { _ in
                initialRotation.wrappedValue = nil
                modelEntity.wrappedValue = nil
            }
    }
    
    static func magnificationGesture(modelEntity: Binding<ModelEntity?>, initialScale: Binding<SIMD3<Float>?>) -> some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                if modelEntity.wrappedValue == nil {
                    modelEntity.wrappedValue = value.entity as? ModelEntity
                }
                
                guard let model = modelEntity.wrappedValue else { return }

                if initialScale.wrappedValue == nil {
                    initialScale.wrappedValue = model.transform.scale
                }
                
                let magnification = Float(value.magnification)
                var newScale = initialScale.wrappedValue!
                newScale *= magnification
                model.transform.scale = newScale
            }
            .onEnded { _ in
                initialScale.wrappedValue = nil
                modelEntity.wrappedValue = nil
            }
    }
}
