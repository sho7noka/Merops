//
//  GameViewOverlay.swift
//  Merops
//
//  Created by sumioka-air on 2017/05/03.
//  Copyright © 2017年 sho sumioka. All rights reserved.
//

import SpriteKit
import SceneKit
import QuartzCore
import ImGui

extension SKScene {
    /*
     * sceneの中心の座標を返すメソッド
     */
    var midPoint: CGPoint {
        return CGPoint(x: self.frame.midX, y: self.frame.midY)
    }
    
    func mLabel(name : String) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = name
        label.name = name
        label.fontSize = 12
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .bottom
        return label
    }
    
    func mButton(name : Any) -> SKSpriteNode {
        let size = CGSize(width: 32, height: 32)
    #if os(OSX)
        let btn = SKSpriteNode(imageNamed: name as! String)
    #elseif os(iOS)
        let btn = SKSpriteNode(color: name as! Color, size: size)
    #endif
        btn.name = (name as! String)
        btn.size = size
        return btn
    }
}

@objcMembers
class GameViewOverlay: SKScene, SKSceneDelegate, SCNSceneRendererDelegate {

    /*
     -------------------------------------------------
     | name                                          |
     | transform                                   ◆ |
     | rotate          ___________                 ◆ |
     | scale          |           |                ◆ |
     | info           |           |                ◆ |
     |                |           |                ◆ |
     |                |           |                ◆ |
     |                 -----------                 ◆ |
     |                                               |
     |               status message              HUD |
     -------------------------------------------------
     */

    var label_name: SKLabelNode!
    var label_position: SKLabelNode!
    var label_rotate: SKLabelNode!
    var label_scale: SKLabelNode!
    var label_info: SKLabelNode!
    var label_message: SKLabelNode!

    var button_geom: SKSpriteNode!
    var button_deform: SKSpriteNode!
    var button_camera: SKSpriteNode!
    var button_material: SKSpriteNode!
    var button_python: SKSpriteNode!
    var button_settings: SKSpriteNode!
    var button_undo: SKSpriteNode!
    var button_redo: SKSpriteNode!

    init(view: GameView) {
        super.init(size: view.frame.size)
        self.anchorPoint = .init(x: 0.5, y: 0.5)
        self.scaleMode = .resizeFill

        // text
        label_name = mLabel(name: "Name")
        label_position = mLabel(name: "Position")
        label_rotate = mLabel(name: "Rotate")
        label_scale = mLabel(name: "Scale")
        label_info = mLabel(name: "Info")
        label_message = mLabel(name: "")
        
        // "/Applications/Visual Studio Code.app/Contents/Resources/Code.icns"
        button_geom = mButton(name: "geom")
        button_camera = mButton(name: "camera")
        button_deform = mButton(name: "deform")
        button_material = mButton(name: "material")
        button_python = mButton(name: "python")
        button_settings = mButton(name: "settings")
        button_undo = mButton(name: "undo")
        button_redo = mButton(name: "redo")

        var guis : [SKNode] = [label_name, label_position, label_rotate, label_scale, label_info, button_geom, button_camera, button_deform, label_message, button_material, button_python, button_settings]
        
        #if os(iOS)
        guis.append(button_undo)
        guis.append(button_redo)
        #endif
        
        DispatchQueue.main.async {
            guis.forEach {
                self.addChild(($0))
            }
        }
    }
    
    func info(msg: String) {
        label_message.fontColor = Color.green
        label_message.text = msg
    }
    
    func warn(msg: String) {
        label_message.fontColor = Color.yellow
        label_message.text = msg
    }
    
    func error(msg: String) {
        label_message.fontColor = Color.red
        label_message.text = msg
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/*
 * Mark: Manipulator
 */

internal class ManipulatorBase: SCNNode, SCNNodeRendererDelegate {

    // variable
    let axisLen = CGFloat(8.0)
    let offset = SCNFloat(8.0 / 2.0)
    let axisSide = CGFloat(0.2)
    let radius = CGFloat(0.2)
    let opaque = CGFloat(0.1)

    required override init() {
        super.init()
        super.isHidden = true
        super.renderingOrder = 1
        super.categoryBitMask = NodeOptions.noExport.rawValue | NodeOptions.noDelete.rawValue
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("miss")
    }
}

final class PositionNode: ManipulatorBase {

    public required init() {

        super.init()
        self.name = "pos"

        // Line
        let xLine = SCNBox(width: axisLen, height: axisSide, length: axisSide, chamferRadius: radius)
        let yLine = SCNBox(width: axisSide, height: axisLen, length: axisSide, chamferRadius: radius)
        let zLine = SCNBox(width: axisSide, height: axisSide, length: axisLen, chamferRadius: radius)

        // Cone
        let xBox = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 2)
        let yBox = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 2)
        let zBox = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 2)

        // color
        xLine.firstMaterial?.diffuse.contents = Color.red
        xBox.firstMaterial?.diffuse.contents = Color.red
        yLine.firstMaterial?.diffuse.contents = Color.green
        yBox.firstMaterial?.diffuse.contents = Color.green
        zLine.firstMaterial?.diffuse.contents = Color.blue
        zBox.firstMaterial?.diffuse.contents = Color.blue
        [xLine, xBox, yLine, yBox, zLine, zBox].forEach {
            $0.firstMaterial?.lightingModel = .constant
        }

        // Node
        let xLineNode = SCNNode(geometry: xLine)
        let yLineNode = SCNNode(geometry: yLine)
        let zLineNode = SCNNode(geometry: zLine)

        xLineNode.position.x = offset
        yLineNode.position.y = offset
        zLineNode.position.z = offset

        let xBoxNode = SCNNode(geometry: xBox)
        let yBoxNode = SCNNode(geometry: yBox)
        let zBoxNode = SCNNode(geometry: zBox)

        xBoxNode.position = SCNVector3Make(SCNFloat(xLine.width) / 2, 0, 0)
        yBoxNode.position = SCNVector3Make(0, SCNFloat(yLine.height) / 2, 0)
        zBoxNode.position = SCNVector3Make(0, 0, SCNFloat(zLine.length) / 2)

        xBoxNode.pivot = SCNMatrix4MakeRotation(SCNFloat(Double.pi / 2), 0, 0, 1)
        yBoxNode.pivot = SCNMatrix4MakeRotation(SCNFloat(Double.pi / 2), 0, 0, 0)
        zBoxNode.pivot = SCNMatrix4MakeRotation(SCNFloat(Double.pi / 2), -1, 0, 0)

        // control
        let control = SCNBox(width: axisLen, height: axisLen, length: axisLen, chamferRadius: 0)
        control.firstMaterial?.diffuse.contents = Color.gray
        let controlNode = SCNNode(geometry: control)
        controlNode.opacity = opaque
        controlNode.position = SCNVector3Make(
            SCNFloat(xLine.width) / 2, SCNFloat(axisLen / 2), SCNFloat(zLine.width / 2))

        // append
        xLineNode.addChildNode(xBoxNode)
        yLineNode.addChildNode(yBoxNode)
        zLineNode.addChildNode(zBoxNode)

        xLineNode.name = "pos.xmove"
        yLineNode.name = "pos.ymove"
        zLineNode.name = "pos.zmove"
        controlNode.name = "pos.amove"

        [controlNode, xLineNode, yLineNode, zLineNode, xBoxNode, yBoxNode, zBoxNode].forEach {
            if $0 == controlNode || $0 == xLineNode || $0 == yLineNode || $0 == zLineNode {
                self.addChildNode($0)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("miss")
    }
}

final class RotateNode: ManipulatorBase {

    public required init() {

        super.init()
        self.name = "rot"

        // Line
        let xCircle = SCNTube(innerRadius: 7.9, outerRadius: 8, height: 0.1)
        let yCircle = SCNTube(innerRadius: 7.9, outerRadius: 8, height: 0.1)
        let zCircle = SCNTube(innerRadius: 7.9, outerRadius: 8, height: 0.1)

        xCircle.firstMaterial?.diffuse.contents = Color.red
        yCircle.firstMaterial?.diffuse.contents = Color.green
        zCircle.firstMaterial?.diffuse.contents = Color.blue

        [xCircle, yCircle, zCircle].forEach {
            $0.radialSegmentCount = 192
            $0.firstMaterial?.lightingModel = .constant
        }

        // Node
        let xCircleNode = SCNNode(geometry: xCircle)
        let yCircleNode = SCNNode(geometry: yCircle)
        let zCircleNode = SCNNode(geometry: zCircle)

        let deg = 90 * (SCNFloat.pi / 180)
        xCircleNode.eulerAngles = SCNVector3(0, 0, deg)
        yCircleNode.eulerAngles = SCNVector3(0, 0, 0)
        zCircleNode.eulerAngles = SCNVector3(deg, 0, 0)

        // control
        let control = SCNSphere(radius: 8)
        control.firstMaterial?.diffuse.contents = Color.gray
        let controlNode = SCNNode(geometry: control)
        controlNode.opacity = opaque

        xCircleNode.name = "rot.xrotate"
        yCircleNode.name = "rot.yrotate"
        zCircleNode.name = "rot.zrotate"
        controlNode.name = "rot.arotate"

        // append
        [controlNode, xCircleNode, yCircleNode, zCircleNode].forEach {
            self.addChildNode($0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("miss")
    }
}

final class ScaleNode: ManipulatorBase {

    public required init() {

        super.init()
        self.name = "scl"

        // Line
        let xLine = SCNBox(width: axisLen, height: axisSide, length: axisSide, chamferRadius: radius)
        let yLine = SCNBox(width: axisSide, height: axisLen, length: axisSide, chamferRadius: radius)
        let zLine = SCNBox(width: axisSide, height: axisSide, length: axisLen, chamferRadius: radius)

        // Box
        let xBox = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let yBox = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let zBox = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)

        // color
        xLine.firstMaterial?.diffuse.contents = Color.red
        xBox.firstMaterial?.diffuse.contents = Color.red
        yLine.firstMaterial?.diffuse.contents = Color.green
        yBox.firstMaterial?.diffuse.contents = Color.green
        zLine.firstMaterial?.diffuse.contents = Color.blue
        zBox.firstMaterial?.diffuse.contents = Color.blue
        [xLine, xBox, yLine, yBox, zLine, zBox].forEach {
            $0.firstMaterial?.lightingModel = .constant
        }

        // Node
        let xLineNode = SCNNode(geometry: xLine)
        let yLineNode = SCNNode(geometry: yLine)
        let zLineNode = SCNNode(geometry: zLine)

        xLineNode.position.x = offset
        yLineNode.position.y = offset
        zLineNode.position.z = offset

        let xBoxNode = SCNNode(geometry: xBox)
        let yBoxNode = SCNNode(geometry: yBox)
        let zBoxNode = SCNNode(geometry: zBox)

        xBoxNode.position = SCNVector3Make(SCNFloat(xLine.width / 2), 0, 0)
        yBoxNode.position = SCNVector3Make(0, SCNFloat(yLine.height / 2), 0)
        zBoxNode.position = SCNVector3Make(0, 0, SCNFloat(zLine.length / 2))

        // control
        let control = SCNBox(width: axisLen, height: axisLen, length: axisLen, chamferRadius: 0)
        control.firstMaterial?.diffuse.contents = Color.gray
        let controlNode = SCNNode(geometry: control)
        controlNode.opacity = opaque
        controlNode.position = SCNVector3Make(
            SCNFloat(xLine.width / 2), SCNFloat(axisLen / 2), SCNFloat(zLine.width / 2))

        // append
        xLineNode.addChildNode(xBoxNode)
        yLineNode.addChildNode(yBoxNode)
        zLineNode.addChildNode(zBoxNode)

        xLineNode.name = "scl.xscale"
        yLineNode.name = "scl.yscale"
        zLineNode.name = "scl.zscale"
        controlNode.name = "scl.ascale"

        [controlNode, xLineNode, yLineNode, zLineNode].forEach {
            self.addChildNode($0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("miss")
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
