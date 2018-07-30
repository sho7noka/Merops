//
//  GameViewOverlay.swift
//  KARAS
//
//  Created by sumioka-air on 2017/05/03.
//  Copyright © 2017年 sho sumioka. All rights reserved.
//

import SpriteKit
import SceneKit
import QuartzCore

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
    
    func mButton(name : String) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 16.0, height: 16.0))
        btn.name = name
        return btn
    }
}

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

    var button_red: SKShapeNode!
    var button_blue: SKShapeNode!
    var button_green: SKShapeNode!
    var button_magenta: SKShapeNode!
    var button_cyan: SKShapeNode!
    var button_yellow: SKShapeNode!
    var button_black: SKShapeNode!

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

        // HUD
        button_red = mButton(name: "red")
        button_red.fillColor = Color.red
        button_green = mButton(name: "green")
        button_green.fillColor = Color.green
        button_blue = mButton(name: "blue")
        button_blue.fillColor = Color.blue
        button_magenta = mButton(name: "magenta")
        button_magenta.fillColor = Color.magenta
        button_cyan = mButton(name: "cyan")
        button_cyan.fillColor = Color.cyan
        button_yellow = mButton(name: "yellow")
        button_yellow.fillColor = Color.yellow
        button_black = mButton(name: "black")
        button_black.fillColor = Color.black
        
        let guis : [SKNode] = [label_name, label_position, label_rotate, label_scale, label_info, button_red, button_green, button_blue, label_message, button_magenta, button_cyan, button_yellow, button_black]
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
    let axisLen = SCNFloat(8.0)
    let offset = SCNFloat(8.0 / 2.0)
    let axisSide = SCNFloat(0.2)
    let radius = SCNFloat(0.2)
    let opaque = CGFloat(0.1)

    required override init() {
        super.init()
        super.isHidden = true
        super.renderingOrder = 1
        super.categoryBitMask = NodeOptions.noExport.rawValue | NodeOptions.noDelete.rawValue
    }
    
    func renderNode(_ node: SCNNode, renderer: SCNRenderer, arguments: [String: Any]) {
        if let commandQueue = renderer.commandQueue {
            if let encoder = renderer.currentRenderCommandEncoder {
                
//                let projMat = float4x4.init((self.sceneView.pointOfView?.camera?.projectionTransform)!)
//                let modelViewMat = float4x4.init((self.sceneView.pointOfView?.worldTransform)!).inverse
//                
//                self.metalScene.render(commandQueue: commandQueue,
//                                       renderEncoder: encoder,
//                                       parentModelViewMatrix: modelViewMat,
//                                       projectionMatrix: projMat)
                
            }
        }
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

        xBoxNode.position = SCNVector3Make(xLine.width / 2, 0, 0)
        yBoxNode.position = SCNVector3Make(0, yLine.height / 2, 0)
        zBoxNode.position = SCNVector3Make(0, 0, zLine.length / 2)

        xBoxNode.pivot = SCNMatrix4MakeRotation(SCNFloat(Double.pi / 2), 0, 0, 1)
        yBoxNode.pivot = SCNMatrix4MakeRotation(SCNFloat(Double.pi / 2), 0, 0, 0)
        zBoxNode.pivot = SCNMatrix4MakeRotation(SCNFloat(Double.pi / 2), -1, 0, 0)

        // control
        let control = SCNBox(width: axisLen, height: axisLen, length: axisLen, chamferRadius: 0)
        control.firstMaterial?.diffuse.contents = Color.gray
        let controlNode = SCNNode(geometry: control)
        controlNode.opacity = opaque
        controlNode.position = SCNVector3Make(xLine.width / 2, axisLen / 2, zLine.width / 2)

        // append
        xLineNode.addChildNode(xBoxNode)
        yLineNode.addChildNode(yBoxNode)
        zLineNode.addChildNode(zBoxNode)

        xLineNode.name = "xmove"
        yLineNode.name = "ymove"
        zLineNode.name = "zmove"
        controlNode.name = "amove"

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

        xCircleNode.name = "xrotate"
        yCircleNode.name = "yrotate"
        zCircleNode.name = "zrotate"
        controlNode.name = "arotate"

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

        xBoxNode.position = SCNVector3Make(xLine.width / 2, 0, 0)
        yBoxNode.position = SCNVector3Make(0, yLine.height / 2, 0)
        zBoxNode.position = SCNVector3Make(0, 0, zLine.length / 2)

        // control
        let control = SCNBox(width: axisLen, height: axisLen, length: axisLen, chamferRadius: 0)
        control.firstMaterial?.diffuse.contents = Color.gray
        let controlNode = SCNNode(geometry: control)
        controlNode.opacity = opaque
        controlNode.position = SCNVector3Make(xLine.width / 2, axisLen / 2, zLine.width / 2)

        // append
        xLineNode.addChildNode(xBoxNode)
        yLineNode.addChildNode(yBoxNode)
        zLineNode.addChildNode(zBoxNode)

        xLineNode.name = "xscale"
        yLineNode.name = "yscale"
        zLineNode.name = "zscale"
        controlNode.name = "ascale"

        [controlNode, xLineNode, yLineNode, zLineNode].forEach {
            self.addChildNode($0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("miss")
    }
}
