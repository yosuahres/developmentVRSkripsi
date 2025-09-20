//
//  AppState.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit

@MainActor
class AppState: ObservableObject {
    let immersiveSpaceID = "ImmersiveSpace"
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    @Published var immersiveSpaceState = ImmersiveSpaceState.closed
    @Published var isControlWindowOpened = false
    
    var isImmersiveSpaceOpened: Bool {
        immersiveSpaceState == .open
    }

    let caseGroupLoader = CaseGroupLoader()
    @Published var selectedCaseGroup: LoadedCaseGroup?

    init() {
        Task {
            await caseGroupLoader.loadCaseGroups(DummyFragmentData.caseGroups)
        }
    }

    func didLeaveImmersiveSpace() {
        immersiveSpaceState = .closed
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
