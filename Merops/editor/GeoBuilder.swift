//
// Created by sumioka-air on 2018/05/01.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import SceneKit

final class Builder {

    class func Plane(meshData: MetalMeshData) -> SCNNode {
        let newNode = SCNNode(geometry: meshData.geometry)
        newNode.name = "plane"
        newNode.geometry?.firstMaterial?.diffuse.contents = Color.blue
        newNode.castsShadow = true

        var trans = SCNMatrix4Identity
        trans = SCNMatrix4Rotate(trans, CGFloat(Float.pi / 2), 1, 0, 0)
        newNode.transform = trans

        return newNode
    }

    class func Cube(scene: SCNScene) {
        let cube = SCNBox()

        let cubeNode = SCNNode(geometry: cube)
        cubeNode.name = "cube"
        scene.rootNode.addChildNode(cubeNode)
    }

    class func Grid(scene: SCNScene) {
        let grid = SCNFloor()

        let gridNode = SCNNode(geometry: grid)
        gridNode.name = "grid"
        scene.rootNode.addChildNode(gridNode)
    }

    class func Cone(scene: SCNScene) {
        let cone = SCNCone()

        let coneNode = SCNNode(geometry: cone)
        coneNode.name = "cone"
        scene.rootNode.addChildNode(coneNode)
    }

    class func Torus(scene: SCNScene) {
        let torus = SCNTorus()

        let torusNode = SCNNode(geometry: torus)
        torusNode.name = "torus"
        scene.rootNode.addChildNode(torusNode)
    }

    class func Camera(scene: SCNScene, name: String = "camera", position: SCNVector3 = SCNVector3(x: 0, y: 5, z: 30)) {
        let camera = SCNCamera()
        camera.name = name
        camera.zNear = 1
        camera.zFar = 100000
        
        let cameraNode = SCNNode()
        cameraNode.name = name
        cameraNode.camera = camera
        cameraNode.position = position
        scene.rootNode.addChildNode(cameraNode)
    }

    class func Light(scene: SCNScene, name: String = "light", position: SCNVector3 = SCNVector3(x: 0, y: 100, z: 0)) {
        let light = SCNLight()
        light.type = .probe
        
        let lightNode = SCNNode()
        lightNode.name = name
        lightNode.light = light
        lightNode.position = position
        scene.rootNode.addChildNode(lightNode)
    }
    
    class func custumGeo(half: Float = 2) -> SCNNode {
        
        // https://qiita.com/takabosoft/items/13114d5da7180a9b2ab0
        
        // VBO 頂点を定義します。
        let vertices = [
            
            // 手前
            SCNVector3(-half, +half, +half), // 手前+左上 0
            SCNVector3(+half, +half, +half), // 手前+右上 1
            SCNVector3(-half, -half, +half), // 手前+左下 2
            SCNVector3(+half, -half, +half), // 手前+右下 3
            
            // 奥
            SCNVector3(-half, +half, -half), // 奥+左上 4
            SCNVector3(+half, +half, -half), // 奥+右上 5
            SCNVector3(-half, -half, -half), // 奥+左下 6
            SCNVector3(+half, -half, -half), // 奥+右下 7
            
            // 左側
            SCNVector3(-half, +half, -half), // 8 (=4)
            SCNVector3(-half, +half, +half), // 9 (=0)
            SCNVector3(-half, -half, -half), // 10 (=6)
            SCNVector3(-half, -half, +half), // 11 (=2)
            
            // 右側
            SCNVector3(+half, +half, +half), // 12 (=1)
            SCNVector3(+half, +half, -half), // 13 (=5)
            SCNVector3(+half, -half, +half), // 14 (=3)
            SCNVector3(+half, -half, -half), // 15 (=7)
            
            // 上側
            SCNVector3(-half, +half, -half), // 16 (=4)
            SCNVector3(+half, +half, -half), // 17 (=5)
            SCNVector3(-half, +half, +half), // 18 (=0)
            SCNVector3(+half, +half, +half), // 19 (=1)
            
            // 下側
            SCNVector3(-half, -half, +half), // 20 (=2)
            SCNVector3(+half, -half, +half), // 21 (=3)
            SCNVector3(-half, -half, -half), // 22 (=6)
            SCNVector3(+half, -half, -half), // 23 (=7)
        ]
        
        // 各頂点における法線ベクトルを定義
        let vectors = [
            SCNVector3(0, 0, 2), // 手前
            SCNVector3(0, 0, -1), // 奥
            SCNVector3(-1, 0, 0), // 左側
            SCNVector3(1, 0, 0), // 右側
            SCNVector3(0, 1, 0), // 上側
            SCNVector3(0, -1, 0), // 下側
        ]
        
        var normals: [SCNVector3] = []
        for vec in vectors {
            for _ in 1...4 {
                normals.append(vec)
            }
        }
        
        // IBO ポリゴンを定義します。
        let indices: [Int32] = [
            // 手前
            0, 2, 1,
            1, 2, 3,
            
            // 奥
            4, 5, 7,
            4, 7, 6,
            
            // 左側
            8, 10, 9,
            9, 10, 11,
            
            // 右側
            13, 12, 14,
            13, 14, 15,
            
            // 上側
            16, 18, 17,
            17, 18, 19,
            
            // 下側
            22, 23, 20,
            23, 21, 20,
            ]
        
        // マテリアル
        let material = SCNMaterial()
        //    material.lightingModel = .physicallyBased
        //    material.diffuse.contents = NSImage(named: NSImage.Name(rawValue: "texture"))
        //    material.metalness.contents = NSNumber(value: 0.5)
        material.diffuse.contents = Color.red
        
        // ジオメトリ
        let customGeometry = SCNGeometry(
            sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
        customGeometry.materials = [material]
        return SCNNode(geometry: customGeometry)
    }
}

final class Editor {
    
    class func removeSelNode(selection: SCNHitTestResult) {
        if selection.node.categoryBitMask != NodeOptions.noExport.rawValue {
            selection.node.removeFromParentNode()
        }
    }
    
    class func EditorDome(scene: SCNScene) {
        let sphere = SCNSphere()
        sphere.firstMaterial?.isDoubleSided = true
        
        let node = SCNNode(geometry: sphere)
        node.name = "Dome"
        node.scale = SCNVector3(100000, 100000, 100000)
        node.categoryBitMask = NodeOptions.noSelect.rawValue
        scene.rootNode.addChildNode(node)
    }
    
    class func EditorGrid(scene: SCNScene) {
        let grid = SCNFloor()
        grid.firstMaterial?.isDoubleSided = true
        grid.width = 100000
        grid.length = 100000
        
        let node = SCNNode(geometry: grid)
        node.name = "grid"
        node.categoryBitMask = NodeOptions.noSelect.rawValue
        scene.rootNode.addChildNode(node)
    }
}

final class MyApplication {
    // 自動的に遅延初期化される(初回アクセスのタイミングでインスタンス生成)
    static let shared = MyApplication()

    // 外部からのインスタンス生成をコンパイルレベルで禁止
    private init() {
    }
}
