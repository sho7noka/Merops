//
//  GameViewController.swift
//  KARAS
//
//  Created by sumioka-air on 2017/04/30.
//  Copyright (c) 2017年 sho sumioka. All rights reserved.
//

import Metal
import MetalKit
import SpriteKit
import SceneKit
import QuartzCore
//import ImGui

extension SuperViewController: NSControlTextEditingDelegate {
    open override func controlTextDidEndEditing(_ notification: Notification) {
        if let textField = notification.object as? TextView {
            let node = (self as! GameViewController).gameView.selection?.node
            switch textField.placeholderString {
            case "Name":
                node?.name = textField.stringValue
            case "positionX":
                node?.position.x = CGFloat(textField.doubleValue)
            case "positionY":
                node?.position.y = CGFloat(textField.doubleValue)
            case "positionZ":
                node?.position.z = CGFloat(textField.doubleValue)
            case "rotationX":
                node?.rotation.x = CGFloat(textField.doubleValue)
            case "rotationY":
                node?.rotation.y = CGFloat(textField.doubleValue)
            case "rotationZ":
                node?.rotation.z = CGFloat(textField.doubleValue)
            case "scaleX":
                node?.scale.x = CGFloat(textField.doubleValue)
            case "scaleY":
                node?.scale.y = CGFloat(textField.doubleValue)
            case "scaleZ":
                node?.scale.z = CGFloat(textField.doubleValue)
            default:
                break
            }
        }
    }
}

class GameViewController: SuperViewController, SCNSceneRendererDelegate, NSTextFieldDelegate {
    
    // Model
    var scene = SCNScene()
    var baseNode: SCNNode? = nil
    var render: SCNRenderer!
    
    // View
    @IBOutlet weak var gameView: GameView!
    var overRay: GameViewOverlay!
    
    // Metal
    var device: MTLDevice!
    var library: MTLLibrary!
    var mRender: MetalRender!
    var meshData: MetalMeshData!
    var deform: MetalMeshDeformer!
    var primData: MetalPrimitiveData!
    var primHandle: MetalPrimitiveHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: Metal Render
        device = MTLCreateSystemDefaultDevice()
        library = device.makeDefaultLibrary()
        
        // MARK: Renderer
        deform = MetalMeshDeformer(device: device)
        primHandle = MetalPrimitiveHandle(device: device, library: library!, view: gameView)
        
        mRender = MetalRender(device: device)
        render = SCNRenderer(device: device, options: nil)
        sceneInit()
        
        // MARK: set scene to view
        gameView.delegate = self
        gameView.allowsCameraControl = true
        gameView.showsStatistics = true
        gameView.autoenablesDefaultLighting = true
        gameView.isPlaying = true
        
        gameView.scene = scene
        gameView.queue = device.makeCommandQueue()
        gameView.settings = Settings(
            dir: userDocument(fileName: "model.usd").deletingPathExtension().path,
            color: Color.lightGray
        )
        gameView.backgroundColor = (gameView.settings?.bgColor)!
        uiInit()
        
        /// - Tag: Mouse Buffer
        let kernel = library?.makeFunction(name: "compute")
        do {
            gameView.cps = try! device.makeComputePipelineState(function: kernel!)
        } catch {}
        gameView.mouseBuffer = device!.makeBuffer(length: MemoryLayout<float2>.size, options: [])
        let bytes = [Float](repeating: 0, count: 2)
        gameView.outBuffer = device?.makeBuffer(bytes: bytes, length: 2 * MemoryLayout<float2>.size, options: [])
    }

    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) throws {
        
        Swift.print(time.nextDown)
        // deform data
        guard let deformData = gameView.deformData else {
            return
        }
        deform.deform(meshData, deformData: deformData)
        gameView.deformData = nil
        
        primData = gameView.prim
        primHandle.typeRender(prim: primData)

        // buffer
        let commandBuffer = mRender.commandBuffer()
        let renderEncoder = commandBuffer!.makeRenderCommandEncoder(
            descriptor: mRender.renderPassDescriptor()
        )
        try renderEncoder?.setRenderPipelineState(
            device.makeRenderPipelineState(descriptor: mRender.renderPipelineDescriptor())
        )
        renderEncoder?.endEncoding()

        // MARK: re-use scene and the current point of view
        render.scene = scene
        render.pointOfView = gameView.pointOfView
        render.render(atTime: 0,
                viewport: CGRect(x: 0, y: 0, width: gameView.frame.width, height: gameView.frame.height),
                commandBuffer: commandBuffer!, passDescriptor: mRender.renderPassDescriptor()
        )
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
    }
    
    private func sceneInit() {
        // MARK: replace object
        let newNode = Builder.Plane(
            meshData: MetalMeshDeformable.buildPlane(device, width: 150, length: 70, step: 1)
        )
        if let existingNode = baseNode {
            scene.rootNode.replaceChildNode(existingNode, with: newNode)
        } else {
            scene.rootNode.addChildNode(newNode)
        }
        baseNode = newNode
        // HalfEdgeStructure.LoadModel(device: device, name: "", reduction: 100)
        
        Builder.Camera(scene: scene)
        Builder.Light(scene: scene)
        
        // gizmos
        let pos = PositionNode()
        let scl = ScaleNode()
        let rot = RotateNode()
        [pos, rot, scl].forEach{
            gameView.gizmos.append($0)
        }
    }
    
    private func uiInit() {
        /// - Tag: addSubView
        gameView.subView = SCNView(frame: NSRect(x: 0, y: 0, width: 80, height: 80))
        gameView.subView?.scene = SCNScene()
        gameView.subView?.allowsCameraControl = true
        gameView.subView?.backgroundColor = .clear
        gameView.subView?.isPlaying = true
        let geo = SCNNode(geometry: SCNSphere(radius: 5))
        geo.categoryBitMask = NodeOptions.noExport.rawValue
        geo.geometry?.firstMaterial?.diffuse.contents = Color.white
        gameView.subView?.scene?.rootNode.addChildNode(geo)
        gameView.addSubview(gameView.subView!)
        
        /*
         ImGui.initialize(.metal)
         if let vc = ImGui.vc {
         addChildViewController(vc)
         vc.view.layer?.backgroundColor = NSColor.clear.cgColor
         vc.view.frame = view.frame
         view.addSubview(vc.view)
         }
         
         ImGui.draw { (imgui) in
         imgui.pushStyleVar(ImGuiStyleVar.windowRounding, value: 0.0)
         imgui.begin("Hello ImGui")
         if imgui.button("Click me") {
         Swift.print("you clicked me.")
         }
         imgui.end()
         imgui.popStyleVar()
         }
         */
        
        // MARK: Overray
        gameView.overlaySKScene = GameViewOverlay(view: gameView)
        overRay = gameView.overlaySKScene as? GameViewOverlay
        overRay.isUserInteractionEnabled = false
        gameView.resizeView()
        
        // MARK: Console
        gameView.console = ConsoleView(frame: gameView.frame)
        gameView.console.isHidden = true
        gameView.addSubview(gameView.console)
        
        // MARK: Text Field
        gameView.numFields.append(contentsOf: [TextView(), TextView(), TextView()])
        gameView.numFields.forEach {
            $0.delegate = self
            $0.frame = CGRect(x: 10, y: 10, width: 32, height: 20)
            $0.backgroundColor = Color.white
            $0.isHidden = true
            gameView.addSubview($0)
        }
        gameView.textField = TextView()
        gameView.textField.frame = CGRect(x: 10, y: 10, width: 100, height: 20)
        gameView.textField.backgroundColor = Color.white
        gameView.textField.isHidden = true
        gameView.textField.placeholderString = "Name"
        gameView.addSubview(gameView.textField!)
    #if os(OSX)
        gameView.textField.delegate = self
    #elseif os(iOS)
        gameView.textField.addTarget(self, action: "textFieldEditingChanged:", forControlEvents: .EditingChanged)
    #endif
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
