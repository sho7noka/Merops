//
// Created by sumioka-air on 2018/05/01.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import SceneKit

enum NodeOptions: Int {
    case noSelect = 1
    case noExport = 2
    case noDelete = 3
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

enum DrawOverride {
    case Object, OverrideVertex, OverrideEdge, OverrideFace
}

struct Settings {
    let projectDir: String
//    let remoteDir: URL
    let bgColor: Color

    // イニシャライザ
    init(dir: String, color: Color) {
        self.projectDir = dir
        self.bgColor = color
    }
}

//let data = Data
//
//let decoder: JSONDecoder = JSONDecoder()
//let encoder: JSONEncoder = JSONEncoder()
//do {
//    let settings: Settings = try decoder.decode(Settings.self, from: data)
//    print(settings) //Success!!!
//} catch {
//    print("json convert failed in JSONDecoder", error.localizedDescription)
//}

let SCNOptions: [SCNDebugOptions] = [
    .showPhysicsShapes,
    .showBoundingBoxes,
    .showLightInfluences,
    .showLightExtents,
    .showPhysicsFields,
    .showWireframe,
]
