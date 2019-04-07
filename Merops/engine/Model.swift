//
// Created by sumioka-air on 2018/05/02.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import Foundation
import SceneKit
import Metal
import MetalKit

struct Attribute {
    var name : String
    var index : Int
}

@objcMembers
class Models {

    private var models: [SCNNode] = []

    func copyModels() {
        models.removeAll()
//        var tmp: [SCNNode] = []
//        gameView.scene?.rootNode.enumerateChildNodes({ child, _ in
//            if child.geometry != nil && child.categoryBitMask != 2 {
//                tmp.append(child.clone())
//            }
//        })
//        models = tmp
    }

    func setModels() {
        models.removeAll()

//        var tmp: [SCNNode] = []
//        gameView.scene?.rootNode.enumerateChildNodes({ child, _ in
//            if child.geometry != nil && child.categoryBitMask != 2 {
//                tmp.append(child.clone())
//                child.removeFromParentNode()
//            }
//        })
//        models = tmp
    }

    func getModels() {
//        models.forEach {
//            gameView.scene?.rootNode.addChildNode($0)
//        }
        models.removeAll()
    }
}

func duplicateNode(_ node: SCNNode) -> SCNNode {
    let nodeCopy = node.copy() as? SCNNode ?? SCNNode()
    if let geometry = node.geometry?.copy() as? SCNGeometry {
        nodeCopy.geometry = geometry
        if let material = geometry.firstMaterial?.copy() as? SCNMaterial {
            nodeCopy.geometry?.firstMaterial = material
        }
    }
    return nodeCopy
}

func setOutline (outlineNode : SCNNode) {
    let outlineProgram = SCNProgram()
    outlineProgram.vertexFunctionName = "outline_vertex"
    outlineProgram.fragmentFunctionName = "outline_fragment"
    outlineNode.geometry?.firstMaterial?.program = outlineProgram
    outlineNode.geometry?.firstMaterial?.cullMode = .front
}

func getMat(textureFilename: String, ureps: SCNFloat = 1.0, vreps: SCNFloat = 1.0, directory: String? = nil,
            normalFilename: String? = nil, specularFilename: String? = nil) -> SCNMaterial {
    let nsb = Bundle.main.path(forResource: textureFilename, ofType: nil, inDirectory: directory)
    let im = Image(contentsOfFile: nsb!)

    let mat = SCNMaterial()
    mat.diffuse.contents = im

    if (normalFilename != nil) {
        mat.normal.contents = Image(contentsOfFile: Bundle.main.path(
                forResource: normalFilename, ofType: nil, inDirectory: directory)!
        )
    }

    if (specularFilename != nil) {
        mat.specular.contents = Image(contentsOfFile: Bundle.main.path(
                forResource: specularFilename, ofType: nil, inDirectory: directory)!
        )
    }

    repeatMat(mat: mat, wRepeat: ureps, hRepeat: vreps)
    return mat
}

func repeatMat(mat: SCNMaterial, wRepeat: SCNFloat, hRepeat: SCNFloat) {

    mat.diffuse.contentsTransform = SCNMatrix4MakeScale(wRepeat, hRepeat, 1.0)
    mat.diffuse.wrapS = .repeat
    mat.diffuse.wrapT = .repeat

    mat.normal.wrapS = .repeat
    mat.normal.wrapT = .repeat

    mat.specular.wrapS = .repeat
    mat.specular.wrapT = .repeat
}

func getNormal(v0: SCNVector3, v1: SCNVector3, v2: SCNVector3) -> SCNVector3 {

    // there are three edges defined by these 3 vertices, but we only need 2 to define the plane
    let edgev0v1 = v1 - v0, edgev1v2 = v2 - v1

    // Assume the verts are expressed in counter-clockwise order to determine normal
    return edgev0v1.cross(vector: edgev1v2)
}

class HalfEdgeStructure {
    static func loadMesh(device: MTLDevice, name modelName: String, needAddNomal: Bool = false) -> MTKMesh {
        let mtlVertex = MTLVertexDescriptor()
        mtlVertex.attributes[0].format = .float3
        mtlVertex.attributes[0].offset = 0
        mtlVertex.attributes[0].bufferIndex = 0
        mtlVertex.attributes[1].format = .float3
        mtlVertex.attributes[1].offset = 12
        mtlVertex.attributes[1].bufferIndex = 0
        mtlVertex.attributes[2].format = .float2
        mtlVertex.attributes[2].offset = 24
        mtlVertex.attributes[2].bufferIndex = 0
        mtlVertex.layouts[0].stride = 32
        mtlVertex.layouts[0].stepRate = 1
        
        let modelDescriptor3D = MTKModelIOVertexDescriptorFromMetal(mtlVertex)    //use only Load obj
        (modelDescriptor3D.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (modelDescriptor3D.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (modelDescriptor3D.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        let allocator = MTKMeshBufferAllocator(device: device)  //use only Load obj
        let asset = MDLAsset(url: URL(string: modelName),
                             vertexDescriptor: modelDescriptor3D,
                             bufferAllocator: allocator)
        let newMesh = try! MTKMesh.newMeshes(asset: asset, device: device)
        return newMesh.metalKitMeshes.first!
    }
    
    static func LoadModel(device: MTLDevice, name: String, reduction: Int) -> Model {
        let model = Model()
        
        // TODO: loadMesh の解決
        let bodyVtx = loadMesh(device: device, name: name).vertexBuffers[0].buffer
        let pOriBuffer = bodyVtx.contents().assumingMemoryBound(to: MeshPoint.self)
        let vertexCount: Int = bodyVtx.length / MemoryLayout<MeshPoint>.size
        
        for i in 0..<(vertexCount / 3) {
            let v0 = pOriBuffer.advanced(by: i * 3 + 0).pointee.point
            var v1 = pOriBuffer.advanced(by: i * 3 + 1).pointee.point
            var v2 = pOriBuffer.advanced(by: i * 3 + 2).pointee.point
            let mynm = cross(
                float3(mFloat(v1.x - v0.x), mFloat(v1.y - v0.y), mFloat(v1.z - v0.z)), float3(mFloat(v2.x - v0.x), mFloat(v2.y - v0.y), mFloat(v2.z - v0.z))
            )
            let ptnm = pOriBuffer.advanced(by: i * 3 + 0).pointee.normal
            let asnm = dot(float3(mFloat(ptnm.x), mFloat(ptnm.y), mFloat(ptnm.z)), mynm)
            if asnm < 0 {
                let myv = v1
                v1 = v2
                v2 = myv
            }
            model.addPolygon(vertex0: float3(mFloat(v0.x), mFloat(v0.y), mFloat(v0.z)),
                             vertex1: float3(mFloat(v1.x), mFloat(v1.y), mFloat(v1.z)),
                             vertex2: float3(mFloat(v2.x), mFloat(v2.y), mFloat(v2.z)))
        }
        model.updateQuadraticErrorMetricsAll()
        model.polygonReduction(count: reduction)
        return model
    }
    
    func loadTexture(name textureName:String, device: MTLDevice, type:String) -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: device)
        let newTexture =
            try? textureLoader.newTexture(URL: Bundle.main.url(forResource: textureName, withExtension: type)!, options: nil)
        return newTexture!
    }
    
    func makeFrameUniformBuffer(device: MTLDevice) -> MTLBuffer {
        let bff = device.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])
        return bff!
    }
}

func loadAnim(baseNode: SCNNode) {
    let url = Bundle.main.url(forResource: "art.scnassets/boss_attack", withExtension: "dae")
    let sceneSource = SCNSceneSource(url: url!, options: [
        SCNSceneSource.LoadingOption.animationImportPolicy: SCNSceneSource.AnimationImportPolicy.doNotPlay
        ])
    
    let attackAnimation: CAAnimation = sceneSource!.entryWithIdentifier(
        "attackID", withClass: CAAnimation.self
        )!
    attackAnimation.fadeInDuration = 0.3
    attackAnimation.fadeOutDuration = 0.3
    
    baseNode.addAnimation(attackAnimation, forKey: "attackID")
}

func animMopher() {
    let scene = SCNScene()
    let o1 = scene.rootNode.childNode(withName: "o", recursively: true)!
    
    let a2 = CABasicAnimation.init(keyPath: "morpher.weights[0]")
    a2.fromValue = 0.0
    a2.toValue = 1.0
    a2.duration = 0.5
    a2.beginTime = 1.0
    a2.autoreverses = true
    a2.repeatCount = .infinity
    
    o1.addAnimation(a2, forKey: nil)
}

func keyMorpher() {
    let scene = SCNScene()
    let o1 = scene.rootNode.childNode(withName: "o", recursively: false)!
    o1.morpher?.setWeight(1.0, forTargetAt: 0)
}

func ikconstraint(shoulderNode: SCNNode, handNode: SCNNode) {
    let ik: SCNIKConstraint = SCNIKConstraint.inverseKinematicsConstraint(
        chainRootNode: shoulderNode
    )
    handNode.constraints = [ik]
    ik.targetPosition = SCNVector3(2, 0, 2)
}
