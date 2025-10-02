//
//  AppState.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
class AppState: ObservableObject {
    let immersiveSpaceID = "ImmersiveSpace"
    let caseGroupLoader = CaseGroupLoader()
    
    @Published var immersiveSpaceState = ImmersiveSpaceState.closed
    @Published var isControlWindowOpened = false
    @Published var controlsWindowState: WindowState = .closed

    @Published var selectedCaseGroup: LoadedCaseGroup?
    @Published var osteotomyPlanes: [OstoetomyPlan] = []
    
    // MARK: - Raycast Support
    var mandibleModelEntity: ModelEntity?
    var realityViewContent: RealityViewContent?
    var mandibleAnchorWorldPosition: SIMD3<Float> = SIMD3<Float>(0, 1.5, -2)
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    enum WindowState {
        case closed
        case opening
        case open
    }
    
    var isImmersiveSpaceOpened: Bool {
        immersiveSpaceState == .open
    }
    
    var currentModelPosition: SIMD3<Float> {
        if selectedCaseGroup?.usdzURL != nil {
            let basePosition: SIMD3<Float> = [0, 1.5, -2]
            let randomOffset: SIMD3<Float> = [
                Float.random(in: -0.2...0.2),
                Float.random(in: -0.1...0.1), 
                Float.random(in: -0.2...0.2)
            ]
            return basePosition + randomOffset
        } else {
            return [
                Float.random(in: -0.3...0.3),
                Float.random(in: -0.1...0.1),
                Float.random(in: -0.3...0.3)
            ]
        }
    }

    init() {
        Task {
            await caseGroupLoader.loadCaseGroups(DummyFragmentData.caseGroups)
        }
    }

    func didLeaveImmersiveSpace() {
        immersiveSpaceState = .closed
    }
    
    func openControlsWindow(openWindow: OpenWindowAction, dismissWindow: DismissWindowAction) async {
        dismissWindow(id: "controls")
        
        controlsWindowState = .opening
        openWindow(id: "controls")
        controlsWindowState = .open
    }
    
    func closeControlsWindow(dismissWindow: DismissWindowAction) async {
        dismissWindow(id: "controls")
        controlsWindowState = .closed
    }
    
    // MARK: - Raycast Functions
    func performMandibleRaycast() {
        guard let content = realityViewContent else {
            print("❌ No RealityView content available for raycast")
            return
        }
        
        Gestures.performMandibleRaycast(
            modelEntity: mandibleModelEntity,
            content: content,
            mandibleAnchorWorldPosition: mandibleAnchorWorldPosition
        )
    }
    
    func setMandibleReferences(modelEntity: ModelEntity?, content: RealityViewContent, anchorPosition: SIMD3<Float>) {
        self.mandibleModelEntity = modelEntity
        self.realityViewContent = content
        self.mandibleAnchorWorldPosition = anchorPosition
    }
}

@main
struct developmentVRApp: App {
    @StateObject private var appState = AppState()

    var body: some SwiftUI.Scene {
        WindowGroup(id: "main") {
            HomeView(appState: appState, immersiveSpaceIdentifier: appState.immersiveSpaceID)
        }
        .windowStyle(.plain)
        
        WindowGroup(id: "controls") {
            ImmersiveControlsView(appState: appState)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 300, height: 400)

        ImmersiveSpace(id: appState.immersiveSpaceID) {
            OstoetomyPlanView(appState: appState)
                .onAppear {
                    appState.immersiveSpaceState = .open
                    appState.isControlWindowOpened = true
                }
                .onDisappear {
                    appState.immersiveSpaceState = .closed
                    appState.isControlWindowOpened = false
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
