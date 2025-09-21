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
    let usdzModelName: String
    let name: String
    let description: String
}

struct LoadedCaseGroup: Identifiable {
    let id = UUID()
    let group: CaseGroup
    let usdzEntity: Entity?
    let usdzURL: URL?
}

struct OstoetomyPlan: Identifiable {
    let id = UUID()
    var position: SIMD3<Float>
    var rotation: simd_quatf
}