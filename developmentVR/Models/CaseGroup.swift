//
//  CaseGroup.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import Foundation
import RealityKit // Required for Entity

struct CaseGroup: Identifiable, Hashable {
    let id = UUID()
    let usdzModelName: String
    let name: String
    let description: String
}

struct LoadedCaseGroup: Identifiable {
    let id = UUID()
    let group: CaseGroup
    let usdzEntity: Entity?
    let usdzURL: URL? // Store the URL for direct use in Model3D
}
