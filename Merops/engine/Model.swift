//
// Created by sumioka-air on 2018/05/02.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import Foundation
import SceneKit

struct Attribute {
    var name : String
    var index : Int
//    var attr : String { set get }
}

class Material {
//    var color: vector_float3?
    var shader: String?
}

class Model : NSObject {
    
    override init(){
        self.current = ""
        self.root = ""
    }
    
    var name: String = ""
    var current: Any
    var root: Any
    
//    var transform: vector_int3 = []
    private var models: [SCNNode] = []
    var file: String = "/Users/shosumioka/Merops/Merops/engine/merops.py"
    var geom: String?
    var material: Material?
    func create(name: String) {}
    func delete() {}
    func select() {}
    func hide() {}
    func lock() {}
    
    func imports() {}
    func exports() {}
    
    private func update(){
        
    }

    func _copy () -> Model {
        dump(self)
        models.removeAll()
//        var tmp: [SCNNode] = []
//        gameView.scene?.rootNode.enumerateChildNodes({ child, _ in
//            if child.geometry != nil && child.categoryBitMask != 2 {
//                tmp.append(child.clone())
//            }
//        })
//        models = tmp
        return self
    }

    func setModels() {
        models.removeAll()
//        _openStage(<#T##sPath: UnsafePointer<Int8>!##UnsafePointer<Int8>!#>)

//        var tmp: [SCNNode] = []
//        gameView.scene?.rootNode.enumerateChildNodes({ child, _ in
//            if child.geometry != nil && child.categoryBitMask != 2 {
//                tmp.append(child.clone())
//                child.removeFromParentNode()
//            }
//        })
//        models = tmp
    }

    func getModels() -> [Model] {
//        models.forEach {
//            gameView.scene?.rootNode.addChildNode($0)
//        }
        models.removeAll()
        return []
    }
}
