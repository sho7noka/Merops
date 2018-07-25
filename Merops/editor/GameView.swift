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
    
    // Mark: Mouse hit point
    
    var p = CGPoint()
    var selection: SCNHitTestResult? = nil
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
            
            let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            commandEncoder?.setComputePipelineState(cps)
            //            commandEncoder?.setTexture(drawable.texture, index: 0)
            commandEncoder?.setBuffer(mouseBuffer, offset: 0, index: 1)
            commandEncoder?.setBuffer(outBuffer, offset: 0, index: 2)
            
            update()
            
            let threadGroupCount = MTLSizeMake(1, 1, 1)
            let threadGroups = MTLSizeMake(
                drawable.texture.width / threadGroupCount.width,
                drawable.texture.height / threadGroupCount.height, 1)
            commandEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder?.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    /*
     * MARK: Mouse Event
     */
    
    override func mouseEntered(with event: Event) {
        // variables
        p = self.convert(event.locationInWindow, from: nil)
        let hitResults = self.hitTest(p, options: options)
        let result: AnyObject = hitResults[0]
        if result is SCNHitTestResult {
            selection = result as? SCNHitTestResult
        }
        
        if let selNode = selection?.node {
            selNode.geometry!.firstMaterial!.emission.contents = Color.yellow
        }
        super.mouseEntered(with: event)
    }
    
    var mode = EditContext.PositionMode
    var part = DrawOverride.Object
    var textField: TextView!
    var gizmos: [BaseNode] = []
    var numFields: [TextView] = []
    var isDeforming = false
    
    override func mouseDown(with event: Event) {
        
        // variables
        p = self.convert(event.locationInWindow, from: nil)
        let hitResults = self.hitTest(p, options: options)
        if isDeforming {
            self.gestureRecognizers.forEach {
                $0.isEnabled = false
            }
        }
        // to MTLBuffer
        let position = convertToLayer(p)
        let scale = Float(self.layer!.contentsScale)
        pos.x = Float(position.x) * scale
        pos.y = Float(bounds.height - position.y) * scale

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
                isDeforming = true
                
            /// - Tag: TextField (x-source-tag://TextField)
            case "Name":
                if let selNode = self.selection?.node {
                    clearView()
                    textField.stringValue = selNode.name!
                    textField.isHidden = false
                    textField.frame.origin = CGPoint(x: 56, y: first.position.y * 2 + 16)
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
                        }().rounded())
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
                                return selNode.rotation.x
                            } else if i == 1 {
                                return selNode.rotation.y
                            }
                            return selNode.rotation.z
                        }().rounded())
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
                        overRay?.label_position.text = "Rotate"
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
                        }().rounded())
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
                        overRay?.label_position.text = "Scale"
                    }
                }
                
            default:
                break
            }
        }
        
        /// MARK: hitTest on Metal https://qiita.com/shu223/items/b9bcdbcf7b0fd410d8ab
        if let selNode = selection?.node {
            switch part {
            case .OverrideVertex:
                let data = outBuffer.contents().bindMemory(to: float2.self, capacity: 1)
                Swift.print("\(data[0].x) \(data[1].x)")
                prim = MetalPrimitiveData(node: selNode, type: MTLPrimitiveType.point, vertex: [data[0].x, data[1].x])
            case .OverrideEdge, .OverrideFace:
                break
            default:
                break
            }
        }
        
        // MARK: SCNNode
        if hitResults.count > 0 {
            
            // variables
            let result: AnyObject = hitResults[0]
            if result is SCNHitTestResult {
                selection = result as? SCNHitTestResult
            }
            if let selNode = selection?.node {
                resizeView()
                
                // HUD info
                overRay?.label_name.text = "Name: \(String(describing: selNode.name!))"
                overRay?.label_position.text = "Position: \(String(describing: selNode.position.xyz))"
                overRay?.label_rotate.text = "Rotate: \(String(describing: selNode.rotation.xyzw))"
                overRay?.label_scale.text = "Scale: \(selNode.scale.xyz)"
                overRay?.label_info.text = "Info: \(selNode.scale.xyz)"
                overRay?.label_info.text = ""
                overRay?.label_info.isHidden = false
                
                // reset color
                selNode.geometry!.firstMaterial!.emission.contents = (
                    (selNode.geometry != nil) ? Color.red : Color.yellow
                )
                
                // Show Gizmo
                gizmos.forEach {
                    root.addChildNode($0)
                    $0.position = selNode.position
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
            }
            
        } else {
            let queue = OperationQueue()
            queue.addOperation {
                self.gizmos.forEach {
                    $0.removeFromParentNode()
                }
                
                self.root.enumerateChildNodes({ child, _ in
                    if let geo = child.geometry {
                        geo.firstMaterial?.emission.contents = Color.black
                    }
                })
            }
            overRay?.label_name.text = "Name"
            overRay?.label_position.text = "Position"
            overRay?.label_rotate.text = "Rotate"
            overRay?.label_scale.text = "Scale"
            overRay?.label_info.isHidden = true
        }

        self.allowsCameraControl = (hitResults.count == 0)
        super.mouseDown(with: event)
    }
    
    override func beginGesture(with event: Event) {
        Swift.print("\(event.pressure)")
    }
    
    

    // Draggable
    var marken: SCNNode? = nil
    var hit_old = SCNVector3Zero
    var deformData: DeformData? = nil
    var isEdit = false
    
    override func mouseDragged(with event: Event) {
        let mouse = self.convert(event.locationInWindow, from: self)
        var hitTests = self.hitTest(mouse, options: nil)
        let result = hitTests[0]

        if isDeforming {
            let loc = result.localCoordinates
            let globalDir = self.cameraZaxis(self) * -1
            let localDir = result.node.convertPosition(globalDir, from: nil)
            deformData = DeformData(location: float3(loc),
                direction: float3(loc),
                radiusSquared: 16.0, deformationAmplitude: 1.5, pad1: 0, pad2: 0
            ); return
        }

        if selection != nil && mode == EditContext.PositionMode {
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

            if marken != nil {
                marken!.position = marken!.position + offset
                gizmos.forEach {
                    $0.position = marken!.position + offset
                }

            } else {
                marken = selection!.node.clone()
                marken!.opacity = 0.333

                switch part {

                case .OverrideFace:
                    marken = marken?.copy() as? SCNNode
                    marken = SCNNode(geometry:
                        SCNGeometry(
                            sources: (marken?.geometry?.sources)!, elements: marken?.geometry?.elements
                        )
                    )
                    marken!.position = selection!.node.position
                    selection!.node.parent!.addChildNode(marken!)

                case .OverrideVertex, .OverrideEdge:
                    break

                default:
                    marken!.position = selection!.node.position
                    gizmos.forEach {
                        $0.position = selection!.node.position
                    }
                    selection!.node.parent!.addChildNode(marken!)
                    overRay?.label_position.text = (
                        "Position : \(String(describing: selection!.node.position.xyz))"
                    )
                }
            }

        } else {
            super.mouseDragged(with: event)
        }
    }
    
    override func mouseUp(with event: Event) {
        if selection != nil && marken != nil {
            if event.modifierFlags == Event.ModifierFlags.control {
                marken!.opacity = 1.0
                
            } else {
                switch part {
                case .OverrideVertex, .OverrideFace, .OverrideEdge:
                    break

                default:
                    selection!.node.position = selection!.node.convertPosition(
                        marken!.position, from: selection!.node
                    )
                    gizmos.forEach {
                        $0.position = selection!.node.convertPosition(
                            marken!.position, from: selection!.node
                        )
                    }
                    overRay?.label_position.text = (
                        "Position : \(String(describing: selection!.node.position.xyz))"
                    )
                }
                marken!.removeFromParentNode()
            }
            // set nil
            selection = nil
            marken = nil
            
        } else {
            super.mouseUp(with: event)
        }

        // Export
        if isEdit {
            let asset = USDExporter.exportFromAsset(scene: self.scene!)
            self.scene = SCNScene(mdlAsset: asset)
            isEdit = false
        }
        
        // Update
        isDeforming = false
        self.gestureRecognizers.forEach {
            $0.isEnabled = true
        }
        self.allowsCameraControl = true
        p = self.convert(event.locationInWindow, to: nil)
        needsDisplay = true
    }
    
    private func cameraZaxis(_ view: SCNView) -> SCNVector3 {
        let cameraMat = view.pointOfView!.transform
        return SCNVector3Make(cameraMat.m31, cameraMat.m32, cameraMat.m33) * -1
    }

    var prim: MetalPrimitiveData?
    
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
    
    var console: ConsoleView!
    
    private func clearView() {
        if console != nil {
            console.isHidden = true
        }
        
        if textField != nil {
            textField.isHidden = true
        }
        
        numFields.forEach {
            $0.isHidden = true
        }
    }

    /*
     * MARK: Resize Event
     */
    
    var subView: SCNView?
    
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
        overRay?.label_message.position = CGPoint(x: -size.width / 2 + 300, y: -size.height / 2 + 28)
    }
    
    /*
     * Mark : Key Event
     */
    
    private func removeSelNode() {
        if selection?.node.categoryBitMask != NodeOptions.noExport.rawValue {
            selection?.node.removeFromParentNode()
            gizmos.forEach {
                $0.isHidden = true
            }
        }
    }
    
    var settings: Settings?
    
    override func keyDown(with event: Event) {
        switch event.characters! {
        case "\u{1B}": //ESC
            clearView()
        case "\u{7F}": //del
            removeSelNode()
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
        case "1", "2", "3", "4":
            self.debugOptions = SCNOptions[Int(event.characters!)!]
        case "c":
            break
        case "v":
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
}
