//
//  FragmentData.swift
//  developmentVR
//
//  Created by HARES on 9/20/25.
//

import Foundation
import ARKit
import RealityKit

struct Slice: Codable, Hashable {
    var distanceFromLeftAnchor: Float
    var xRotationDegrees: Float
    var yRotationDegrees: Float
    var zRotationDegrees: Float
}

struct Fragment: Codable, Hashable {
    var startSlice: Slice
    var endSlice: Slice
}

struct FragmentGroup: Identifiable, Codable, Hashable {
    var id = UUID()
    let usdzModelName: String
    let name: String
    let description: String
    var fragments: [Fragment]
    var orientation: String
}

struct LoadedFragmentGroup {
    let group: FragmentGroup
    let referenceObject: ReferenceObject?
    let usdzEntity: Entity?
}
