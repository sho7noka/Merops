//
//  GameViewController.swift
//  Merops
//
//  Created by sumioka-air on 2017/04/30.
//  Copyright (c) 2017年 sho sumioka. All rights reserved.
//

import Metal
import MetalKit
import SpriteKit
import SceneKit
import QuartzCore

import ImGui

class GameViewController: SuperViewController, SCNSceneRendererDelegate, TextFieldDelegate {
    
    // Base
    var scene = SCNScene()
    var baseNode: SCNNode? = nil
    var device: MTLDevice!
    
    // View
    @IBOutlet weak var gameView: GameView!
    var overRay: GameViewOverlay!
    
    // Metal
    var render: MetalRender!
    var meshData: MetalMeshData!
    var deform: MetalMeshDeformer!
    var primData: MetalPrimitiveData!
    var primHandle: MetalPrimitiveHandle!
    
    /*
     * NOTE: render 内で `thorows` 使うと render 使えない(オーバーロード扱いされない)
     */
    @objc
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        /// - Tag: DrawOverride
        if let primData = gameView.prim {
            primHandle.typeRender(prim: primData)
        }

        // Mark: Deformer
        guard let deformData = gameView.deformData else {
            return
        }
        deform.deform(meshData, deformData: deformData)
        gameView.deformData = nil
        
        // buffer
        let commandBuffer = render.commandBuffer()
        commandBuffer?.pushDebugGroup("in SCNRender Buffer")
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(
            descriptor: render.renderPassDescriptor())
        let renderPipelineState = try! device.makeRenderPipelineState(
            descriptor: render.renderPipelineDescriptor())
        renderEncoder?.setRenderPipelineState(renderPipelineState)
        renderEncoder?.endEncoding()
        
        render.scene = scene
        render.pointOfView = gameView.pointOfView
        render.render(atTime: 0,
                      viewport: CGRect(x: 0, y: 0, width: gameView.frame.width, height: gameView.frame.height),
                      commandBuffer: commandBuffer!, passDescriptor: render.renderPassDescriptor())
        
        commandBuffer?.commit()
        commandBuffer?.popDebugGroup()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if gameView == nil {
            gameView = GameView()
            self.view.addSubview(gameView)
        }
        
        // MARK: Metal Render
        device = MTLCreateSystemDefaultDevice()
        render = MetalRender(device: device, options: nil)
        
        // MARK: Renderert
        deform = MetalMeshDeformer(device: render.device!)
        primHandle = MetalPrimitiveHandle(render: render, view: gameView)
        sceneInit()
        
        // MARK: set scene to view
        gameView.scene = scene
        gameView.delegate = self
        gameView.isPlaying = true
        uiInit()
    }
    
    private func sceneInit() {
        // MARK: replace object
        meshData = MetalMeshDeformable.buildPlane(device, width: 150, length: 70, step: 1)
        let newNode = Builder.Plane(meshData: meshData)
        let (min, max) = newNode.boundingBox
        let x = CGFloat(max.x - min.x)
        let y = CGFloat(max.y - min.y)
        newNode.position = SCNVector3(-(x/2), -1, -2)
        
        if let existingNode = baseNode {
            scene.rootNode.replaceChildNode(existingNode, with: newNode)
        } else {
            scene.rootNode.addChildNode(newNode)
        }
        baseNode = newNode
//        HalfEdgeStructure.LoadModel(device: device, name: "", reduction: 100)
        
        Builder.Camera(scene: scene)
        Builder.Light(scene: scene)
        Builder.Camera(scene: scene, name: "camera1", position: SCNVector3(0, 0, 10))
        
        // gizmos
        [PositionNode(), ScaleNode(), RotateNode()].forEach{
            gameView.gizmos.append($0)
        }
    }
    
    private func uiInit() {
        // MARK: Settings
        gameView.settings = Settings(
            dir: userDocument(fileName: "model.usd").deletingPathExtension().path,
            color: Color.lightGray,
            usdDir: Bundle.main.bundleURL.deletingLastPathComponent().path,
            pyDir: "/usr/bin/python")
        
        gameView.queue = device.makeCommandQueue()
        gameView.showsStatistics = true
        gameView.allowsCameraControl = true
        gameView.autoenablesDefaultLighting = true
        gameView.backgroundColor = (gameView.settings?.bgColor)!
        
//        Editor.EditorDome(scene: scene)
        Editor.EditorGrid(scene: scene)
        
        /// - Tag: addSubView
        gameView.subView = SCNView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        gameView.subView?.scene = SCNScene()
        gameView.subView?.allowsCameraControl = true
        gameView.subView?.backgroundColor = .clear
//        gameView.subView?.defaultCameraController
        gameView.subView?.isPlaying = true
        
        let pos = PositionNode()
        pos.isHidden = false
        gameView.subView?.scene?.rootNode.addChildNode(pos)
        gameView.addSubview(gameView.subView!)
        
        // MARK: Overray
        gameView.overlaySKScene = GameViewOverlay(view: gameView)
        overRay = gameView.overlaySKScene as? GameViewOverlay
        overRay.isUserInteractionEnabled = false
        gameView.cameraName = (gameView.defaultCameraController.pointOfView?.name)!
        
        // MARK: Text Field
        gameView.numFields.append(contentsOf: [TextView(), TextView(), TextView()])
        gameView.numFields.forEach {
            $0.delegate = self
            $0.frame = CGRect(x: 10, y: 10, width: 32, height: 20)
            $0.backgroundColor = Color.white
            $0.isHidden = true
            gameView.addSubview($0)
        }
        gameView.txtField = TextView()
        gameView.txtField.frame = CGRect(x: 10, y: 10, width: 100, height: 20)
        gameView.txtField.backgroundColor = Color.white
        gameView.txtField.isHidden = true
        gameView.addSubview(gameView.txtField!)
        
    #if os(OSX)
        gameView.setsView = SettingDialog(frame: gameView.frame, setting: gameView.settings!)
        gameView.setsView?.isHidden = true
        gameView.addSubview(gameView.setsView!)
        
        // MARK: Console
        gameView.resizeView()
        gameView.console = PythonConsole(frame: gameView.frame, view: gameView)
        gameView.console.isHidden = true
        gameView.addSubview(gameView.console)

        gameView.txtField.placeholder = "Name"
        gameView.txtField.delegate = self
    #elseif os(iOS)
        gameView.txtField.addTarget(self, action: "textFieldEditingChanged:", for: .editingChanged)
        
        // add a tap gesture recognizer
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gameView.selection))
//        gameView.addGestureRecognizer(tapGesture)
    #endif
        
        /// - Tag: Mouse Buffer
        gameView.cps = try! device.makeComputePipelineState(function: render.mouseFunction)
        gameView.mouseBuffer = device!.makeBuffer(length: MemoryLayout<float2>.size, options: [])
        gameView.outBuffer = device?.makeBuffer(bytes: [Float](repeating: 0, count: 2), length: 2 * MemoryLayout<float2>.size, options: [])
        
        ImGui.initialize(.metal)
        
        if let vc = ImGui.vc {
            addChildViewController(vc)
//            addChildViewController(vc)
            view.addSubview(vc.view)
            vc.view.frame = CGRect(x: 0, y: view.frame.height * 0.7, width: view.frame.width, height: view.frame.height * 0.3)
        }
        
        ImGui.draw { (imgui) in
            
            // Setting Window Position and window size
            imgui.setNextWindowPos(CGPoint.zero, cond: .always)
            imgui.setNextWindowSize(self.view.frame.size)
            imgui.begin("Hello ImGui on Swift")
            
            // Setting the font scale
//            imgui.setWindowFontScale(NSScreen.main.scale)
            
            
            // When button is clicked...
            if imgui.button("rotate me") {
                // rotate me
//                self.myView.transform = CGAffineTransform.identity
//                UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.9, animations: {
//                    self.myView.transform = CGAffineTransform.init(rotationAngle: 180.0)
//                }).startAnimation()
            }
            
//            imgui.sliderFloat("cornerRadius", v: &self.gameView.selectedNode.position.x, minV: 0.0, maxV: 10.0)
//            imgui.sliderFloat2("offset", v: &self.gameView.selectedNode, minV: -100.0, maxV: 100.0)
//            imgui.sliderFloat2("size", v: &self.myView.bounds.size, minV: 5.0, maxV: 100.0)
            imgui.colorEdit("backgroundColor", color: &(self.gameView.backgroundColor))
            imgui.end()
            
//            var center = self.view.center
//            center.x += self.viewOffset.x
//            center.y += self.viewOffset.y
//            self.myView.center = center
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

#if os(OSX)
extension SuperViewController: NSControlTextEditingDelegate {
    open override func controlTextDidEndEditing(_ notification: Notification) {
        if let textField = notification.object as? TextView {
            guard let node = (self as! GameViewController).gameView.selection?.node else { return }
            
            switch textField.placeholderString {
            case "Name":
                node.name = textField.stringValue
            case "positionX":
                node.position.x = CGFloat(textField.doubleValue)
            case "positionY":
                node.position.y = CGFloat(textField.doubleValue)
            case "positionZ":
                node.position.z = CGFloat(textField.doubleValue)
            case "rotationX":
                node.eulerAngles.x = CGFloat(textField.doubleValue)
            case "rotationY":
                node.eulerAngles.y = CGFloat(textField.doubleValue)
            case "rotationZ":
                node.eulerAngles.z = CGFloat(textField.doubleValue)
            case "scaleX":
                node.scale.x = CGFloat(textField.doubleValue)
            case "scaleY":
                node.scale.y = CGFloat(textField.doubleValue)
            case "scaleZ":
                node.scale.z = CGFloat(textField.doubleValue)
            default:
                break
            }
            
            (self as! GameViewController).gameView.gizmos.forEach {
                $0.position = node.position
            }
        }
    }
}
#elseif os(iOS)
extension GameViewController {
    func addChildViewController(vc: SuperViewController) {
        self.addChild(vc)
    }
}
#endif
