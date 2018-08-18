//
//  GameView.swift
//  Merops
//
//  Created by sumioka-air on 2017/04/30.
//  Copyright (c) 2017年 sho sumioka. All rights reserved.
//

import SpriteKit
import SceneKit

extension GameView {
    
    // event
    internal var overRay: GameViewOverlay? {
        return (overlaySKScene as? GameViewOverlay)
    }
    
    internal func keybind(modify: Event.ModifierFlags, k: String, e: Event) -> Bool {
        return (e.characters! == k &&
            e.modifierFlags.intersection(Event.ModifierFlags.deviceIndependentFlagsMask) == modify
        )
    }
    
    // node
    internal var root: SCNNode {
        return self.scene!.rootNode
    }
    
    internal func node(name: String) -> SCNNode? {
        return self.scene!.rootNode.childNode(withName: name, recursively: true)
    }
    
    // drawable
    internal var metalLayer: CAMetalLayer {
        let metalLayer = (self.layer as? CAMetalLayer)!
        metalLayer.framebufferOnly = false
        return metalLayer
    }
}

class GameView: SCNView {
    
    /*
     * Mark: Mouse hit point
     */
    
    var p = CGPoint()
    var selection: SCNHitTestResult? = nil
    var selectedNode: SCNNode!
    var zDepth: SCNFloat!
    var pos = float2()
    let options = [
        SCNHitTestOption.sortResults: NSNumber(value: true),
        SCNHitTestOption.boundingBoxOnly: NSNumber(value: true),
        SCNHitTestOption.categoryBitMask: NSNumber(value: true),
    ]
    var mouseBuffer: MTLBuffer!
    var outBuffer: MTLBuffer!
    var queue: MTLCommandQueue! = nil
    var cps: MTLComputePipelineState! = nil
    
    private func update() {
        let bufferPointer = mouseBuffer.contents()
        memcpy(bufferPointer, &pos, MemoryLayout<float2>.size)
    }
    
    override func draw(_ dirtyRect: NSRect) {
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
    
    override func beginGesture(with event: Event) {
        Swift.print("\(event.pressure)")
        super.beginGesture(with: event)
    }
    
    /*
     * MARK: Mouse Event
     */
    
    var isEdit = false {
        didSet {
            if isEdit {
                let asset = USDExporter.exportFromAsset(scene: self.scene!)
                self.scene = SCNScene(mdlAsset: asset)
                isEdit = false
            }
        }
    }
    
    var cameraName = "camera" {
        willSet {
            self.root.enumerateChildNodes({ child, _ in
                if let camera = child.camera {
                    Swift.print(camera.name)
                }
            })
            self.pointOfView?.position
        }
        didSet {
            self.pointOfView = self.node(name: cameraName)
            self.overRay?.label_message.text = cameraName + " / " + mode.toString
        }
    }
    
    var mode = EditContext.PositionMode {
        didSet {
            self.overRay?.label_message.text = cameraName + " / " + mode.toString
            self.overRay?.label_message.fontColor = Color.white
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
    
    var txtField: TextView!
    var gizmos: [ManipulatorBase] = []
    var numFields: [TextView] = []
    
    override func mouseDown(with event: Event) {
        
        // point to MTLBuffer
        p = self.convert(event.locationInWindow, from: nil)
        let hitResults = self.hitTest(p, options: options)
        let position = convertToLayer(p)
        let scale = Float((self.layer?.contentsScale)!)
        pos.x = Float(position.x) * scale
        pos.y = Float(bounds.height - position.y) * scale
        
        if let hit = hitResults.first {
            selectedNode = hit.node
            zDepth = self.projectPoint(selectedNode.position).z
        }
        let queue = OperationQueue()
        
        // MARK: overray
        let _p = overRay?.convertPoint(fromView: event.locationInWindow)
        if let first = overRay?.nodes(at: _p!).first {
            resizeView()
            
            switch first.name {
            case "red":
                Builder.Cone(scene: self.scene!)
                
            case "blue":
                Builder.Grid(scene: self.scene!)
                
            case "green":
                Builder.Torus(scene: self.scene!)
                
            case "cyan":
                cameraName = "camera1"
                
            case "magenta":
                cameraName = "camera"
                
            case "black":
                let setwindow = SettingDialog()
                self.addSubview(setwindow)
                
                
            /// - Tag: TextField (x-source-tag://TextField)
            case "Name":
                if let selNode = self.selection?.node {
                    clearView()
                    
                    txtField.stringValue = selNode.name!
                    txtField.isHidden = false
                    txtField.frame.origin = CGPoint(x: 56, y: first.position.y * 2 + 16)
                    overRay?.label_name.text = "Name"
                }
                
            case "Position":
                if let selNode = self.selection?.node {
                    clearView()
                    
                    for (i, item) in numFields.enumerated() {
                        item.stringValue = String(describing: { () -> CGFloat in
                            if i == 0 {
                                return selNode.position.x
                            } else if i == 1 {
                                return selNode.position.y
                            }
                            return selNode.position.z
                        }())
                        item.placeholderString = { () -> String in
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
                        item.stringValue = String(describing: { () -> CGFloat in
                            if i == 0 {
                                return selNode.eulerAngles.x
                            } else if i == 1 {
                                return selNode.eulerAngles.y
                            }
                            return selNode.eulerAngles.z
                        }())
                        item.placeholderString = { () -> String in
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
                        item.stringValue = String(describing: { () -> CGFloat in
                            if i == 0 {
                                return selNode.scale.x
                            } else if i == 1 {
                                return selNode.scale.y
                            }
                            return selNode.scale.z
                        }())
                        item.placeholderString = { () -> String in
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
            
            // finally
            super.mouseDown(with: event)
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
                root.addChildNode($0)
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
            switch part {
            case .OverrideVertex:
                let data = outBuffer.contents().bindMemory(to: float2.self, capacity: 1)
                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.point, vertex: [data[0].x, data[1].x])
            case .OverrideEdge:
                let data = outBuffer.contents().bindMemory(to: float2.self, capacity: 1)
                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.line, vertex: [data[0].x, data[1].x])
            case .OverrideFace:
                let data = outBuffer.contents().bindMemory(to: float2.self, capacity: 1)
                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.triangleStrip, vertex: [data[0].x, data[1].x])
            default:
                break
            }
            
        } else {
            queue.addOperation {
                self.root.enumerateChildNodes({ child, _ in
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
        super.mouseDown(with: event)
    }
    
    // Draggable
    var marken: SCNNode? = nil
    var hit_old = SCNVector3Zero
    var deformData: DeformData? = nil
    
    override func mouseDragged(with event: Event) {
        let mouse = self.convert(event.locationInWindow, from: self)
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
            var unPoint = self.unprojectPoint(SCNVector3(x: mouse.x, y: mouse.y, z: 0.0))
            let p1 = selection!.node.parent!.convertPosition(unPoint, from: nil)
            unPoint = self.unprojectPoint(SCNVector3(x: mouse.x, y: mouse.y, z: 1.0))
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
            Swift.print(offset)

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
            super.mouseDragged(with: event)
        }
    }
    
    override func mouseUp(with event: Event) {
        if selection != nil && marken != nil {
            if event.modifierFlags == Event.ModifierFlags.control {
                marken!.opacity = 1.0
                marken!.filters = nil
                
            } else {
                
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
            isEdit = true
            selection = nil
            marken = nil
            
        } else {
            super.mouseUp(with: event)
        }
        
        // Update
        isDeforming = false
        p = self.convert(event.locationInWindow, to: nil)
        self.draw(NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        needsDisplay = true
    }
    
    var part = DrawOverride.Object
    var prim: MetalPrimitiveData?
    
    private func cameraZaxis(_ view: SCNView) -> SCNVector3 {
        let cameraMat = view.pointOfView!.transform
        return SCNVector3Make(cameraMat.m31, cameraMat.m32, cameraMat.m33) * -1
    }

    /*
     * MARK: Resize Event
     */
    
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
    
    func resizeView() {
        let size = self.frame.size
        subView?.frame.origin = .init(x: size.width - 88 , y: 24)
        overRay?.label_name.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 1))
        overRay?.label_position.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 2))
        overRay?.label_rotate.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 3))
        overRay?.label_scale.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 4))
        overRay?.label_info.position = CGPoint(x: -size.width / 2 + 16, y: size.height / 2 - CGFloat(20 * 5))
        overRay?.button_red.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 272)
        overRay?.button_green.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 248)
        overRay?.button_blue.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 224)
        overRay?.button_magenta.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 200)
        overRay?.button_cyan.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 176)
        overRay?.button_yellow.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 152)
        overRay?.button_black.position = CGPoint(x: size.width / 2 - 18, y: -size.height / 2 + 128)
        overRay?.label_message.position = CGPoint(x: 0 - round(size.width / 22), y: -size.height / 2 + 28)
    }
    
    private func clearView() {
        if console != nil {
            console.isHidden = true
        }
        
        if txtField != nil {
            txtField.isHidden = true
        }
        
        numFields.forEach {
            $0.isHidden = true
        }
    }
    var console: ConsoleView!
    var subView: SCNView?
    
    /*
     * Mark : Key Event
     */
    
    override func keyDown(with event: Event) {
        switch event.characters! {
        case "\u{1B}": //ESC
            clearView()
        case "1", "2", "3", "4":
            self.debugOptions = SCNOptions[Int(event.characters!)!]
        case "\t": // TAB
            break
        case "q":
            self.resetView(_mode: .Object)
        case "w":
            self.resetView(_mode: .PositionMode)
        case "e":
            self.resetView(_mode: .ScaleMode)
        case "r":
            self.resetView(_mode: .RotateMode)
        case "a":
            self.resetView(_mode: .Object)
        case "s":
            self.resetView(_part: .OverrideVertex)
        case "d":
            self.resetView(_part: .OverrideEdge)
        case "f":
            self.resetView(_part: .OverrideFace)
        case "z":
            gitRevert(url: (settings?.projectDir)!)
        case "x":
            gitCommit(url: (settings?.projectDir)!)
        case "c":
            break
        case "v":
            break
        case "\u{7F}": //del
            Editor.removeSelNode(selection: selection!)
            gizmos.forEach {
                $0.isHidden = true
            }
        case "\r": //Enter
            break
        default:
            break
        }
        
        // ctrl + d
        if keybind(modify: Event.ModifierFlags.command, k: "d", e: event) {
        
        }

        // Update
        self.draw(NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        needsDisplay = true
        super.keyDown(with: event)
    }
    
    func resetView(_mode: EditContext = EditContext.Object, _part: DrawOverride = DrawOverride.Object) {
        part = _part
        
        // MARK: curret override mode
        if let selNode = selection?.node {
            switch part {
            case .OverrideVertex:
                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.point, vertex: [])
                
            case .OverrideEdge:
                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.line, vertex: [])
                
            case .OverrideFace:
                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.triangleStrip, vertex: [])
                
            default:
                prim = nil
            }
        }
        
        // track gizmo position
        gizmos.forEach {
            root.addChildNode($0)
            if let selNode = selection?.node {
                $0.position = selNode.position
            }
            $0.isHidden = true
        }
        mode = _mode
        
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
        
        // reset color
        root.enumerateChildNodes({ child, _ in
            if let geo = child.geometry {
                geo.firstMaterial?.emission.contents = Color.black
            }
        })
    }

    var settings: Settings?
}
