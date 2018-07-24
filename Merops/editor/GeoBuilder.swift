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

    class func Camera(scene: SCNScene, position: SCNVector3 = SCNVector3(x: 0, y: 5, z: 30)) {
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.position = position
        scene.rootNode.addChildNode(cameraNode)
    }

    class func Light(scene: SCNScene, position: SCNVector3 = SCNVector3(x: 0, y: 100, z: 0)) {
        let lightNode = SCNNode()
        lightNode.name = "light"
        lightNode.light = SCNLight()
        lightNode.position = position
        scene.rootNode.addChildNode(lightNode)
    }
}

final class MyApplication {
    // 自動的に遅延初期化される(初回アクセスのタイミングでインスタンス生成)
    static let shared = MyApplication()

    // 外部からのインスタンス生成をコンパイルレベルで禁止
    private init() {
    }
}