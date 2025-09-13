//
//  AppState.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit

@MainActor
@Observable
class AppState {
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
    var selectedCaseGroup: LoadedCaseGroup?

    init() {
        Task {
            await caseGroupLoader.loadCaseGroups([
                CaseGroup(usdzModelName: "toy_biplane", name: "Toy Biplane", description: "A small toy biplane."),
                CaseGroup(usdzModelName: "toy_drummer", name: "Toy Drummer", description: "A toy drummer playing drums."),
                CaseGroup(usdzModelName: "toy_robot", name: "Toy Robot", description: "A classic toy robot."),
                CaseGroup(usdzModelName: "toy_train", name: "Toy Train", description: "A toy train on tracks.")
            ])
        }
    }

    func didLeaveImmersiveSpace() {
        immersiveSpaceState = .closed
    }
}

@main
struct developmentVRApp: App {
    @State private var appState = AppState()

    var body: some SwiftUI.Scene {
        WindowGroup {
            HomeView(appState: appState, immersiveSpaceIdentifier: appState.immersiveSpaceID)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
