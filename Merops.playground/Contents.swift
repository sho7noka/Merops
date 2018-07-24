///*:
// # Merops playground
// * Build the target "ShaderView" against "My Mac" as below. Please note that it doesn't work on iOS Simulator becase of the limitation of Metal.
// ![Target](target.png)
// * Progam your own shader function in `playgroundSample` in MSLPlayground.metal. You can also add your own metal file or metal function. In that case, change the name of the resource file to load the `MTLLibrary` or `funcationName` to set on the `ShaderViewRenderer`.
// 
// ## memo
// - MetalEzLoader の復元
// 
// #### memo
// device と MTLVertexDescriptor と MTKView
// 
// MTKView から取れるのは
// - view.currentDrawable
// - view.currentRenderPassDescriptor
// - view.colorPixelFormat / sampleCount
// */
//
//import Metal
//import SceneKit
//import SpriteKit
//import PlaygroundSupport
//
//
//class GameScene: SCNScene {
//    
//    private var label : SKLabelNode!
//    private var spinnyNode : SKShapeNode!
//    
//    override func didMove(to view: SKView) {
//        // Get label node from scene and store it for use later
//        label = childNode(withName: "//helloLabel") as? SKLabelNode
//        label.alpha = 0.0
//        let fadeInOut = SKAction.sequence([.fadeIn(withDuration: 2.0),
//                                           .fadeOut(withDuration: 2.0)])
//        label.run(.repeatForever(fadeInOut))
//        
//        // Create shape node to use during mouse interaction
//        let w = (size.width + size.height) * 0.05
//        
//        spinnyNode = SKShapeNode(rectOf: CGSize(width: w, height: w), cornerRadius: w * 0.3)
//        spinnyNode.lineWidth = 2.5
//        
//        let fadeAndRemove = SKAction.sequence([.wait(forDuration: 0.5),
//                                               .fadeOut(withDuration: 0.5),
//                                               .removeFromParent()])
//        spinnyNode.run(.repeatForever(.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
//        spinnyNode.run(fadeAndRemove)
//    }
//    
//    func touchDown(atPoint pos : CGPoint) {
//        guard let n = spinnyNode.copy() as? SKShapeNode else { return }
//        
//        n.position = pos
//        n.strokeColor = SKColor.green
////        addChild(n)
//    }
//    
//    func touchMoved(toPoint pos : CGPoint) {
//        guard let n = self.spinnyNode.copy() as? SKShapeNode else { return }
//        
//        n.position = pos
//        n.strokeColor = SKColor.blue
////        addChild(n)
//    }
//    
//    func touchUp(atPoint pos : CGPoint) {
//        guard let n = spinnyNode.copy() as? SKShapeNode else { return }
//        
//        n.position = pos
//        n.strokeColor = SKColor.red
////        addChild(n)
//    }
//    
//    override func mouseDown(with event: NSEvent) {
////        touchDown(atPoint: event.location(in: self))
//    }
//    
//    override func mouseDragged(with event: NSEvent) {
////        touchMoved(toPoint: event.location(in: self))
//    }
//    
//    override func mouseUp(with event: NSEvent) {
////        touchUp(atPoint: event.location(in: self))
//    }
//    
//    override func update(_ currentTime: TimeInterval) {
//        // Called before each frame is rendered
//    }
//}
//
//// Load the SKScene from 'GameScene.sks'
//let sceneView = SCNView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
//if let scene = GameScene() {
//    // Set the scale mode to scale to fit the window
//    scene.scaleMode = .aspectFill
//    
//    // Present the scene
//    sceneView.scene = scene
//    sceneView.presentScene(scene)
//}
//
//PlaygroundSupport.PlaygroundPage.current.liveView = sceneView

import CreateMLUI
let builder = MLImageClassifierBuilder()
builder.showInLiveView()
