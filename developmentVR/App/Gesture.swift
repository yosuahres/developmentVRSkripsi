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

    static func rectangleDragGesture(rectangleEntity: Binding<ModelEntity?>, modelEntity: Binding<ModelEntity?>) -> some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let rect = rectangleEntity.wrappedValue, 
                      let model = modelEntity.wrappedValue,
                      value.entity == rect else { return }

                let bounds = model.visualBounds(relativeTo: model)
                let dragX = Float(value.translation.width) * 0.001
                let dragZ = Float(value.translation.height) * 0.001
                
                let maxX = Float(bounds.extents.x / 2) - 0.05
                let maxZ = Float(bounds.extents.z / 2) - 0.05
                
                rect.position.x = max(-maxX, min(maxX, dragX))
                rect.position.z = max(-maxZ, min(maxZ, dragZ))
                rect.position.y = Float(bounds.extents.y/2) + 0.1 
            }
            .onEnded { _ in
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
