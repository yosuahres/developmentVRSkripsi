import SwiftUI
import RealityKit
import RealityKitContent

struct Gestures {

    static func dragGesture(modelEntity: Binding<ModelEntity?>, lastTranslation: Binding<CGSize>) -> some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { drag in
                guard let model = modelEntity.wrappedValue else { return }
                let dx = Float(drag.translation.width - lastTranslation.wrappedValue.width) * 0.002
                let dy = Float(drag.translation.height - lastTranslation.wrappedValue.height) * 0.002
                let dz = Float(drag.translation.height - lastTranslation.wrappedValue.height) * 0.002
                model.position += [dx, dy, dz]
                lastTranslation.wrappedValue = drag.translation
            }
            .onEnded { _ in
                lastTranslation.wrappedValue = .zero
            }
    }

    static func rotationGesture(modelEntity: Binding<ModelEntity?>, currentAngle: Binding<Float>) -> some Gesture {
        RotationGesture()
            .onChanged { value in
                guard let model = modelEntity.wrappedValue else { return }
                model.transform.rotation = simd_quatf(angle: currentAngle.wrappedValue + Float(value.radians), axis: [0, 1, 0])
            }
            .onEnded { value in
                currentAngle.wrappedValue += Float(value.radians)
            }
    }
    /*
    // Pinch to scale (disabled for now)
    static func pinchGesture(modelEntity: Binding<ModelEntity?>, currentScale: Binding<Float>) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard let model = modelEntity.wrappedValue else { return }
                model.scale = [currentScale.wrappedValue * Float(value),
                               currentScale.wrappedValue * Float(value),
                               currentScale.wrappedValue * Float(value)]
            }
            .onEnded { value in
                currentScale.wrappedValue *= Float(value)
            }
    }
    */
}
