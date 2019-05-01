//
// Created by sumioka-air on 2018/05/01.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import SceneKit
import Euclid

final class Builder {

    class func Plane(meshData: MetalMeshData) -> SCNNode {
        let newNode = SCNNode(geometry: meshData.geometry)
        newNode.name = "plane"
        newNode.geometry?.firstMaterial?.diffuse.contents = Color.blue
        newNode.castsShadow = true

        var trans = SCNMatrix4Identity
        trans = SCNMatrix4Rotate(trans, SCNFloat(Float.pi / 2), 1, 0, 0)
        newNode.transform = trans

        return newNode
    }

    class func Cube(scene: SCNScene) {
        let cube = SCNBox()

        let cubeNode = SCNNode(geometry: cube)
        cubeNode.name = "cube"
        scene.rootNode.addChildNode(cubeNode)
    }

    class func Grid(scene: SCNScene) -> SCNNode {
        let grid = SCNFloor()

        let gridNode = SCNNode(geometry: grid)
        gridNode.name = "grid"
        scene.rootNode.addChildNode(gridNode)
        return gridNode
    }

    class func Sphere(scene: SCNScene) -> SCNNode {
        let sphere = SCNSphere()

        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "sphere"
        scene.rootNode.addChildNode(sphereNode)
        return sphereNode
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
    
    class func openScript(model: Model, settings: Settings) {
        #if os(iOS)
        
        if model.file.endsWith(".py") {
            let pythonista = URL(string: "pythonista://\(model.file)")!
            UIApplication.shared.open(pythonista)
        } else {
            storeAndShare(withURLString: (model!.file ?? nil)!)
        }
        
        #elseif os(OSX)
        
        if (NSWorkspace.shared.fullPath(forApplication: settings.editor) != nil) {
            
            // https://code.visualstudio.com/docs/editor/command-line#_opening-vs-code-with-urls
            if (settings.editor.hasSuffix("Code")) {
                NSWorkspace.shared.open((URL(string: "vscode://file\(model.file)") ?? nil)!)
            }
            
            // https://github.com/macvim-dev/macvim/blob/e06ff0d83a1687e19679e9bddec2745e06a144ae/runtime/doc/gui_mac.txt
            if (settings.editor.hasSuffix("Vim")) {
                NSWorkspace.shared.open((URL(string: "mvim://open?url=file://\(model.file)") ?? nil)!)
            }
        }
        
        #endif
    }
    
    class func remove(selection: SCNHitTestResult?) {
        if selection?.node.categoryBitMask != NodeOptions.noExport.rawValue {
            selection?.node.removeFromParentNode()
        }
    }
    
//    https://github.com/warrenm/SCNOutline
//    https://github.com/warrenm/SCNShadableSky
    class func EditorDome(view: GameView) {
        let skyGeometry = SCNSphere(radius: 700)
        let skyTexture = SCNMaterialProperty(contents: Image(named: "sky") as Any)
        
        let skyProgram = SCNProgram()
        skyProgram.library = view.device!.makeDefaultLibrary()
        skyProgram.vertexFunctionName = "sky_vertex"
        skyProgram.fragmentFunctionName = "sky_fragment"
        
        let skyMaterial = skyGeometry.firstMaterial!
        skyMaterial.program = skyProgram
        skyMaterial.isDoubleSided = true
        skyMaterial.setValue(skyTexture, forKey: "timeOfDay")

        let node = SCNNode(geometry: skyGeometry)
        node.name = "sky"
        node.categoryBitMask = NodeOptions.noSelect.rawValue
        view.scene!.rootNode.addChildNode(node)
    }
    
    class func EditorGrid(view: GameView) {
        let grid = SCNFloor()
        grid.width = 100000
        grid.length = 100000
        
        let skyProgram = SCNProgram()
        skyProgram.library = view.device!.makeDefaultLibrary()
        skyProgram.vertexFunctionName = "grid_vertex"
        skyProgram.fragmentFunctionName = "grid_fragment"
        
        let gridMaterial = grid.firstMaterial!
        gridMaterial.program = skyProgram
        gridMaterial.isDoubleSided = true
        //        gridMaterial.setValue(skyTexture, forKey: "timeOfDay")
        
        let node = SCNNode(geometry: grid)
        node.name = "grid"
        node.categoryBitMask = NodeOptions.noSelect.rawValue
        view.scene!.rootNode.addChildNode(node)
        
        EditorDome(view: view)
    }
}

//extension NSImage {
//    convenience init(color: NSColor, size: NSSize) {
//        self.init(size: size)
//        lockFocus()
//        color.drawSwatch(in: NSRect(origin: .zero, size: size))
//        unlockFocus()
//    }
//}

class SCNReplicatorNode: SCNNode, SCNNodeRendererDelegate {
    
    init(geometry: SCNGeometry, positions: [SCNVector3], normals: [SCNVector3] = [], upVector: SCNVector3 = SCNVector3(0, 1, 0), localFrontVector: SCNVector3 = SCNVector3(0, 0, 1)) {
        super.init()
        
        let baseNode = SCNNode(geometry: geometry)
        
        for i in 0..<positions.count {
            // Position
            baseNode.position = positions[i]
            
            // Normals
            if !normals.isEmpty {
                let pos = SCNVector3(
                    positions[i].x + normals[i].x,
                    positions[i].y + normals[i].y,
                    positions[i].z + normals[i].z
                )
                
                
                baseNode.look(at: pos, up: upVector, localFront: localFrontVector)
            }
            
            self.addChildNode(baseNode.clone())
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Action
    func replicatorAction(_ action: SCNAction) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].removeAllActions()
            self.childNodes[i].runAction(action)
        }
    }
    
    func replicatorAction(_ action: SCNAction, delay: Double) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].removeAllActions()
            self.childNodes[i].runAction(
                SCNAction.sequence([
                    SCNAction.wait(duration: Double(i) * delay),
                    action
                    ])
            )
        }
    }
    
    // Pivot
    func geometryPivot(_ x: Float, _ y: Float, _ z: Float) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].pivot = SCNMatrix4MakeTranslation(SCNFloat(x), SCNFloat(y), SCNFloat(z))
        }
    }
    
    // Scale
    func geometryScale(_ x: Float, _ y: Float, _ z: Float) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].scale = SCNVector3(x, y, z)
        }
    }
}

class SCNPositionVectors {
    
    init() {
    }
    
    enum Pivot: Int {
        case center
        case left
        case right
    }
    
    // Line
    class func line(count: UInt, margin: Double = 1, position: Pivot = .center) -> [SCNVector3] {
        
        if count == 0 {
            return [SCNVector3Zero]
        }
        
        var pivot: Double = 0
        switch position {
        case .center:
            pivot = -(Double(count - 1) * margin / 2)
        case .left:
            pivot = 0
        case .right:
            pivot = -(Double(count - 1) * margin)
        }
        
        var position: [SCNVector3] = []
        for i in 0..<count {
            position.append(SCNVector3(Double(i) * margin + pivot, 0, 0))
        }
        
        return position
    }
    
    // Box
    class func box(widthCount: UInt, heightCount: UInt, lengthCount: UInt, margin: Double = 1) -> [SCNVector3] {
        
        if widthCount == 0 || lengthCount == 0 || heightCount == 0 {
            return [SCNVector3Zero]
        }
        
        var position: [SCNVector3] = []
        let pivotX = -(Double(widthCount - 1) * margin / 2)
        let pivotY = -(Double(heightCount - 1) * margin / 2)
        let pivotZ = -(Double(lengthCount - 1) * margin / 2)
        for x in 0..<widthCount {
            for y in 0..<heightCount {
                for z in 0..<lengthCount {
                    position.append(SCNVector3(
                        Double(x) * margin + pivotX,
                        Double(y) * margin + pivotY,
                        Double(z) * margin + pivotZ
                    ))
                }
            }
        }
        
        return position
    }
    
    // Circle
    class func circle(divide: UInt, radius: Double) -> [SCNVector3] {
        
        if divide == 0 {
            return [SCNVector3Zero]
        }
        
        var position: [SCNVector3] = []
        let divideCount = 2.0 * Double.pi / Double(divide)
        for r in 0..<divide {
            position.append(SCNVector3(
                cos(divideCount * Double(r)) * radius,
                0,
                sin(divideCount * Double(r)) * radius
            ))
        }
        
        return position
    }
}
