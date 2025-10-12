//
//  AppState.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum TargetSide {
    case left
    case right
}

@MainActor
class AppState: ObservableObject {
    let immersiveSpaceID = "ImmersiveSpace"
    let caseGroupLoader = CaseGroupLoader()
    
    @Published var immersiveSpaceState = ImmersiveSpaceState.closed
    @Published var isControlWindowOpened = false
    @Published var controlsWindowState: WindowState = .closed

    @Published var selectedCaseGroup: LoadedCaseGroup?
    
    // management state
    @Published var rulerManager = RulerManager()
    @Published var planePositions: [SIMD3<Float>] = []
    @Published var rootContentEntity: Entity?
    @Published var isMaxillaVisible: Bool = true
    @Published var isMandibleVisible: Bool = true
    @Published var maxillaOpacityToggle: Bool = true
    @Published var mandibleOpacityToggle: Bool = true
    @Published var currentTargetSide: TargetSide = .left
    var maxillaOpacity: Float {
        return maxillaOpacityToggle ? 1.0 : 0.5
    }
    
    var mandibleOpacity: Float {
        return mandibleOpacityToggle ? 1.0 : 0.5
    }
    
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
        if let usdzURLs = selectedCaseGroup?.usdzURLs, !usdzURLs.isEmpty {
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
    
    func toggleMaxillaVisibility() {
        isMaxillaVisible.toggle()
    }
    
    func toggleMandibleVisibility() {
        isMandibleVisible.toggle()
    }
    
    func toggleOpacityMaxilla() {
        maxillaOpacityToggle.toggle()
    }
    
    func toggleOpacityMandible() {
        mandibleOpacityToggle.toggle()
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
