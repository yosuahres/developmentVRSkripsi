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
    private(set) var loadedFragmentGroups = [LoadedFragmentGroup]()
    private var didStartLoading = false

    func loadCaseGroups(_ caseGroups: [CaseGroup]) async {
        guard !didStartLoading else { return }
        didStartLoading = true

        await withTaskGroup(of: LoadedCaseGroup?.self) { group in
            for caseGroup in caseGroups {
                group.addTask {
                    guard let usdzURL = Bundle.main.url(
                        forResource: caseGroup.usdzModelName,
                        withExtension: "usdz"
                    ) else {
                        print("USDZ model not found for \(caseGroup.usdzModelName)")
                        return nil
                    }

                    do {
                        let usdzEntity = try await Entity(contentsOf: usdzURL)
                        var loadedCaseGroup = LoadedCaseGroup(
                            group: caseGroup,
                            usdzEntity: usdzEntity,
                            usdzURL: usdzURL
                        )

                        if !caseGroup.fragmentGroups.isEmpty {
                            let loadedFragments = await self.loadFragmentGroups(caseGroup.fragmentGroups)
                            loadedCaseGroup.loadedFragmentGroups = loadedFragments
                        }
                        
                        return loadedCaseGroup
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

    private func loadFragmentGroups(_ fragmentGroups: [FragmentGroup]) async -> [LoadedFragmentGroup] {
        var loadedFragments = [LoadedFragmentGroup]()
        
        await withTaskGroup(of: LoadedFragmentGroup?.self) { group in
            for fragmentGroup in fragmentGroups {
                group.addTask {
                    guard let url = Bundle.main.url(
                        forResource: fragmentGroup.usdzModelName,
                        withExtension: "referenceobject"
                    ) else {
                        print("Reference object not found for \(fragmentGroup.usdzModelName)")
                        return nil
                    }

                    do {
                        let referenceObject = try await ReferenceObject(from: url)

                        var usdzEntity: Entity? = nil
                        if let usdzURL = referenceObject.usdzFile {
                            do {
                                usdzEntity = try await Entity(contentsOf: usdzURL)
                            } catch {
                                print("Failed to load USDZ model \(fragmentGroup.usdzModelName)")
                            }
                        }

                        return LoadedFragmentGroup(
                            group: fragmentGroup,
                            referenceObject: referenceObject,
                            usdzEntity: usdzEntity
                        )
                    } catch {
                        print("Failed to load reference object for \(fragmentGroup.usdzModelName): \(error)")
                        return nil
                    }
                }
            }

            for await result in group {
                if let loadedGroup = result {
                    loadedFragments.append(loadedGroup)
                }
            }
        }
        
        loadedFragments.sort { $0.group.name < $1.group.name }
        return loadedFragments
    }
}
