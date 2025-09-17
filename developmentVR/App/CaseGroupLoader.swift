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
                    guard let usdzURL = Bundle.main.url(
                        forResource: caseGroup.usdzModelName,
                        withExtension: "usdz" // Changed extension to usdz
                    ) else {
                        print("USDZ model not found for \(caseGroup.usdzModelName)")
                        return nil
                    }

                    do {
                        let usdzEntity = try await Entity(contentsOf: usdzURL)
                        return LoadedCaseGroup(
                            group: caseGroup,
                            usdzEntity: usdzEntity,
                            usdzURL: usdzURL
                        )
                    } catch {
                        print("Failed to load USDZ model for \(caseGroup.usdzModelName): \(error)")
                        return nil
                    }
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
