//
//  HomeView.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit

struct HomeView: View {
    @ObservedObject var appState: AppState
    let immersiveSpaceIdentifier: String
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    //for controls
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State var selectedCaseGroupId: UUID? 
    @State private var searchText: String = ""
    
    var filteredCaseGroups: [LoadedCaseGroup] {
        if searchText.isEmpty {
            return appState.caseGroupLoader.loadedCaseGroups
        } else {
            return appState.caseGroupLoader.loadedCaseGroups.filter {
                $0.group.name.localizedCaseInsensitiveContains(searchText) ||
                $0.group.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack {
                List(selection: $selectedCaseGroupId) {
                    ForEach(filteredCaseGroups, id: \.id) { caseGroup in
                        HStack(spacing: 8) {
                            Image("glyph")
                                .resizable()
                                .frame(width: 50, height: 50)
                            VStack(alignment: .leading) {
                                Text(caseGroup.group.name)
                                Text(caseGroup.group.description)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Session")
                .searchable(text: $searchText, prompt: "Search groups")
            }
        } detail: {
            if let selectedObject = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroupId}) {
                if let firstUsdzURL = selectedObject.usdzURLs.first, let usdzURL = firstUsdzURL {
                    Model3D(url: usdzURL) { model in
                        model
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(0.5)
                            .offset(y: -50)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Text("No preview available")
                }
            } else {
                Text("No object selected")
            }
        }
        .frame(minWidth: 800, minHeight: 300)
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                VStack {
                    if appState.immersiveSpaceState == .closed {
                        if let selectedCaseGroupId, let selectedObject = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroupId}) {
                            Button("Open Immersive Space") {
                                appState.selectedCaseGroup = selectedObject
                                appState.immersiveSpaceState = .inTransition
                                Task {
                                    switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                    case .opened:
                                        appState.immersiveSpaceState = .open
                                        await appState.openControlsWindow(openWindow: openWindow, dismissWindow: dismissWindow)
                                        dismissWindow(id: "main")
                                    case .error:
                                        print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
                                        appState.immersiveSpaceState = .closed
                                    case .userCancelled:
                                        print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
                                        appState.immersiveSpaceState = .closed
                                    @unknown default:
                                        appState.immersiveSpaceState = .closed
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// #Preview {
//     HomeView(appState: AppState(), immersiveSpaceIdentifier: "ImmersiveSpace")
// }
