////
////  ObjectTrackingRealityView.swift
////  VisionOSFibulaCuttingGuide
////
////  Created by Mohammad Zhafran Dzaky on 05/05/25.
////
//
//import SwiftUI
//import RealityKit
//import ARKit
//
//struct ObjectTrackingView: View {
//    var appState: AppState
//    var root = Entity()
//    
//    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
//    @State private var currentVisualization: ObjectAnchorVisualization?
//    
//    var body: some View {
//        RealityView { content, attachments in
//            content.add(root)
//            
//            Task {
//                guard let objectTracking = await appState.startTracking() else  {
//                    print("Failed to start object tracking.")
//                    return
//                }
//                
//                for await anchorUpdate in objectTracking.anchorUpdates {
//                    let anchor = anchorUpdate.anchor
//                    let id = anchor.id
//                    
//                    switch anchorUpdate.event {
//                    case .added:
//                        let selectedFragmentGroup = appState.selectedFragmentGroup!
//                        let model = appState.fragmentGroupLoader.loadedFragmentGroups.first(where: {$0.id == selectedFragmentGroup.id})?.usdzEntity
//                        let visualization = ObjectAnchorVisualization(for: anchor, withModel: model, fragmentGroup: selectedFragmentGroup)
//                        
//                        await MainActor.run {
//                            self.objectVisualizations[id] = visualization
//                            self.currentVisualization = visualization
//                        }
//                        
//                        root.addChild(visualization.entity)
//                        
//                        // Add lock/unlock control attachment
//                        if let controlAttachment = attachments.entity(for: "LockControl") {
//                            controlAttachment.position = [0, anchor.boundingBox.extent.y * 0.5 + 0.1, 0]
//                            controlAttachment.components.set(BillboardComponent())
//                            controlAttachment.scale = [0.5, 0.5, 0.5]
//                            
//                            visualization.entity.addChild(controlAttachment)
//                        }
//                        
//                    case .updated:
//                        objectVisualizations[id]?.update(with: anchor)
//                        
//                        // Update control panel position
//                        if let visualization = objectVisualizations[id],
//                           let controlAttachment = visualization.entity.children.first(where: { $0.components.has(ViewAttachmentComponent.self) }) {
//                            controlAttachment.position = [0, anchor.boundingBox.extent.y * 0.5 + 0.1, 0]
//                            controlAttachment.scale = [0.5, 0.5, 0.5]
//                        }
//                        
//                    case .removed:
//                        objectVisualizations[id]?.entity.removeFromParent()
//                        await MainActor.run {
//                            objectVisualizations.removeValue(forKey: id)
//                            if currentVisualization?.anchorId == id {
//                                currentVisualization = nil
//                            }
//                        }
//                    }
//                }
//            }
//        } attachments: {
//            Attachment(id: "LockControl") {
//                if let visualization = currentVisualization {
//                    LockControlView(visualization: visualization)
//                } else {
//                    Text("Searching...")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                        .padding()
//                        .glassBackgroundEffect()
//                }
//            }
//        }
//        .onAppear() {
//            print("Entering immersive space.")
//            appState.isImmersiveSpaceOpened = true
//        }
//        .onDisappear() {
//            for (_, visualization) in objectVisualizations {
//                root.removeChild(visualization.entity)
//            }
//            
//            objectVisualizations.removeAll()
//            currentVisualization = nil
//            
//            appState.didLeaveImmersiveSpace()
//        }
//    }
//}
//
//struct LockControlView: View {
//    @ObservedObject var visualization: ObjectAnchorVisualization
//    
//    var body: some View {
//        VStack(spacing: 12) {
//            // Status indicator
//            HStack {
//                Image(systemName: visualization.isPositionLocked ? "lock.fill" : "lock.open")
//                    .foregroundColor(visualization.isPositionLocked ? .green : .blue)
//                    .font(.title2)
//                
//                Text(visualization.isPositionLocked ? "Locked" : "Tracking")
//                    .font(.headline)
//                    .foregroundColor(visualization.isPositionLocked ? .green : .blue)
//            }
//            
//            Button(action: {
//                visualization.togglePositionLock()
//            }) {
//                Text(visualization.isPositionLocked ? "Unlock Position" : "Lock Position")
//                    .font(.headline)
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 8)
//                    .background(
//                        RoundedRectangle(cornerRadius: 20)
//                            .fill(visualization.isPositionLocked ? Color.green : Color.blue)
//                            .opacity(0.8)
//                    )
//                    .foregroundColor(.white)
//            }
//        }
//        .padding()
//        .glassBackgroundEffect()
//    }
//}
