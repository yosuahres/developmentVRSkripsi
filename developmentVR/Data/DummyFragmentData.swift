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
            usdzModelNames: ["CATALUNYA FENDA AUFAA OTILA_Mandibula_001", "CATALUNYA FENDA AUFAA OTILA_Maxilla_001"],
            name: "Mandible & Maxilla Case 1",
            description: "Combined Mandible and Maxilla for Case 1"
        ),
        CaseGroup(
            usdzModelNames: ["CHARIS KRISNA MUKTI_ TN_Mandibula_001", "CHARIS KRISNA MUKTI_ TN_Maxilla_001"],
            name: "Mandible & Maxilla Case 2",
            description: "Combined Mandible and Maxilla for Case 2"
        ),
    ]
}
