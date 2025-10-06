//
//  CaseGroupLoader.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import Foundation
import RealityKit
import ARKit

@MainActor
@Observable
final class CaseGroupLoader {
    private(set) var loadedCaseGroups = [LoadedCaseGroup]()
    private var didStartLoading = false

    func loadCaseGroups(_ caseGroups: [CaseGroup]) async {
        guard !didStartLoading else { return }
        didStartLoading = true

        await withTaskGroup(of: LoadedCaseGroup?.self) { group in
            for caseGroup in caseGroups {
                group.addTask {
                    var usdzEntities: [Entity?] = []
                    var usdzURLs: [URL?] = []

                    for modelName in caseGroup.usdzModelNames {
                        guard let usdzURL = Bundle.main.url(
                            forResource: modelName,
                            withExtension: "usdz"
                        ) else {
                            print("USDZ model not found for \(modelName)")
                            usdzEntities.append(nil)
                            usdzURLs.append(nil)
                            continue
                        }

                        do {
                            let usdzEntity = try await Entity(contentsOf: usdzURL)
                            usdzEntities.append(usdzEntity)
                            usdzURLs.append(usdzURL)
                        } catch {
                            print("Failed to load USDZ model for \(modelName): \(error)")
                            usdzEntities.append(nil)
                            usdzURLs.append(nil)
                        }
                    }
                    
                    let loadedCaseGroup = LoadedCaseGroup(
                        group: caseGroup,
                        usdzEntities: usdzEntities,
                        usdzURLs: usdzURLs
                    )
                    
                    return loadedCaseGroup
                }
            }

            for await result in group {
                if let loadedGroup = result {
                    loadedCaseGroups.append(loadedGroup)
                }
            }
        }

        loadedCaseGroups.sort { $0.group.name < $1.group.name }
    }
}
