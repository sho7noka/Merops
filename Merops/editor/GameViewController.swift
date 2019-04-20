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

#if os(iOS)
import UIKit
#endif

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
            view.addSubview(gameView)
            gameView.frame = CGRect(x: 0, y: 0,
                                    width: view.frame.width,
                                    height: view.frame.height)
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
        
        executeCallback()
        start()
    }
    
    private func sceneInit() {
        gameView.model = Model()
        
        // MARK: replace object
        meshData = MetalMeshDeformable.buildPlane(device, width: 150, length: 70, step: 1)
        let newNode = Builder.Plane(meshData: meshData)
        let (min, max) = newNode.boundingBox
        let x = CGFloat(max.x - min.x)
        _ = CGFloat(max.y - min.y)
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
            pyDir: "/usr/bin/python",
            editor: "Visual Studio Code"
        )
        gameView.queue = device.makeCommandQueue()
        gameView.allowsCameraControl = true
        gameView.autoenablesDefaultLighting = true
        gameView.backgroundColor = (gameView.settings?.bgColor)!
        
        /// - Tag: addSubView
        gameView.subView = SCNView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        gameView.subView?.scene = SCNScene()
        gameView.subView?.allowsCameraControl = true
        gameView.subView?.backgroundColor = .clear
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
        gameView.txtField.placeholder = "Name"
        gameView.txtField.delegate = self
        
    #elseif os(iOS)
        gameView.txtField.addTarget(self, action: Selector(("textFieldEditingChanged:")), for: .editingChanged)
        gameView.documentInteractionController.delegate = (self as! UIDocumentInteractionControllerDelegate)
        
    #endif
        
        /// - Tag: Mouse Buffer
        gameView.cps = try! device.makeComputePipelineState(function: render.mouseFunction)
        gameView.mouseBuffer = device!.makeBuffer(length: MemoryLayout<float2>.size, options: [])
        gameView.outBuffer = device?.makeBuffer(bytes: [Float](repeating: 0, count: 2), length: 2 * MemoryLayout<float2>.size, options: [])
        
        /// - Tag: ImGui
        ImGui.initialize(.metal)
        if let vc = ImGui.vc {
            self.addChild(vc)
            view.addSubview(vc.view)
            vc.view.frame = CGRect(x: view.frame.width * 0.2,
                                   y: view.frame.height * 0.3,
                                   width: view.frame.width,
                                   height: view.frame.height * 0.5)
            self.removeChild(at: 0)
        }
        
        ImGui.draw { (imgui) in
            let f = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            f[0] = true
            imgui.begin("Attributes", show: f, flags: .alwaysAutoResize)
            // style
            imgui.setWindowFontScale(2.0)
            imgui.setNextWindowPos(CGPoint.zero, cond: .always)
            imgui.setNextWindowSize(self.view.frame.size)
            
            // items
            imgui.pushStyleVar(.windowRounding, value: 0)
            imgui.pushStyleColor(.frameBg, color: Color.blue)
            imgui.sliderFloat("index", v: &self.gameView.val, minV: 0.0, maxV: 10.0)
            imgui.colorEdit("backgroundColor", color: &(self.gameView.backgroundColor))
            
            imgui.beginGroup()
            if imgui.button("Edit") {
                dump(imgui)
            }
            if imgui.button("Script") {
                self.gameView.openScript()
            }
            imgui.endGroup()
            imgui.popStyleColor()
            imgui.popStyleVar()
            imgui.end()
        }
    #if DEBUG
        gameView.showsStatistics = true
    #endif
        Editor.EditorGrid(view: gameView)
        gameView.resizeView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

#if os(iOS)
//    http://chicketen.blog.jp/archives/76071441.html
    override func viewWillLayoutSubviews() {
        self.gameView.resizeView()
        super.viewWillLayoutSubviews()
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "Q",
                         modifierFlags: .init(rawValue: 0),
                         action: #selector(self.performCommand(sender:))),

            UIKeyCommand(input: "W",
                         modifierFlags: .init(rawValue: 0),
                         action: #selector(self.performCommand(sender:))),

            UIKeyCommand(input: "E",
                         modifierFlags: .init(rawValue: 0),
                         action: #selector(self.performCommand(sender:))),
            
            UIKeyCommand(input: "R",
                         modifierFlags: .init(rawValue: 0),
                         action: #selector(self.performCommand(sender:))),
            
            UIKeyCommand(input: "O",
                         modifierFlags: .init(rawValue: 0),
                         action: #selector(self.performCommand(sender:)))
        ]
    }
    
    @objc func performCommand(sender: UIKeyCommand) {
        
        switch sender.input {
        case "Q":
            gameView.resetView(_mode: .Object)
            return
        case "W":
            gameView.resetView(_mode: .PositionMode)
            return
        case "E":
            gameView.resetView(_mode: .ScaleMode)
            return
        case "R":
            gameView.resetView(_mode: .RotateMode)
            return
        case "O":
            storeAndShare(withURLString: (gameView.model!.file ?? nil)!)
//            storeAndShare(withURLString: "https://images5.alphacoders.com/581/581655.jpg")
            return
        case .none:
            break
        case .some(_):
            break
        }
    }
#endif
    
}

#if os(OSX)
extension TextView {
    var text: String {
        get {
            return self.stringValue
        }
        set (text) {
            self.stringValue = text
        }
    }
    
    var placeholder: String {
        get {
            return self.placeholderString ?? ""
        }
        
        set (text) {
            self.placeholderString = text
        }
    }
}

extension GameViewController: NSControlTextEditingDelegate {
    open func controlTextDidChange(_ notification: Notification) {
        if let textField = notification.object as? TextView {
            guard let node = (self as! GameViewController).gameView.selection?.node else { return }
            
            switch textField.placeholder {
            case "Name":
                node.name = textField.text
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
            gameView.gizmos.forEach {
                $0.position = node.position
            }
        }
    }
}
#endif

#if os(iOS)
extension GameViewController {
    /// This function will set all the required properties, and then provide a preview for the document
    func share(url: URL) {
        self.gameView.documentInteractionController.url = url
        self.gameView.documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        self.gameView.documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        self.gameView.documentInteractionController.presentPreview(animated: true)
    }
    
    /// This function will store your document to some temporary URL and then provide sharing, copying, printing, saving options to the user
    func storeAndShare(withURLString: String) {
        guard let url = URL(string: withURLString) else { return }
        /// START YOUR ACTIVITY INDICATOR HERE
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(response?.suggestedFilename ?? "fileName.png")
            do {
                try data.write(to: tmpURL)
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                /// STOP YOUR ACTIVITY INDICATOR HERE
                self.share(url: tmpURL)
            }
        }.resume()
    }
}

extension GameViewController: UIDocumentInteractionControllerDelegate {
    /// If presenting atop a navigation stack, provide the navigation controller in order to animate in a manner consistent with the rest of the platform
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
            return self
        }
        return navVC
    }
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
#endif

