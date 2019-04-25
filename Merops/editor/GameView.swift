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
            //            self.allowsCameraControl = !isDeforming
        }
    }
    
    var cameraName = "camera" {
        didSet {
            self.pointOfView = self.node(name: cameraName)
            self.overRay?.label_message.text = cameraName + " / " + mode.toString
        }
    }
    
    var mode = EditContext.PositionMode {
        didSet {
            self.overRay?.label_message.text = cameraName + " / " + mode.toString
            self.overRay?.label_message.fontColor = Color.white
            
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
                let outlineNode = duplicateNode(selNode)
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
    
    var p = CGPoint()
    var selection: SCNHitTestResult? = nil
    var selectedNode: SCNNode!
    var zDepth: SCNFloat!
    
    var prim: MetalPrimitiveData?
    var marken: SCNNode? = nil
    var hit_old = SCNVector3Zero
    var deformData: DeformData? = nil
    
    /*
     * MARK: Mouse Event
     */
    
    func ctouchesBegan(touchLocation: CGPoint, previousLocation: CGPoint, event: Event) {
        p = self.convert(touchLocation, from: nil)
        
        // point to MTLBuffer
        let hitResults = self.hitTest(p, options: options)
//        let position = self.convertToLayer(p)
//        let scale = self.layer?.contentsScale
//        pos.x = (position.x) * scale
//        pos.y = (bounds.height - position.y) * scale
        
        if let hit = hitResults.first {
            selectedNode = hit.node
            zDepth = self.projectPoint(selectedNode.position).z
        }
        let queue = OperationQueue()
        
        // MARK: overray
        let _p = overRay?.convertPoint(fromView: touchLocation)
        if let first = overRay?.nodes(at: _p!).first {

            resizeView()
            
            switch first.name {
            case "NSMultipleDocuments"?:
                Builder.Cone(scene: self.scene!)
                
            case "NSColorPanel"?:
                Builder.Grid(scene: self.scene!)
                
            case "NSComputer"?:
                cameraName = "camera"
                
            case "NSInfo"?:
                openScript()
        
        #if os(OSX)
            case "NSNetwork"?:
                cameraName = "camera1"
            case "NSAdvanced"?:
                setsView?.isHidden = false
        #endif

            case "NSFolder"?:
                break
                
            /// - Tag: TextField (x-source-tag://TextField)
            case "Name":
                if let selNode = self.selection?.node {
                    clearView()
                    
                #if os(OSX)
                    txtField.stringValue = selNode.name!
                #elseif os(iOS)
                    txtField.text = selNode.name!
                #endif

                    txtField.isHidden = false
                    txtField.frame.origin = CGPoint(x: 56, y: first.position.y * 2 + 16)
                    overRay?.label_name.text = "Name"
                }
                
            case "Position":
                if let selNode = self.selection?.node {
                    clearView()
                    
                    for (i, item) in numFields.enumerated() {
                        item.text = String(describing: { () -> SCNFloat in
                            if i == 0 {
                                return selNode.position.x
                            } else if i == 1 {
                                return selNode.position.y
                            }
                            return selNode.position.z
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
                        overRay?.label_position.text = "Position"
                    }
                }
                
            case "Rotate":
                if let selNode = self.selection?.node {
                    clearView()
                    
                    for (i, item) in numFields.enumerated() {
                        item.text = String(describing: { () -> SCNFloat in
                            if i == 0 {
                                return selNode.eulerAngles.x
                            } else if i == 1 {
                                return selNode.eulerAngles.y
                            }
                            return selNode.eulerAngles.z
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
                        overRay?.label_rotate.text = "Rotate"
                    }
                }
                
            case "Scale":
                if let selNode = self.selection?.node {
                    clearView()
                    
                    for (i, item) in numFields.enumerated() {
                        item.text = String(describing: { () -> SCNFloat in
                            if i == 0 {
                                return selNode.scale.x
                            } else if i == 1 {
                                return selNode.scale.y
                            }
                            return selNode.scale.z
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
                        overRay?.label_scale.text = "Scale"
                    }
                }
            default:
                break
            }
            return
        }
        
        // MARK: SCNNode
        if hitResults.count > 0 {
            let result: AnyObject = hitResults[0]
            if result is SCNHitTestResult {
                selection = result as? SCNHitTestResult
            }
            guard let selNode = selection?.node else {
                return
            }
            // reset color
            clearView()
            selNode.geometry!.firstMaterial!.emission.contents = (
                (selNode.geometry != nil) ? Color.red : Color.yellow
            )
            
            // Show Gizmo
            gizmos.forEach {
                root?.addChildNode($0)
                $0.position = selNode.position
                $0.isHidden = true
            }
            
            // HUD info
            overRay?.label_name.text = "Name: \(String(describing: selNode.name!))"
            overRay?.label_position.text = "Position: \(String(describing: selNode.position.xyz))"
            overRay?.label_rotate.text = "Rotate: \(String(describing: selNode.eulerAngles.xyz))"
            overRay?.label_scale.text = "Scale: \(selNode.scale.xyz)"
            overRay?.label_info.text = "Info: \(selNode.scale.xyz)"
            
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
            
            /// MARK: hitTest on Metal https://qiita.com/shu223/items/b9bcdbcf7b0fd410d8ab
            /// MARK: 4.3.1.1 Vertex Function Example with Resources and Outputs to Device Memory
            let data = outBuffer.contents().bindMemory(to: float2.self, capacity: 1)
            switch part {
            case .OverrideVertex:
                let outlineNode = duplicateNode(selectedNode)
                root?.addChildNode(outlineNode)
                outlineNode.removeFromParentNode()
                
                let outlineProgram = SCNProgram()
                outlineProgram.vertexFunctionName = "point_vertex"
                outlineProgram.fragmentFunctionName = "point_fragment"
                outlineNode.geometry?.firstMaterial?.program = outlineProgram
                outlineNode.geometry?.firstMaterial?.cullMode = .front
//                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.point, vertex: [CGFloat(data[0].x), CGFloat(data[1].x)])
            case .OverrideEdge:
                let outlineNode = duplicateNode(selectedNode)
                root?.addChildNode(outlineNode)
                outlineNode.removeFromParentNode()
                
                let outlineProgram = SCNProgram()
                outlineProgram.vertexFunctionName = "outline_vertex"
                outlineProgram.fragmentFunctionName = "outline_fragment"
                outlineNode.geometry?.firstMaterial?.program = outlineProgram
                outlineNode.geometry?.firstMaterial?.cullMode = .front
                
//                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.line, vertex: [CGFloat(data[0].x), CGFloat(data[1].x)])
            case .OverrideFace:
                let outlineNode = duplicateNode(selectedNode)
                root?.addChildNode(outlineNode)
                outlineNode.removeFromParentNode()
                
                let outlineProgram = SCNProgram()
                outlineProgram.vertexFunctionName = "face_vertex"
                outlineProgram.fragmentFunctionName = "face_fragment"
                outlineNode.geometry?.firstMaterial?.program = outlineProgram
                outlineNode.geometry?.firstMaterial?.cullMode = .front
//                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.triangleStrip, vertex: [CGFloat(data[0].x), CGFloat(data[1].x)])
            default:
                break
            }
            
        } else {
            queue.addOperation {
                self.root?.enumerateChildNodes({ child, _ in
                    if let geo = child.geometry {
                        geo.firstMaterial?.emission.contents = Color.black
                    }
                })
                self.gizmos.forEach {
                    $0.removeFromParentNode()
                }
                self.overRay?.label_name.text = "Name"
                self.overRay?.label_position.text = "Position"
                self.overRay?.label_rotate.text = "Rotate"
                self.overRay?.label_scale.text = "Scale"
                self.overRay?.label_info.text = "Info"
            }
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
            deformData = DeformData(location: float3(loc),
                                    direction: float3(loc),
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
            let offset = (hit - hit_old) * 100
            hit_old = hit
            
            if marken != nil {
                switch mode {
                    
                case .PositionMode:
                    marken!.position = marken!.position + offset
                    overRay?.label_position.text = (
                        "Position: \(String(describing: marken!.position.xyz))"
                    )
                    
                case .RotateMode:
                    marken!.eulerAngles = marken!.eulerAngles + offset
                    overRay?.label_rotate.text = (
                        "Rotate: \(String(describing: marken!.eulerAngles.xyz))"
                    )
                    
                case .ScaleMode:
                    marken!.scale = marken!.scale + offset
                    overRay?.label_scale.text = (
                        "Scale: \(String(describing: marken!.scale.xyz))"
                    )
                    
                default:
                    break
                }
                gizmos.forEach {
                    $0.position = marken!.position + offset
                }
                
            } else {
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
                    overRay?.label_position.text = (
                        "Position: \(String(describing: selection!.node.position.xyz))"
                    )
                    
                case .RotateMode:
                    marken!.rotation = selection!.node.rotation
                    overRay?.label_rotate.text = (
                        "Rotate: \(String(describing: selection!.node.eulerAngles.xyz))"
                    )
                    
                case .ScaleMode:
                    marken!.scale = selection!.node.scale
                    overRay?.label_scale.text = (
                        "Scale: \(String(describing: selection!.node.scale.xyz))"
                    )
                    
                default:
                    break
                }
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
                selection!.node.position = selection!.node.convertPosition(
                    marken!.position, from: selection!.node
                )
                overRay?.label_position.text = (
                    "Position: \(String(describing: selection!.node.position.xyz))"
                )
            case .RotateMode:
                selection!.node.eulerAngles = selection!.node.convertVector(
                    marken!.eulerAngles, from: selection!.node
                )
                overRay?.label_rotate.text = (
                    "Rotate: \(String(describing: selection!.node.eulerAngles.xyz))"
                )
            case .ScaleMode:
                selection!.node.position = selection!.node.convertVector(
                    marken!.scale, from: selection!.node
                )
                overRay?.label_scale.text = (
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
//        isEdit = true
        p = self.convert(touchLocation, from: nil)
        let hitResults = self.hitTest(p, options: options)
        if (hitResults.count < 0) {
            selection = nil
        }
        marken = nil
        
        #if os(OSX)
        super.mouseUp(with: event)
        #endif
        
        // Update
        isDeforming = false
        p = self.convert(touchLocation, to: nil)
        self.draw(CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        setNeedsDisplay()
    }
    
    private func cameraZaxis(_ view: SCNView) -> SCNVector3 {
        let cameraMat = view.pointOfView!.transform
        return SCNVector3Make(cameraMat.m31, cameraMat.m32, cameraMat.m33) * -1
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
        overRay?.label_name.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 1))
        overRay?.label_position.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 2))
        overRay?.label_rotate.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 3))
        overRay?.label_scale.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 4))
        overRay?.label_info.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 5))
        
        overRay?.button_red.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 300)
        overRay?.button_green.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 268)
        overRay?.button_blue.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 236)
        overRay?.button_magenta.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 212)
        overRay?.button_cyan.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 184)
        overRay?.button_yellow.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 156)
        overRay?.button_black.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 120)
        
        overRay?.label_message.position = CGPoint(x: 0 - round(size.width / 14), y: -size.height / 2 + 20)
    }
    
    func clearView() {        
        if txtField != nil {
            txtField.isHidden = true
        }
        
        numFields.forEach {
            $0.isHidden = true
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
            self.clearView()
            self.isDeforming = true
        case "\t": // TAB
            self.isDeforming = false
        case "\u{7F}": //del
            Editor.removeSelNode(selection: self.selection!)
            self.gizmos.forEach {
                $0.isHidden = true
            }
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
        case "o":
            self.openScript()
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
//        super.keyDown(with: event)
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
    internal var overRay: GameViewOverlay? {
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
