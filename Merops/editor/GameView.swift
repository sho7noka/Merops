//
//  GameView.swift
//  Merops
//
//  Created by sumioka-air on 2017/04/30.
//  Copyright (c) 2017年 sho sumioka. All rights reserved.
//

import SpriteKit
import SceneKit
import ImGui

class GameView: SCNView {
    
    /// Mark: Mouse hit point
    let options = [
        SCNHitTestOption.sortResults: NSNumber(value: true),
        SCNHitTestOption.boundingBoxOnly: NSNumber(value: true),
        SCNHitTestOption.categoryBitMask: NSNumber(value: true),
    ]
    
    private func update() {
        let bufferPointer = mouseBuffer.contents()
        memcpy(bufferPointer, &pos, MemoryLayout<float2>.size)
    }
    
    var pos = float2()
    var mouseBuffer: MTLBuffer!
    var outBuffer: MTLBuffer!
    var queue: MTLCommandQueue! = nil
    var cps: MTLComputePipelineState! = nil
    
    override func draw(_ dirtyRect: CGRect) {
        if let drawable = metalLayer.nextDrawable() {
            guard let commandBuffer = queue.makeCommandBuffer() else { return }
            commandBuffer.pushDebugGroup("Mouse Buffer")
            
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            commandEncoder?.setComputePipelineState(cps)
            commandEncoder?.setBuffer(mouseBuffer, offset: 0, index: 1)
            commandEncoder?.setBuffer(outBuffer, offset: 0, index: 2)
            
            update()
            
            let threadGroupCount = MTLSizeMake(1, 1, 1)
            let threadGroups = MTLSizeMake(
                drawable.texture.width / threadGroupCount.width,
                drawable.texture.height / threadGroupCount.height, 1
            )
            commandEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder?.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            commandBuffer.popDebugGroup()
        }
    }
    
    /*
     * MARK: Attributes
     */
    
    var model: Model?
    
    var val = 0.0 {
        didSet {
            self.pointOfView?.position.z = CGFloat(Float(val))
        }
    }
    
    var isEdit = false {
        didSet {
            if isEdit {
                let asset = USDExporter.exportFromAsset(scene: self.scene!)
                self.scene = SCNScene(mdlAsset: asset)
                isEdit = false
            }
        }
    }
    
    var isDeforming = true {
        didSet {
            self.gestureRecognizers.forEach {
                $0.isEnabled = !isDeforming
            }
            self.allowsCameraControl = !isDeforming
        }
    }
    
    var cameraName = "camera" {
        didSet {
            self.pointOfView = self.node(name: cameraName)
            self.overLay?.label_message.text = cameraName + " / " + mode.toString
        }
    }
    
    var mode = EditContext.PositionMode {
        didSet {
            self.overLay?.label_message.text = cameraName + " / " + mode.toString
            self.overLay?.label_message.fontColor = Color.white
            
            gizmos.forEach {
                root?.addChildNode($0)
                if let selNode = selection?.node {
                    $0.position = selNode.position
                }
                $0.isHidden = true
            }
            
            switch mode {
            case .PositionMode:
                node(name: "pos")?.isHidden = false
                gizmos.forEach {
                    if $0.name != "pos" {
                        $0.removeFromParentNode()
                    }
                }
            case .ScaleMode:
                node(name: "scl")?.isHidden = false
                gizmos.forEach {
                    if $0.name != "scl" {
                        $0.removeFromParentNode()
                    }
                }
            case .RotateMode:
                node(name: "rot")?.isHidden = false
                gizmos.forEach {
                    if $0.name != "rot" {
                        $0.removeFromParentNode()
                    }
                }
            default:
                gizmos.forEach {
                    $0.removeFromParentNode()
                }
            }
        }
    }
    
    var part = DrawOverride.Object {
        didSet {
            if let selNode = selection?.node {
                let outlineNode = duplicate(selNode)
                root?.addChildNode(outlineNode)
                
                switch part {
                case .OverrideVertex:
                    let outlineProgram = SCNProgram()
                    outlineProgram.vertexFunctionName = "point_vertex"
                    outlineProgram.fragmentFunctionName = "point_fragment"
                    outlineNode.geometry?.firstMaterial?.program = outlineProgram
                    outlineNode.geometry?.firstMaterial?.cullMode = .front
                //  prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.point, vertex: [])
                    
                case .OverrideEdge:
                    let outlineProgram = SCNProgram()
                    outlineProgram.vertexFunctionName = "outline_vertex"
                    outlineProgram.fragmentFunctionName = "outline_fragment"
                    outlineNode.geometry?.firstMaterial?.program = outlineProgram
                    outlineNode.geometry?.firstMaterial?.cullMode = .front
                //  prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.line, vertex: [])
                    
                case .OverrideFace:
                    let outlineProgram = SCNProgram()
                    outlineProgram.vertexFunctionName = "face_vertex"
                    outlineProgram.fragmentFunctionName = "face_fragment"
                    outlineNode.geometry?.firstMaterial?.program = outlineProgram
                    outlineNode.geometry?.firstMaterial?.cullMode = .front
                //  prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.triangleStrip, vertex: [])
                    
                default:
                    outlineNode.removeFromParentNode()
                    prim = nil
                }
            }
        }
    }

    var selectedNode: SCNNode? = nil {
        didSet {
            if (selectedNode != nil) {
//                // Label
//                overLay?.label_name.text = "Name: \(String(describing: selectedNode!.name!))"
//                overLay?.label_position.text = "Position: \(String(describing: selectedNode!.position.xyz))"
//                overLay?.label_rotate.text = "Rotate: \(String(describing: selectedNode!.eulerAngles.xyz))"
//                overLay?.label_scale.text = "Scale: \(selectedNode!.scale.xyz)"
//
//                // Material
//                selectedNode!.geometry!.firstMaterial!.emission.contents = (
//                    (selectedNode!.geometry != nil) ? Color.red : Color.yellow
//                )

            } else {
                // Label
                overLay?.label_name.text = "Name"
                overLay?.label_position.text = "Position"
                overLay?.label_rotate.text = "Rotate"
                overLay?.label_scale.text = "Scale"
                
                // Material
                self.root?.enumerateChildNodes({ child, _ in
                    if let geo = child.geometry {
                        geo.firstMaterial?.emission.contents = Color.black
                    }
                })
                clearView()
            }
        }
    }
    var selection: SCNHitTestResult? = nil
    var p = CGPoint()
    var zDepth: SCNFloat!
    
    var prim: MetalPrimitiveData?
    var marken: SCNNode? = nil
    var hit_old = SCNVector3Zero
    var deformData: DeformData? = nil
    
    private func cameraZaxis(_ view: SCNView) -> SCNVector3 {
        let cameraMat = view.pointOfView!.transform
        return SCNVector3Make(cameraMat.m31, cameraMat.m32, cameraMat.m33) * -1
    }
    
    /*
     * MARK: Mouse Event
     */
    
    func ctouchesBegan(touchLocation: CGPoint, previousLocation: CGPoint, event: Event) {
        
        /// MARK: point
        p = self.convert(touchLocation, from: nil)
        let _p = overLay?.convertPoint(fromView: touchLocation)
        
        // MARK: overLay
        if let first = overLay?.nodes(at: _p!).first {
            resizeView()
            
            switch first.name {
                
            case "NSMultipleDocuments"?:
                selectedNode = Builder.Cone(scene: self.scene!)
                
            case "NSColorPanel"?:
                selectedNode = Builder.Grid(scene: self.scene!)
                
            case "NSComputer"?:
                cameraName = "camera"
                
            case "NSInfo"?:
                openScript()
        
            case "NSNetwork"?:
                cameraName = "camera1"
                
            case "NSAdvanced"?:
                setsView?.isHidden = false

            case "NSFolder"?:
                break
                
            case "Info":
                break
                
            case "Name":
                clearView()
                
                if selectedNode != nil {
                #if os(OSX)
                    txtField.stringValue = selectedNode!.name!
                #elseif os(iOS)
                    txtField.text = selectedNode.name!
                #endif
                    txtField.isHidden = false
                    txtField.frame.origin = CGPoint(x: 56, y: first.position.y * 2 + 16)
                    overLay?.label_name.text = "Name"
                }
                
            case "Position":
                clearView()
                
                if selectedNode != nil {
                    for (i, item) in numFields.enumerated() {
                        item.text = String(describing: { () -> SCNFloat in
                            if i == 0 {
                                return selectedNode!.position.x
                            } else if i == 1 {
                                return selectedNode!.position.y
                            }
                            return selectedNode!.position.z
                        }())
                        item.placeholder = { () -> String in
                            if i == 0 {
                                return "positionX"
                            } else if i == 1 {
                                return "positionY"
                            }
                            return "positionZ"
                        }()
                        item.isHidden = false
                        item.frame.origin = CGPoint(x: CGFloat(64 + 32 * i), y: first.position.y * 2 + 36)
                        overLay?.label_position.text = "Position"
                    }
                }
                
            case "Rotate":
                clearView()
                
                if selectedNode != nil {
                    for (i, item) in numFields.enumerated() {
                        item.text = String(describing: { () -> SCNFloat in
                            if i == 0 {
                                return selectedNode!.eulerAngles.x
                            } else if i == 1 {
                                return selectedNode!.eulerAngles.y
                            }
                            return selectedNode!.eulerAngles.z
                        }())
                        item.placeholder = { () -> String in
                            if i == 0 {
                                return "rotationX"
                            } else if i == 1 {
                                return "rotationY"
                            }
                            return "rotationZ"
                        }()
                        item.isHidden = false
                        item.frame.origin = CGPoint(x: CGFloat(64 + 32 * i), y: first.position.y * 2 + 56)
                        overLay?.label_rotate.text = "Rotate"
                    }
                }
                
            case "Scale":
                clearView()
                
                if selectedNode != nil {
                    for (i, item) in numFields.enumerated() {
                        item.text = String(describing: { () -> SCNFloat in
                            if i == 0 {
                                return selectedNode!.scale.x
                            } else if i == 1 {
                                return selectedNode!.scale.y
                            }
                            return selectedNode!.scale.z
                        }())
                        item.placeholder = { () -> String in
                            if i == 0 {
                                return "scaleX"
                            } else if i == 1 {
                                return "scaleY"
                            }
                            return "scaleZ"
                        }()
                        item.isHidden = false
                        item.frame.origin = CGPoint(x: CGFloat(64 + 32 * i), y: first.position.y * 2 + 76)
                        overLay?.label_scale.text = "Scale"
                    }
                }
                
            default:
                break

            }
            return
        }
        
        // point to MTLBuffer
        let hitResults = self.hitTest(p, options: options)
        //        let position = self.convertToLayer(p)
        //        let scale = self.layer?.contentsScale
        //        pos.x = (position.x) * scale
        //        pos.y = (bounds.height - position.y) * scale
        if let hit = hitResults.first {
            selectedNode = hit.node
            zDepth = self.projectPoint(selectedNode!.position).z
        }
        
        // MARK: SCNNode
        if hitResults.count > 0 {
            clearView()
            
            let result: AnyObject = hitResults[0]
            if result is SCNHitTestResult {
                selection = result as? SCNHitTestResult
            }
            guard let selectedNode = selection?.node else {
                return
            }
            
            // Show Gizmo
            gizmos.forEach {
                root?.addChildNode($0)
                $0.position = selectedNode.position
                $0.isHidden = true
            }
            switch mode {
            case .PositionMode:
                node(name: "pos")?.isHidden = false
                
            case .ScaleMode:
                node(name: "scl")?.isHidden = false
                
            case .RotateMode:
                node(name: "rot")?.isHidden = false
                
            default:
                break
            }
            
        } else {
            // Hide Gizmo
            gizmos.forEach {
                $0.removeFromParentNode()
            }
            selectedNode = nil
        }
        
        #if os(OSX)
        super.mouseDown(with: event)
        #endif
    }
    
    func ctouchesMoved(touchLocation: CGPoint, previousLocation: CGPoint, event: Event) {
        let mouse = self.convert(touchLocation, from: self)
        var hitTests = self.hitTest(mouse, options: nil)
        let result = hitTests[0]
        
        if isDeforming && mode == .Object {
            let loc = result.localCoordinates
            //            let globalDir = self.cameraZaxis(self) * -1
            //            let localDir = result.node.convertPosition(globalDir, from: nil)
            deformData = DeformData(location: float3(loc), direction: float3(loc),
                                    radiusSquared: 16.0, deformationAmplitude: 1.5, pad1: 0, pad2: 0
            ); return
        }
        
        /*
         guard selectedNode != nil else { return }
         let touch = touches.first!
         let touchPoint = touch.location(in: self)
         selectedNode.position = self.unprojectPoint(
         SCNVector3(x: Float(touchPoint.x),
         y: Float(touchPoint.y),
         z: zDepth))
         */
        
        if selection != nil {
            var unPoint = self.unprojectPoint(SCNVector3(x: SCNFloat(mouse.x), y: SCNFloat(mouse.y), z: 0.0))
            let p1 = selection!.node.parent!.convertPosition(unPoint, from: nil)
            unPoint = self.unprojectPoint(SCNVector3(x: SCNFloat(mouse.x), y: SCNFloat(mouse.y), z: 1.0))
            let p2 = selection!.node.parent!.convertPosition(unPoint, from: nil)
            
            let m = p2 - p1, e = selection!.localCoordinates, n = selection!.localNormal
            let t = ((e * n) - (p1 * n)) / (m * n)
            let hit = SCNVector3(
                x: (t * m.x).x + p1.x,
                y: (t * m.y).y + p1.y,
                z: (t * m.z).z + p1.z
            )
            
            var offset = (hit - hit_old) * 100
            hit_old = hit
            
            if marken != nil {
                switch mode {
                    
                case .PositionMode:
                    switch selection?.node.name {
                    case "pos.xmove":
                        node(name: "pos.ymove")?.isHidden = true
                        node(name: "pos.zmove")?.isHidden = true
                        offset = SCNVector3(offset.x, 0, 0)
                    case "pos.ymove":
                        node(name: "pos.xmove")?.isHidden = true
                        node(name: "pos.zmove")?.isHidden = true
                        offset = SCNVector3(0, offset.y, 0)
                    case "pos.zmove":
                        node(name: "pos.xmove")?.isHidden = true
                        node(name: "pos.ymove")?.isHidden = true
                        offset = SCNVector3(0, 0, offset.z)
                    default:
                        node(name: "pos")?.isHidden = true
                    }
                    marken!.position = marken!.position + offset
                    overLay?.label_position.text = (
                        "Position: \(String(describing: marken!.position.xyz))"
                    )
                    
                case .RotateMode:
                    switch selection?.node.name {
                    case "rot.xrotate":
                        node(name: "rot.yrotate")?.isHidden = true
                        node(name: "rot.zrotate")?.isHidden = true
                        offset = SCNVector3(offset.x, 0, 0)
                    case "rot.yrotate":
                        node(name: "rot.xrotate")?.isHidden = true
                        node(name: "rot.zrotate")?.isHidden = true
                        offset = SCNVector3(0, offset.y, 0)
                    case "rot.zrotate":
                        node(name: "rot.xrotate")?.isHidden = true
                        node(name: "rot.yrotate")?.isHidden = true
                        offset = SCNVector3(0, 0, offset.z)
                    default:
                        node(name: "rot")?.isHidden = true
                    }
                    
                    marken!.eulerAngles = marken!.eulerAngles + offset
                    overLay?.label_rotate.text = (
                        "Rotate: \(String(describing: marken!.eulerAngles.xyz))"
                    )
                    
                case .ScaleMode:
                    switch selection?.node.name {
                    case "scl.xscale":
                        node(name: "scl.yscale")?.isHidden = true
                        node(name: "scl.zscale")?.isHidden = true
                        offset = SCNVector3(offset.x, 0, 0)
                    case "scl.yscale":
                        node(name: "scl.xscale")?.isHidden = true
                        node(name: "scl.zscale")?.isHidden = true
                        offset = SCNVector3(0, offset.y, 0)
                    case "scl.zscale":
                        node(name: "scl.xscale")?.isHidden = true
                        node(name: "scl.zscale")?.isHidden = true
                        offset = SCNVector3(0, 0, offset.z)
                    default:
                        node(name: "scl")?.isHidden = true
                    }
                    
                    marken!.scale = marken!.scale + offset
                    overLay?.label_scale.text = (
                        "Scale: \(String(describing: marken!.scale.xyz))"
                    )
                    
                default:
                    break
                }
                
                gizmos.forEach {
                    $0.position = marken!.position + offset
                }
                
            } else {
                /// MARK: clone node
                marken = selection!.node.clone()
                marken!.opacity = 0.333
                
                let invertFilter = CIFilter(name: "CIColorInvert")
                invertFilter?.name = "invert"
                let pixellateFilter = CIFilter(name:"CIPixellate")
                pixellateFilter?.name = "pixellate"
                marken!.filters = [ pixellateFilter, invertFilter ] as? [CIFilter]
                
                switch mode {
                    
                case .PositionMode:
                    marken!.position = selection!.node.position
                    overLay?.label_position.text = (
                        "Position: \(String(describing: selection!.node.position.xyz))"
                    )
                    
                case .RotateMode:
                    marken!.rotation = selection!.node.rotation
                    overLay?.label_rotate.text = (
                        "Rotate: \(String(describing: selection!.node.eulerAngles.xyz))"
                    )
                    
                case .ScaleMode:
                    marken!.scale = selection!.node.scale
                    overLay?.label_scale.text = (
                        "Scale: \(String(describing: selection!.node.scale.xyz))"
                    )
                    
                default:
                    break
                }
                
                // sync
                gizmos.forEach {
                    $0.position = selection!.node.position
                }
                selection!.node.parent!.addChildNode(marken!)
            }
            
        } else {
            #if os(OSX)
            super.mouseDragged(with: event)
            #endif
        }
    }
    
    func ctouchesEnded(touchLocation: CGPoint, previousLocation: CGPoint, event: Event) {
        if selection != nil && marken != nil {
            
            #if os(OSX)
            if event.modifierFlags == Event.ModifierFlags.control {
                marken!.opacity = 1.0
                marken!.filters = nil
            }
            #endif
                
            switch mode {
                
            case .PositionMode:
                node(name: "pos")?.isHidden = false
                node(name: "pos.xmove")?.isHidden = false
                node(name: "pos.ymove")?.isHidden = false
                node(name: "pos.zmove")?.isHidden = false
                selection!.node.position = selection!.node.convertPosition(
                    marken!.position, from: selection!.node
                )
                overLay?.label_position.text = (
                    "Position: \(String(describing: selection!.node.position.xyz))"
                )
            case .RotateMode:
                node(name: "rot")?.isHidden = false
                node(name: "rot.xrotate")?.isHidden = false
                node(name: "rot.yrotate")?.isHidden = false
                node(name: "rot.zrotate")?.isHidden = false
                selection!.node.eulerAngles = selection!.node.convertVector(
                    marken!.eulerAngles, from: selection!.node
                )
                overLay?.label_rotate.text = (
                    "Rotate: \(String(describing: selection!.node.eulerAngles.xyz))"
                )
            case .ScaleMode:
                node(name: "scl")?.isHidden = false
                node(name: "scl.xscale")?.isHidden = false
                node(name: "scl.yscale")?.isHidden = false
                node(name: "scl.zscale")?.isHidden = false
                selection!.node.position = selection!.node.convertVector(
                    marken!.scale, from: selection!.node
                )
                overLay?.label_scale.text = (
                    "Scale: \(String(describing: selection!.node.position.xyz))"
                )
                
            default:
                break
            }
            
            gizmos.forEach {
                $0.position = selection!.node.convertPosition(
                    marken!.position, from: selection!.node
                )
            }
            marken!.removeFromParentNode()
        }
        
        // set nil
        p = self.convert(touchLocation, from: nil)
        let hitResults = self.hitTest(p, options: options)
        if (hitResults.count < 0) {
            selection = nil
        }
        marken = nil
        
        // Update
        isDeforming = false
        p = self.convert(touchLocation, to: nil)
        self.draw(CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        setNeedsDisplay()
        
        #if os(OSX)
        super.mouseUp(with: event)
        #endif
    }
    
    /*
     * MARK: Resize Event
     */
    
    func resizeView() {
        let size = self.frame.size
        
        #if os(OSX)
        subView?.frame.origin = CGPoint(x: size.width - 88 , y: 16)
        #elseif os(iOS)
        subView?.frame.origin = CGPoint(x: size.width - 88 , y: size.height - 80)
        /// TODO: ノッチ幅を下げる
        #endif
        overLay?.label_name.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 1))
        overLay?.label_position.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 2))
        overLay?.label_rotate.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 3))
        overLay?.label_scale.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 4))
        overLay?.label_info.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 5))
        
        overLay?.button_red.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 300)
        overLay?.button_green.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 268)
        overLay?.button_blue.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 236)
        overLay?.button_magenta.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 212)
        overLay?.button_cyan.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 184)
        overLay?.button_yellow.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 156)
        overLay?.button_black.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 120)
        
        overLay?.label_message.position = CGPoint(x: 0 - round(size.width / 14), y: -size.height / 2 + 20)
    }
    
    func clearView() {
        isDeforming = false
        
        if txtField != nil {
            txtField.isHidden = true
        }
        
        numFields.forEach {
            $0.isHidden = true
        }
        
        gizmos.forEach {
            $0.removeFromParentNode()
        }
    }
    
    func resetView() {
        
        // track gizmo position
        gizmos.forEach {
            root?.addChildNode($0)
            if let selNode = selection?.node {
                $0.position = selNode.position
            }
            $0.isHidden = true
        }

        // reset color
        root?.enumerateChildNodes({ child, _ in
            if let geo = child.geometry {
                geo.firstMaterial?.emission.contents = Color.black
            }
        })
    }
    
    func ckeyDown(key: String) {
        switch key {
            
        case "\u{1B}": //ESC
            clearView()
        case "\t": // TAB
            break
            
        case "o":
            self.openScript()
        case "\u{7F}": //del
            Editor.removeSelNode(selection: self.selection!)
            selectedNode = nil
        case "\r": //Enter
            break
            
        case "q":
            mode = .Object
        case "w":
            mode = .PositionMode
        case "e":
            mode = .ScaleMode
        case "r":
            mode = .RotateMode
        case "a":
            mode = .Object
        case "s":
            part = .OverrideVertex
        case "d":
            part = .OverrideEdge
        case "f":
            part = .OverrideFace
        case "z":
            gitRevert(url: (self.settings?.projectDir)!)
        case "x":
            gitCommit(url: (self.settings?.projectDir)!)
        case "c":
            break
        case "v":
            break
        default:
            break
        }
        
        self.draw(CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        setNeedsDisplay()
    }
    
#if os(iOS)
    
    let documentInteractionController = UIDocumentInteractionController()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: Event?) {
        for touch: UITouch in touches {
            if touch.type == .pencil {
                touch.altitudeAngle
                touch.azimuthAngle(in: self)
                touch.force
            }
            let location = touch.location(in: self)
            let previousLocation = location
            ctouchesBegan(touchLocation: location, previousLocation: previousLocation, event: event!)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: Event?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            let previousLocation = location
            ctouchesMoved(touchLocation: location, previousLocation: previousLocation, event: event!)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: Event?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            let previousLocation = location
            ctouchesEnded(touchLocation: location, previousLocation: previousLocation, event: event!)
        }
    }
    
#elseif os(OSX)

    override func viewWillStartLiveResize() {
        clearView()
        resizeView()
    }
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        resizeView()
    }
    
    override func viewDidEndLiveResize() {
        resizeView()
    }
    
    override func keyDown(with event: Event) {
        ckeyDown(key: event.characters!)
    }
    
    override func mouseDown(with event: Event) {
        let location = event.locationInWindow
        let previousLocation = location
        ctouchesBegan(touchLocation: location, previousLocation: previousLocation, event: event)
    }
    
    override func mouseMoved(with event: Event) {
        let location = event.locationInWindow
        let previousLocation = location
        ctouchesMoved(touchLocation: location, previousLocation: previousLocation, event: event)
    }
    
    override func mouseDragged(with event: Event) {
        let location = event.locationInWindow
        let previousLocation = location
        ctouchesMoved(touchLocation: location, previousLocation: previousLocation, event: event)
    }
    
    override func mouseUp(with event: Event) {
        let location = event.locationInWindow
        let previousLocation = location
        ctouchesEnded(touchLocation: location, previousLocation: previousLocation, event: event)
    }
    
    var setsView: SettingDialog!
    
#endif
    
    var settings: Settings?
    var subView: SCNView?
    var txtField: TextView!
    var gizmos: [ManipulatorBase] = []
    var numFields: [TextView] = []
    
    func showProperty() {
//        ImGui.draw { (imgui) in
//            imgui.pushStyleVar(.windowRounding, value: 0)
//            imgui.pushStyleColor(.frameBg, color: Color.blue)
//
//            let f = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
//            f[0] = true
//            imgui.begin("Attributes", show: f, flags: .alwaysAutoResize)
//
//            // style
//            imgui.setWindowFontScale(2.0)
//            imgui.setNextWindowPos(CGPoint.zero, cond: .always)
//            imgui.setNextWindowSize(self.frame.size)
//
//            // items
//            imgui.beginGroup()
//            imgui.sliderFloat("index", v: &self.val, minV: 0.0, maxV: 10.0)
//            imgui.colorEdit("backgroundColor", color: &(self.backgroundColor))
//
//            if imgui.button("Edit") {
//                dump(imgui)
//            }
//            if imgui.button("Script") {
//                self.openScript()
//            }
//            imgui.endGroup()
//
//
//            imgui.end()
//            imgui.popStyleColor()
//            imgui.popStyleVar()
//        }
    }
    
    func openScript() {
        #if os(iOS)
        
        let pythonista = URL(string: "pythonista://\(model?.file)")!
        UIApplication.shared.open(pythonista)
//        storeAndShare(withURLString: (self.model!.file ?? nil)!)
        
        #elseif os(OSX)
        
        if (NSWorkspace.shared.fullPath(forApplication: self.settings!.editor) != nil) {
            let config = GTConfiguration.default()
            
            if ((self.settings?.editor.hasSuffix("Code"))!) {
                config?.setString("vim", forKey: "core.editor")
                config?.setString("vimdiff", forKey: "merge.tool")
                NSWorkspace.shared.open((URL(string: "mvim://open?url=\(model!.file)") ?? nil)!)
            }
            
            // https://code.visualstudio.com/docs/editor/command-line#_opening-vs-code-with-urls
            if ((self.settings?.editor.hasSuffix("Vim"))!) {
                config?.setString("code --wait", forKey: "core.editor")
                config?.setString("code --wait --diff $LOCAL $REMOTE", forKey: "merge.tool")
                NSWorkspace.shared.open((URL(string: "vscode://\(model!.file)") ?? nil)!)
            }
        }
        
        #endif
    }

}

extension GameView {
    
    // root
    internal var root: SCNNode? {
        return self.scene?.rootNode
    }
    
    // node
    internal func node(name: String) -> SCNNode? {
        return self.scene!.rootNode.childNode(withName: name, recursively: true)
    }
    
    // iOS/macOS 両方で扱える
    internal var metalLayer: CAMetalLayer {
        let metalLayer = (self.layer as? CAMetalLayer)!
        metalLayer.framebufferOnly = false
        return metalLayer
    }
    
    // event
    internal var overLay: GameViewOverlay? {
        return (overlaySKScene as? GameViewOverlay)
    }

#if os(OSX)
    
    func keybind(modify: Event.ModifierFlags, k: String, e: Event) -> Bool {
        return (e.characters! == k &&
            e.modifierFlags.intersection(Event.ModifierFlags.deviceIndependentFlagsMask) == modify
        )
    }
    
    func setNeedsDisplay() {
        self.needsDisplay = true
    }

#elseif os(iOS)
    
    var gestureRecognizers: [UIGestureRecognizer] {
        return self.gestureRecognizers
    }
    
    func convertToLayer(_ p: CGPoint) -> CGPoint {
        return CGPoint(x: 0, y: 0)
    }
    
#endif

}
