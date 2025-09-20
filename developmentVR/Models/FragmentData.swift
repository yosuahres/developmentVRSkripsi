//
//  FragmentData.swift
//  developmentVR
//
//  Created by HARES on 9/20/25.
//

import Foundation

// Placeholder structs
struct Slice {
    var distanceFromLeftAnchor: Float = 0.0
    var xRotationDegrees: Float = 0.0
    var yRotationDegrees: Float = 0.0
    var zRotationDegrees: Float = 0.0
}

struct Fragment {
    var startSlice: Slice = Slice()
    var endSlice: Slice = Slice()
}

struct FragmentGroup {
    var fragments: [Fragment] = []
    var orientation: String = "x"
}

struct LoadedFragmentGroup {
    var group: FragmentGroup = FragmentGroup()
}
