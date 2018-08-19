//
//  interpolate.swift
//  Merops
//
//  Created by sho sumioka on 2018/08/19.
//  Copyright © 2018 sho sumioka. All rights reserved.
// https://developer.apple.com/documentation/accelerate/simd/rotating_a_cube_by_transforming_its_vertices

import Cocoa
import simd
import SceneKit
import QuartzCore

class ViewController: SuperViewController {
    
    enum DemoMode: String {
        case simpleRotation = "Simple"
        case compositeRotation = "Composite"
        case sphericalInterpolate = "Spherical"
        case splineInterpolate = "Spline"
        case splineRotationIn3D = "Cube: spline"
        case slerpRotationIn3D = "Cube: slerp"
    }
    
    var mode: DemoMode = .simpleRotation {
        didSet {
            switchDemo()
        }
    }
    
    @IBOutlet var sceneKitView: SCNView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    let defaultColor = Color.orange
    
    let modeSegmentedControlItem: UIBarButtonItem = {
        let segmentedControl = UISegmentedControl(items: [DemoMode.simpleRotation.rawValue,
                                                          DemoMode.compositeRotation.rawValue,
                                                          DemoMode.sphericalInterpolate.rawValue,
                                                          DemoMode.splineInterpolate.rawValue,
                                                          DemoMode.slerpRotationIn3D.rawValue,
                                                          DemoMode.splineRotationIn3D.rawValue])
        
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.addTarget(self,
                                   action: #selector(modeSegmentedControlChangeHandler),
                                   for: .valueChanged)
        
        return UIBarButtonItem(customView: segmentedControl)
    }()
    
    lazy var scene = setupSceneKit()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.setItems([modeSegmentedControlItem,
                          UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                          UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play,
                                          target: self,
                                          action: #selector(runButtonTouchHandler))],
                         animated: false)
        
        switchDemo()
    }
    
    func switchDemo() {
        scene = setupSceneKit()
        isRunning = false
        displaylink?.invalidate()
        
        switch mode {
        case .simpleRotation:
            simpleRotation()
        case .compositeRotation:
            compositeRotation()
        case .sphericalInterpolate:
            sphericalInterpolate()
        case .splineInterpolate:
            splineInterpolate()
        case .splineRotationIn3D:
            vertexRotation(useSpline: true)
        case .slerpRotationIn3D:
            vertexRotation(useSpline: false)
        }
    }
    
    @objc
    func runButtonTouchHandler() {
        switchDemo()
        isRunning = true
    }
    
    @objc
    func modeSegmentedControlChangeHandler(segmentedControl: UISegmentedControl) {
        guard
            let newModeName = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex),
            let newMode = DemoMode(rawValue: newModeName) else {
                return
        }
        
        mode = newMode
    }
    
    var isRunning: Bool = false {
        didSet {
            toolbar.isUserInteractionEnabled = !isRunning
            toolbar.alpha = isRunning ? 0.5 : 1
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            SCNTransaction.commit()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .bottom
    }
    
    // MARK: Demos
    
    var displaylink: CADisplayLink?
    
    // MARK: Simple Rotation Demo
    
    var angle: Float = 0
    let originVector = simd_float3(0, 0, 1)
    var previousSphere: SCNNode?
    
    func simpleRotation() {
        addMainSphere(scene: scene)
        
        angle = 0
        previousSphere = nil
        
        addSphereAt(position: originVector,
                    radius: 0.04,
                    color: .red,
                    scene: scene)
        
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(simpleRotationStep))
        
        displaylink?.add(to: .current,
                         forMode: .defaultRunLoopMode)
    }
    
    @objc
    func simpleRotationStep(displaylink: CADisplayLink) {
        guard isRunning else {
            return
        }
        
        previousSphere?.removeFromParentNode()
        
        angle -= 1
        
        let quaternion = simd_quatf(angle: degreesToRadians(angle),
                                    axis: simd_float3(x: 1,
                                                      y: 0,
                                                      z: 0))
        
        let rotatedVector = quaternion.act(originVector)
        
        previousSphere = addSphereAt(position: rotatedVector,
                                     radius: 0.04,
                                     color: defaultColor,
                                     scene: scene)
        
        if angle < -60 {
            displaylink.invalidate()
            isRunning = false
        }
    }
    
    // MARK: Composite Rotation Demo
    
    // `previousSphereA` and `previousSphereB` show component quaternions
    var previousSphereA: SCNNode?
    var previousSphereB: SCNNode?
    
    func compositeRotation() {
        addMainSphere(scene: scene)
        
        angle = 0
        previousSphere = nil
        previousSphereA = nil
        previousSphereB = nil
        
        addSphereAt(position: originVector,
                    radius: 0.04,
                    color: .red,
                    scene: scene)
        
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(compositeRotationStep))
        
        displaylink?.add(to: .current,
                         forMode: .defaultRunLoopMode)
    }
    
    @objc
    func compositeRotationStep(displaylink: CADisplayLink) {
        guard isRunning else {
            return
        }
        
        previousSphere?.removeFromParentNode()
        previousSphereA?.removeFromParentNode()
        previousSphereB?.removeFromParentNode()
        
        angle -= 1
        
        let quaternionA = simd_quatf(angle: degreesToRadians(angle),
                                     axis: simd_float3(x: 1,
                                                       y: 0,
                                                       z: 0))
        
        let quaternionB = simd_quatf(angle: degreesToRadians(angle),
                                     axis: simd_normalize(simd_float3(x: 0,
                                                                      y: -0.75,
                                                                      z: -0.5)))
        
        let rotatedVectorA = quaternionA.act(originVector)
        previousSphereA = addSphereAt(position: rotatedVectorA,
                                      radius: 0.02,
                                      color: .green,
                                      scene: scene)
        
        let rotatedVectorB = quaternionB.act(originVector)
        previousSphereB = addSphereAt(position: rotatedVectorB,
                                      radius: 0.02,
                                      color: .red,
                                      scene: scene)
        
        let quaternion = quaternionA * quaternionB
        
        let rotatedVector = quaternion.act(originVector)
        
        previousSphere = addSphereAt(position: rotatedVector,
                                     radius: 0.04,
                                     color: defaultColor,
                                     scene: scene)
        
        if angle <= -360 {
            displaylink.invalidate()
            isRunning = false
        }
    }
    
    // MARK: Spherical Interpolate Demo
    
    var sphericalInterpolateTime: Float = 0
    
    let origin = simd_float3(0, 0, 1)
    
    let q0 = simd_quatf(angle: .pi / 6,
                        axis: simd_float3(x: 0,
                                          y: -1,
                                          z: 0))
    
    let q1 = simd_quatf(angle: .pi / 6,
                        axis: simd_normalize(simd_float3(x: -1,
                                                         y: 1,
                                                         z: 0)))
    
    let q2 = simd_quatf(angle: .pi / 20,
                        axis: simd_normalize(simd_float3(x: 1,
                                                         y: 0,
                                                         z: -1)))
    
    func sphericalInterpolate() {
        addMainSphere(scene: scene)
        
        sphericalInterpolateTime = 0
        
        let u0 = simd_act(q0, origin)
        let u1 = simd_act(q1, origin)
        let u2 = simd_act(q2, origin)
        
        for u in [u0, u1, u2] {
            addSphereAt(position: u,
                        radius: 0.04,
                        color: defaultColor,
                        scene: scene)
        }
        
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(sphericalInterpolateStep))
        
        displaylink?.add(to: .current,
                         forMode: .defaultRunLoopMode)
        
        previousShortestInterpolationPoint = nil
        previousLongestInterpolationPoint = nil
        
    }
    
    var previousShortestInterpolationPoint: simd_float3?
    var previousLongestInterpolationPoint: simd_float3?
    
    @objc
    func sphericalInterpolateStep(displaylink: CADisplayLink) {
        guard isRunning else {
            return
        }
        
        let increment: Float = 0.005
        sphericalInterpolateTime += increment
        
        // simd_slerp
        do {
            let q = simd_slerp(q0, q1, sphericalInterpolateTime)
            let interpolationPoint = simd_act(q, origin)
            if let previousShortestInterpolationPoint = previousShortestInterpolationPoint {
                addLineBetweenVertices(vertexA: previousShortestInterpolationPoint,
                                       vertexB: interpolationPoint,
                                       inScene: scene)
            }
            previousShortestInterpolationPoint = interpolationPoint
        }
        
        // simd_slerp_longest
        do {
            for t in [sphericalInterpolateTime,
                      sphericalInterpolateTime + increment * 0.5] {
                        let q = simd_slerp_longest(q1, q2, t)
                        let interpolationPoint = simd_act(q, origin)
                        if let previousLongestInterpolationPoint = previousLongestInterpolationPoint {
                            addLineBetweenVertices(vertexA: previousLongestInterpolationPoint,
                                                   vertexB: interpolationPoint,
                                                   inScene: scene)
                        }
                        previousLongestInterpolationPoint = interpolationPoint
            }
        }
        
        if !(sphericalInterpolateTime < 1) {
            displaylink.invalidate()
            isRunning = false
        }
    }
    
    // MARK: Spline Interpolate Demo
    
    var splineInterpolateTime: Float = 0
    var rotations = [simd_quatf]()
    var markers = [SCNNode]()
    
    var index = 0 {
        didSet {
            if !markers.isEmpty {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                if oldValue < markers.count {
                    markers[oldValue].geometry?.firstMaterial?.diffuse.contents = defaultColor
                }
                if index < markers.count {
                    markers[index].geometry?.firstMaterial?.diffuse.contents = Color.yellow
                }
                SCNTransaction.commit()
            }
        }
    }
    
    func splineInterpolate() {
        rotations.removeAll()
        
        let origin = simd_float3(0, 0, 1)
        let q_origin = simd_quatf(angle: 0,
                                  axis: simd_float3(x: 1, y: 0, z: 0))
        
        rotations.append(q_origin)
        
        let markerCount = 12
        markers.removeAll()
        
        for i in 0 ... markerCount {
            let angle = (.pi * 2) / Float(markerCount) * Float(i)
            let latitudeRotation = simd_quatf(angle: (angle - .pi / 2) * 0.3,
                                              axis: simd_normalize(simd_float3(x: 0,
                                                                               y: 1,
                                                                               z: 0)))
            
            let longitudeRotation = simd_quatf(angle: .pi / 4 * .random(in: 0...0.25) * Float(i % 2 == 0 ? -1 : 1),
                                               axis: simd_normalize(simd_float3(x: 1,
                                                                                y: 0,
                                                                                z: 0)))
            
            let q = latitudeRotation * longitudeRotation
            
            let u = simd_act(q, origin)
            
            rotations.append(q)
            
            if  i != markerCount {
                markers.append(addSphereAt(position: u,
                                           radius: 0.01,
                                           color: defaultColor,
                                           scene: scene))
            }
        }
        
        addMainSphere(scene: scene)
        
        splineInterpolateTime = 0
        index = 1
        
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(splineInterpolateStep))
        
        displaylink?.add(to: .current,
                         forMode: .defaultRunLoopMode)
        
        previousSplinePoint = nil
    }
    
    var previousSplinePoint: simd_float3?
    
    @objc
    func splineInterpolateStep(displaylink: CADisplayLink) {
        guard isRunning else {
            return
        }
        
        let increment: Float = 0.04
        splineInterpolateTime += increment
        
        let q = simd_spline(rotations[index - 1],
                            rotations[index],
                            rotations[index + 1],
                            rotations[index + 2],
                            splineInterpolateTime)
        
        let splinePoint = simd_act(q, origin)
        
        if let previousSplinePoint = previousSplinePoint {
            addLineBetweenVertices(vertexA: previousSplinePoint,
                                   vertexB: splinePoint,
                                   inScene: scene)
        }
        
        previousSplinePoint = splinePoint
        
        if !(splineInterpolateTime < 1) {
            index += 1
            splineInterpolateTime = 0
            
            if index > rotations.count - 3 {
                displaylink.invalidate()
                isRunning = false
            }
        }
    }
    
    // MARK: Rotating vertices in 3D
    
    let vertexRotations: [simd_quatf] = [
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))),
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))),
        simd_quatf(angle: .pi * 0.05,
                   axis: simd_normalize(simd_float3(x: 0, y: 1, z: 0))),
        simd_quatf(angle: .pi * 0.1,
                   axis: simd_normalize(simd_float3(x: 1, y: 0, z: -1))),
        simd_quatf(angle: .pi * 0.15,
                   axis: simd_normalize(simd_float3(x: 0, y: 1, z: 0))),
        simd_quatf(angle: .pi * 0.2,
                   axis: simd_normalize(simd_float3(x: -1, y: 0, z: 1))),
        simd_quatf(angle: .pi * 0.15,
                   axis: simd_normalize(simd_float3(x: 0, y: -1, z: 0))),
        simd_quatf(angle: .pi * 0.1,
                   axis: simd_normalize(simd_float3(x: 1, y: 0, z: -1))),
        simd_quatf(angle: .pi * 0.05,
                   axis: simd_normalize(simd_float3(x: 0, y: 1, z: 0))),
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1))),
        simd_quatf(angle: 0,
                   axis: simd_normalize(simd_float3(x: 0, y: 0, z: 1)))
    ]
    
    var vertexRotationUsesSpline = true
    var vertexRotationIndex = 0
    var vertexRotationTime: Float = 0
    var previousCube: SCNNode?
    var previousVertexMarker: SCNNode?
    
    let cubeVertexOrigins: [simd_float3] = [
        simd_float3(x: -0.5, y: -0.5, z: 0.5),
        simd_float3(x: 0.5, y: -0.5, z: 0.5),
        simd_float3(x: -0.5, y: -0.5, z: -0.5),
        simd_float3(x: 0.5, y: -0.5, z: -0.5),
        simd_float3(x: -0.5, y: 0.5, z: 0.5),
        simd_float3(x: 0.5, y: 0.5, z: 0.5),
        simd_float3(x: -0.5, y: 0.5, z: -0.5),
        simd_float3(x: 0.5, y: 0.5, z: -0.5)
    ]
    
    lazy var cubeVertices = cubeVertexOrigins
    
    let sky = MDLSkyCubeTexture(name: "sky",
                                channelEncoding: MDLTextureChannelEncoding.float16,
                                textureDimensions: simd_int2(x: 128, y: 128),
                                turbidity: 0.5,
                                sunElevation: 0.5,
                                sunAzimuth: 0.5,
                                upperAtmosphereScattering: 0.5,
                                groundAlbedo: 0.5)
    
    func vertexRotation(useSpline: Bool) {
        scene.lightingEnvironment.contents = sky
        scene.rootNode.childNode(withName: "cameraNode",
                                 recursively: false)?.camera?.usesOrthographicProjection = false
        
        vertexRotationUsesSpline = useSpline
        
        vertexRotationTime = 0
        vertexRotationIndex = 1
        
        previousCube = addCube(vertices: cubeVertexOrigins,
                               inScene: scene)
        
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(vertexRotationStep))
        
        displaylink?.add(to: .current,
                         forMode: .defaultRunLoopMode)
    }
    
    @objc
    func vertexRotationStep(displaylink: CADisplayLink) {
        guard isRunning else {
            return
        }
        
        previousCube?.removeFromParentNode()
        
        let increment: Float = 0.02
        vertexRotationTime += increment
        
        let q: simd_quatf
        if vertexRotationUsesSpline {
            q = simd_spline(vertexRotations[vertexRotationIndex - 1],
                            vertexRotations[vertexRotationIndex],
                            vertexRotations[vertexRotationIndex + 1],
                            vertexRotations[vertexRotationIndex + 2],
                            vertexRotationTime)
        } else {
            q = simd_slerp(vertexRotations[vertexRotationIndex],
                           vertexRotations[vertexRotationIndex + 1],
                           vertexRotationTime)
        }
        
        previousVertexMarker?.removeFromParentNode()
        let vertex = cubeVertices[5]
        cubeVertices = cubeVertexOrigins.map {
            return q.act($0)
        }
        
        previousVertexMarker = addSphereAt(position: cubeVertices[5],
                                           radius: 0.01,
                                           color: .red,
                                           scene: scene)
        
        addLineBetweenVertices(vertexA: vertex,
                               vertexB: cubeVertices[5],
                               inScene: scene,
                               color: .white)
        
        previousCube = addCube(vertices: cubeVertices,
                               inScene: scene)
        
        if vertexRotationTime >= 1 {
            vertexRotationIndex += 1
            vertexRotationTime = 0
            
            if vertexRotationIndex > vertexRotations.count - 3 {
                displaylink.invalidate()
                isRunning = false
            }
        }
    }
}

extension ViewController {
    func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * .pi / 180
    }
    
    func setupSceneKit(shadows: Bool = true) -> SCNScene {
        sceneKitView.allowsCameraControl = false
        
        let scene = SCNScene()
        sceneKitView.scene = scene
        
        scene.background.contents = Color(red: 41 / 255,
                                            green: 42 / 255,
                                            blue: 48 / 255,
                                            alpha: 1)
        
        let lookAtNode = SCNNode()
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.name = "cameraNode"
        cameraNode.camera = camera
        camera.fieldOfView = 25
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.5
        cameraNode.position = SCNVector3(x: 2.5, y: 2.0, z: 5.0)
        let lookAt = SCNLookAtConstraint(target: lookAtNode)
        lookAt.isGimbalLockEnabled = true
        cameraNode.constraints = [ lookAt ]
        
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: -1.5, y: 2.5, z: 1.5)
        
        if shadows {
            light.type = .directional
            light.castsShadow = true
            light.shadowSampleCount = 8
            lightNode.constraints = [ lookAt ]
        }
        
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = Color(white: 0.5, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        
        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ambientNode)
        
        addAxisArrows(scene: scene)
        
        return scene
    }
    
    func addLineBetweenVertices(vertexA: simd_float3,
                                vertexB: simd_float3,
                                inScene scene: SCNScene,
                                useSpheres: Bool = false,
                                color: Color = .yellow) {
        if useSpheres {
            addSphereAt(position: vertexB,
                        radius: 0.01,
                        color: .red,
                        scene: scene)
        } else {
            let geometrySource = SCNGeometrySource(vertices: [SCNVector3(x: vertexA.x,
                                                                         y: vertexA.y,
                                                                         z: vertexA.z),
                                                              SCNVector3(x: vertexB.x,
                                                                         y: vertexB.y,
                                                                         z: vertexB.z)])
            let indices: [Int8] = [0, 1]
            let indexData = Data(bytes: indices, count: 2)
            let element = SCNGeometryElement(data: indexData,
                                             primitiveType: .line,
                                             primitiveCount: 1,
                                             bytesPerIndex: MemoryLayout<Int8>.size)
            
            let geometry = SCNGeometry(sources: [geometrySource],
                                       elements: [element])
            
            geometry.firstMaterial?.isDoubleSided = true
            geometry.firstMaterial?.emission.contents = color
            
            let node = SCNNode(geometry: geometry)
            
            scene.rootNode.addChildNode(node)
        }
    }
    
    @discardableResult
    func addTriangle(vertices: [simd_float3], inScene scene: SCNScene) -> SCNNode {
        assert(vertices.count == 3, "vertices count must be 3")
        
        let vector1 = vertices[2] - vertices[1]
        let vector2 = vertices[0] - vertices[1]
        let normal = simd_normalize(simd_cross(vector1, vector2))
        
        let normalSource = SCNGeometrySource(normals: [SCNVector3(x: normal.x, y: normal.y, z: normal.z),
                                                       SCNVector3(x: normal.x, y: normal.y, z: normal.z),
                                                       SCNVector3(x: normal.x, y: normal.y, z: normal.z)])
        
        let sceneKitVertices = vertices.map {
            return SCNVector3(x: $0.x, y: $0.y, z: $0.z)
        }
        let geometrySource = SCNGeometrySource(vertices: sceneKitVertices)
        
        let indices: [Int8] = [0, 1, 2]
        let indexData = Data(bytes: indices, count: 3)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: 1,
                                         bytesPerIndex: MemoryLayout<Int8>.size)
        
        let geometry = SCNGeometry(sources: [geometrySource, normalSource],
                                   elements: [element])
        
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.diffuse.contents = Color.orange
        
        let node = SCNNode(geometry: geometry)
        
        scene.rootNode.addChildNode(node)
        
        return node
    }
    
    func addCube(vertices: [simd_float3], inScene scene: SCNScene) -> SCNNode {
        assert(vertices.count == 8, "vertices count must be 3")
        
        let sceneKitVertices = vertices.map {
            return SCNVector3(x: $0.x, y: $0.y, z: $0.z)
        }
        let geometrySource = SCNGeometrySource(vertices: sceneKitVertices)
        
        let indices: [Int8] = [
            // bottom
            0, 2, 1,
            1, 2, 3,
            // back
            2, 6, 3,
            3, 6, 7,
            // left
            0, 4, 2,
            2, 4, 6,
            // right
            1, 3, 5,
            3, 7, 5,
            // front
            0, 1, 4,
            1, 5, 4,
            // top
            4, 5, 6,
            5, 7, 6 ]
        
        let indexData = Data(bytes: indices, count: indices.count)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: 12,
                                         bytesPerIndex: MemoryLayout<Int8>.size)
        
        let geometry = SCNGeometry(sources: [geometrySource],
                                   elements: [element])
        
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.diffuse.contents = Color.purple
        geometry.firstMaterial?.lightingModel = .physicallyBased
        
        let node = SCNNode(geometry: geometry)
        
        scene.rootNode.addChildNode(node)
        
        return node
    }
    
    func addAxisArrows(scene: SCNScene) {
        let xArrow = arrow(color: Color.red)
        xArrow.simdEulerAngles = simd_float3(x: 0, y: 0, z: -.pi * 0.5)
        
        let yArrow = arrow(color: Color.green)
        
        let zArrow = arrow(color: Color.blue)
        zArrow.simdEulerAngles = simd_float3(x: .pi * 0.5, y: 0, z: 0)
        
        let node = SCNNode()
        node.addChildNode(xArrow)
        node.addChildNode(yArrow)
        node.addChildNode(zArrow)
        
        node.simdPosition = simd_float3(x: -1.5, y: -1.25, z: 0.0)
        
        scene.rootNode.addChildNode(node)
    }
    
    func arrow(color: Color) -> SCNNode {
        let cylinder = SCNCylinder(radius: 0.01, height: 0.5)
        cylinder.firstMaterial?.diffuse.contents = color
        let cylinderNode = SCNNode(geometry: cylinder)
        
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.03, height: 0.1)
        cone.firstMaterial?.diffuse.contents = color
        let coneNode = SCNNode(geometry: cone)
        
        coneNode.simdPosition = simd_float3(x: 0, y: 0.25, z: 0)
        
        let returnNode = SCNNode()
        returnNode.addChildNode(cylinderNode)
        returnNode.addChildNode(coneNode)
        
        returnNode.pivot = SCNMatrix4MakeTranslation(0, -0.25, 0)
        
        return returnNode
    }
    
    @discardableResult
    func addSphereAt(position: simd_float3, radius: CGFloat = 0.1, color: Color, scene: SCNScene) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.simdPosition = position
        scene.rootNode.addChildNode(sphereNode)
        
        return sphereNode
    }
    
    func addMainSphere(scene: SCNScene) {
        let sphereRotation = simd_float3(x: degreesToRadians(0), y: 0, z: 0) // was 30
        let sphere = SCNSphere(radius: 1)
        sphere.firstMaterial?.transparency = 0.85
        sphere.firstMaterial?.locksAmbientWithDiffuse = true
        sphere.firstMaterial?.diffuse.contents = Color(red: 0.75, green: 0.5, blue: 0.5, alpha: 1)
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.simdEulerAngles = sphereRotation
        scene.rootNode.addChildNode(sphereNode)
        let wireFrameSphere = SCNSphere(radius: 1)
        wireFrameSphere.firstMaterial?.fillMode = .lines
        wireFrameSphere.firstMaterial?.shininess = 1
        wireFrameSphere.firstMaterial?.diffuse.contents = Color(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        let wireFrameSphereNode = SCNNode(geometry: wireFrameSphere)
        wireFrameSphereNode.simdEulerAngles = sphereRotation
        scene.rootNode.addChildNode(wireFrameSphereNode)
    }
}
