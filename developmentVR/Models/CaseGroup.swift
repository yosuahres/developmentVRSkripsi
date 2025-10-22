//
//  CaseGroup.swift
//  developmentVR
//
//  Created by HARES on 9/13/25.
//

import Foundation
import RealityKit
import ARKit

struct CaseGroup: Identifiable, Hashable {
    let id = UUID()
    let usdzModelNames: [String]
    let referenceObjectNames: [String] 
    let name: String
    let description: String
}

struct LoadedCaseGroup: Identifiable {
    //vr
    let id = UUID()
    let group: CaseGroup
    let usdzEntities: [Entity?]
    let usdzURLs: [URL?]
    
    //ar
    var referenceObjects: [ARReferenceObject]
}
