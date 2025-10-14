//
//  Sample.swift
//  VisionOSFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 16/05/25.
//

import Foundation
import simd

//let sampleFragmentGroup = FragmentGroup(
//    name: "Test Case A",
//    description: "Simple dual-slice fragment setup for testing.",
//    usdzModelName: "fibula-2",
//    orientation: "x",
//    fragments: [
//        Fragment(
//            startSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.05, // Added 5cm offset
//                xRotationDegrees: -160.911,
//                yRotationDegrees: -83.0456,
//                zRotationDegrees: 144.811
//            ),
//            endSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1104728, // 0.05 + 0.0604728
//                xRotationDegrees: -1.97443,
//                yRotationDegrees: 55.9448,
//                zRotationDegrees: 1.21357
//            ),
//            length: 0.0604728
//        ),
//        Fragment(
//            startSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1286343, // 0.1104728 + 0.0181615
//                xRotationDegrees: -18.093,
//                yRotationDegrees: -58.4248,
//                zRotationDegrees: 5.21148
//            ),
//            endSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1606886, // 0.1286343 + 0.0320543
//                xRotationDegrees: -4.2324,
//                yRotationDegrees: 59.2235,
//                zRotationDegrees: 1.28983
//            ),
//            length: 0.0320543
//        ),
//        Fragment(
//            startSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1804378, // 0.1606886 + 0.0197492
//                xRotationDegrees: -40.5112,
//                yRotationDegrees: -50.6391,
//                zRotationDegrees: 35.8737
//            ),
//            endSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.2273878, // 0.1804378 + 0.04695
//                xRotationDegrees: -27.5019,
//                yRotationDegrees: 87.2228,
//                zRotationDegrees: -24.0868
//            ),
//            length: 0.04695
//        )
//    ]
//)
//
//let newFragmentGroup = FragmentGroup(
//    name: "Test Case A",
//    description: "New fibula color for testing.",
//    usdzModelName: "fibula-3",
//    orientation: "x",
//    fragments: [
//        Fragment(
//            startSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.05, // Added 5cm offset
//                xRotationDegrees: -160.911,
//                yRotationDegrees: -83.0456,
//                zRotationDegrees: 144.811
//            ),
//            endSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1104728, // 0.05 + 0.0604728
//                xRotationDegrees: -1.97443,
//                yRotationDegrees: 55.9448,
//                zRotationDegrees: 1.21357
//            ),
//            length: 0.0604728
//        ),
//        Fragment(
//            startSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1286343, // 0.1104728 + 0.0181615
//                xRotationDegrees: -18.093,
//                yRotationDegrees: -58.4248,
//                zRotationDegrees: 5.21148
//            ),
//            endSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1606886, // 0.1286343 + 0.0320543
//                xRotationDegrees: -4.2324,
//                yRotationDegrees: 59.2235,
//                zRotationDegrees: 1.28983
//            ),
//            length: 0.0320543
//        ),
//        Fragment(
//            startSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.1804378, // 0.1606886 + 0.0197492
//                xRotationDegrees: -40.5112,
//                yRotationDegrees: -50.6391,
//                zRotationDegrees: 35.8737
//            ),
//            endSlice: FragmentSlice(
//                distanceFromLeftAnchor: 0.2273878, // 0.1804378 + 0.04695
//                xRotationDegrees: -27.5019,
//                yRotationDegrees: 87.2228,
//                zRotationDegrees: -24.0868
//            ),
//            length: 0.04695
//        )
//    ]
//)
//
//let allFragmentGroups: [FragmentGroup] = [sampleFragmentGroup, newFragmentGroup]
