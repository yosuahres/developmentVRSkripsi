//
//  CaseGroupLoader.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import Foundation
import RealityKit
import ARKit // Add ARKit back if AppModel needs it for ARKitSession.isSupported

@MainActor
@Observable
final class CaseGroupLoader {
    private(set) var loadedCaseGroups = [LoadedCaseGroup]() // Renamed property
    private var didStartLoading = false

    func loadCaseGroups(_ caseGroups: [CaseGroup]) async { // Renamed parameter
        guard !didStartLoading else { return }
        didStartLoading = true

        await withTaskGroup(of: LoadedCaseGroup?.self) { group in
            for caseGroup in caseGroups {
                group.addTask {
                    // Directly load USDZ model
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

            // Collect results
            for await result in group {
                if let loadedGroup = result {
                    loadedCaseGroups.append(loadedGroup)
                }
            }
        }

        // Sort by name
        loadedCaseGroups.sort { $0.group.name < $1.group.name }
    }
}
