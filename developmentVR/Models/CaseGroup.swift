//
//  CaseGroup.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import Foundation
import RealityKit

struct CaseGroup: Identifiable, Hashable {
    let id = UUID()
    let usdzModelNames: [String]
    let name: String
    let description: String
}

struct LoadedCaseGroup: Identifiable {
    let id = UUID()
    let group: CaseGroup
    let usdzEntities: [Entity?]
    let usdzURLs: [URL?]
}
