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
    
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var isImmersiveSpaceOpened: Bool {
        immersiveSpaceState == .open
    }

    let caseGroupLoader = CaseGroupLoader()
    @Published var selectedCaseGroup: LoadedCaseGroup?

    init() {
        Task {
            await caseGroupLoader.loadCaseGroups([
                CaseGroup(usdzModelName: "blue-1", name: "Blue 1", description: "Blue 1 USDZ model."),
                CaseGroup(usdzModelName: "bone-white-1", name: "Bone White 1", description: "Bone White 1 USDZ model.")
            ])
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
        WindowGroup {
            HomeView(appState: appState, immersiveSpaceIdentifier: appState.immersiveSpaceID)
        }

        ImmersiveSpace(id: appState.immersiveSpaceID) {
            OstoetomyPlanView(appState: appState)
                .onAppear {
                    appState.immersiveSpaceState = .open
                }
                .onDisappear {
                    appState.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
