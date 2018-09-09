//
// Created by sumioka-air on 2018/05/01.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import Foundation
import SceneKit

struct Settings {
    let projectDir: String
    let bgColor: Color
    let usdDir: String
    let pythonDir: String
    
    init(dir: String, color: Color, usdDir: String, pyDir: String) {
        self.projectDir = dir
        self.bgColor = color
        self.usdDir = usdDir
        self.pythonDir = pyDir
    }
    
//    public init(from decoder: Decoder) throws {
//        let url = URL(fileURLWithPath: projectDir + "/setting.json")
//        let data = try Data(contentsOf: url)
//        try JSONDecoder().decode(Settings.self, from: data)
//    }
    
//    public func encode(to encoder: Encoder) throws {
//        JSONEncoder().encode(<#T##value: Encodable##Encodable#>)
//    }
}

enum NodeOptions: Int {
    case noSelect = 1
    case noExport = 2
    case noDelete = 3
}

enum DrawOverride {
    case Object, OverrideVertex, OverrideEdge, OverrideFace
}

enum EditContext {
    case Object, PositionMode, ScaleMode, RotateMode
    
    var toString : String! {
        switch self {
        case .Object:
            return "Object"
        case .PositionMode:
            return "Position"
        case .ScaleMode:
            return "Scale"
        case .RotateMode:
            return "Rotate"
        }
    }
}

enum CameraPosition {
    case top, right, left, back, bottom, front
    
    var vec : SCNVector3 {
        switch self {
        case .top:
            return SCNVector3(0, 1, 0)
        case .right:
            return SCNVector3(1, 0, 0)
        case .left:
            return SCNVector3(-1, 0, 0)
        case .front:
            return SCNVector3(0, 0, 1)
        case .back:
            return SCNVector3(0, 0, -1)
        case .bottom:
            return SCNVector3(0, -1, 0)
        }
    }
}

let SCNOptions: [SCNDebugOptions] = [
    .showPhysicsShapes,
    .showBoundingBoxes,
    .showLightInfluences,
    .showLightExtents,
    .showPhysicsFields,
    .showWireframe,
]
