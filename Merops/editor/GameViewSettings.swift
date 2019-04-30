//
// Created by sumioka-air on 2018/05/01.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import Foundation

struct Settings {
    let projectDir: String
    let bgColor: Color
    let usdDir: String
    let pythonDir: String
    let editor: String
    
    init(dir: String, color: Color, usdDir: String, pyDir: String, editor: String) {
        self.projectDir = dir
        self.bgColor = color
        self.usdDir = usdDir
        self.pythonDir = pyDir
        self.editor = editor
    }
}

enum NodeOptions: Int {
    case noSelect = 2
    case noExport = 3
    case noDelete = 4
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
