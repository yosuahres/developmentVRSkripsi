//
//  DummyFragmentData.swift
//  developmentVR
//
//  Created by HARES on 9/21/25.
//

import Foundation

struct DummyFragmentData {
    static let caseGroups: [CaseGroup] = [
        CaseGroup(
            usdzModelName: "Mandible",
            name: "Mandible Case",
            description: "A case with a mandible model and fragment data.",
            fragmentGroups: [
                FragmentGroup(
                    usdzModelName: "Mandible",
                    name: "Mandible Fragments",
                    description: "Fragments for the mandible.",
                    fragments: [
                        Fragment(
                            startSlice: Slice(distanceFromLeftAnchor: 0.1, xRotationDegrees: 0, yRotationDegrees: 0, zRotationDegrees: 0),
                            endSlice: Slice(distanceFromLeftAnchor: 0.2, xRotationDegrees: 0, yRotationDegrees: 0, zRotationDegrees: 0)
                        ),
                        Fragment(
                            startSlice: Slice(distanceFromLeftAnchor: 0.3, xRotationDegrees: 0, yRotationDegrees: 15, zRotationDegrees: 0),
                            endSlice: Slice(distanceFromLeftAnchor: 0.4, xRotationDegrees: 0, yRotationDegrees: 15, zRotationDegrees: 0)
                        )
                    ],
                    orientation: "x"
                )
            ]
        ),
        CaseGroup(
            usdzModelName: "Mandible",
            name: "Mandible Case 2",
            description: "Another case with a mandible model and no fragment data."
        )
    ]
}
