//
// Created by sumioka-air on 2018/05/01.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import SceneKit

enum NodeOptions: Int {
    case noExport = 1
    case noDelete = 2
}

enum EditContext {
    case Object, PositionMode, ScaleMode, RotateMode
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
