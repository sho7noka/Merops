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
