//
//  HomeView.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import SwiftUI
import RealityKit

struct HomeView: View {
    @Bindable var appState: AppState
    let immersiveSpaceIdentifier: String
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
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
        Group {
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
                    if let usdzURL = selectedObject.usdzURL {
                        Model3D(url: usdzURL) { model in
                            model
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(0.8)
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
            .frame(minWidth: 400, minHeight: 300)
        }
        .glassBackgroundEffect()
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                VStack {
                    if !appState.isImmersiveSpaceOpened {
                        if let selectedCaseGroupId, let selectedObject = appState.caseGroupLoader.loadedCaseGroups.first(where: { $0.id == selectedCaseGroupId}) {
                            Button("Open Immersive Space") {
                                appState.selectedCaseGroup = selectedObject
                                Task {
                                    switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                    case .opened:
                                        appState.immersiveSpaceState = .open
                                    case .error:
                                        print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
                                    case .userCancelled:
                                        print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
                                    @unknown default:
                                        break
                                    }
                                }
                            }
                        }
                    } else {
                        Button("Close Immersive Space") {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(appState: AppState(), immersiveSpaceIdentifier: "ImmersiveSpace")
}
