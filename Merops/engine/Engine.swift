//
// Created by sho sumioka on 2018/05/26.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import Metal
import MetalKit
import SceneKit

/// - Tag: engine
class MetalRender : SCNRenderer {
    
    var library: MTLLibrary {
//        try self.device?.makeLibrary(source: "", options: nil)
        return self.device!.makeDefaultLibrary()!
    }
    
    var vertexFunction: MTLFunction {
        return self.library.makeFunction(name: "vertex_main")!
    }
    
    var fragmentFunction: MTLFunction {
        return self.library.makeFunction(name: "fragment_main")!
    }
    
    var mouseFunction : MTLFunction {
        return self.library.makeFunction(name: "compute")!
    }

    func commandBuffer() -> MTLCommandBuffer! {
        let buffer = self.commandQueue?.makeCommandBuffer()
        buffer!.label = "deform buffer"
        return buffer
    }

    func renderPassDescriptor() -> MTLRenderPassDescriptor {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
        return renderPassDescriptor
    }

    func renderPipelineDescriptor() -> MTLRenderPipelineDescriptor {
        let renderPipeDescriptor = MTLRenderPipelineDescriptor()
//        renderPipeDescriptor.depthAttachmentPixelFormat = .depth16Unorm
//        renderPipeDescriptor.stencilAttachmentPixelFormat = .stecil
//        renderPipeDescriptor.tessellationControlPointIndexType = .uint16
        return renderPipeDescriptor
    }
}

func duplicate(_ node: SCNNode) -> SCNNode {
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

struct MetalPrimitiveData {
    var node: SCNNode
    var type: MTLPrimitiveType
    var vertex: [CGFloat]
}

class MetalPrimitiveHandle {
    var device: MTLDevice?
    var library: MTLLibrary?
    
    var render: MetalRender
    var view: SCNView
    
    init (render: MetalRender, view: SCNView){
        self.device = render.device
        self.library = render.library
        
        self.render = render
        self.view = view
    }
    
    /// - Tag: DrawOverride
    func typeRender(prim: MetalPrimitiveData) {
        Swift.print(prim.vertex)
        switch prim.type {
        case .point:
            metalRender(node: prim.node, type: .point)
            
        case .line:
//            prim.node.geometry?.firstMaterial?.fillMode = .lines
            metalRender(node: prim.node, type: .line)
            
        case .triangleStrip:
            metalRender(node: prim.node, type: .triangleStrip)
            
        default:
            break
        }
    }
    
    func metalRender(node: SCNNode, type: MTLPrimitiveType) {
        //        MTKModelIOVertexDescriptorFromMetal
        //        MTKModelIOVertexFormatFromMetal
        guard let commandQueue = device?.makeCommandQueue() else {
            fatalError("Could not create a command queue")
        }
        let allocator = MTKMeshBufferAllocator(device: device!)
        
        // Mesh
//        let mdlMesh = MDLMesh(scnNode: node, bufferAllocator: allocator)
        let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
            segments: [100, 100],
            inwardNormals: false,
            geometryType: .triangles,
            allocator: allocator)

        
        do {
            let mesh = try MTKMesh(mesh: mdlMesh, device: device!)
            guard let submesh = mesh.submeshes.first,
                let drawable = (view.layer as! CAMetalLayer).nextDrawable()
            else {
                return
            }
            
            // descriptor
            let descriptor = render.renderPipelineDescriptor()
            let passDescripter = render.renderPassDescriptor()
            
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
            descriptor.vertexFunction = render.vertexFunction
            descriptor.fragmentFunction = render.fragmentFunction
            descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
            passDescripter.colorAttachments[0].texture = drawable.texture
            
            // buffer & renderEncoder
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescripter)
            else {
                fatalError()
            }
            commandBuffer.pushDebugGroup("Override encoder")
            let pipelineState = try device!.makeRenderPipelineState(descriptor: descriptor)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(type: type,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer.buffer,
                                                indexBufferOffset: 0)
            renderEncoder.setTriangleFillMode(.lines)
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            commandBuffer.popDebugGroup()
            
        } catch {
            Swift.print("Error info: \(error)")
        }
    }
}

extension MTLBuffer {
//    func drawBlockInSafeContext(block: (context: CGContext?) -> ()) {
//        let context = UIGraphicsGetCurrentContext()
//        CGContextSaveGState(context)
//        block(context: context)
//        CGContextRestoreGState(context)
//    }
}

func getNormal(v0: SCNVector3, v1: SCNVector3, v2: SCNVector3) -> SCNVector3 {
    
    // there are three edges defined by these 3 vertices, but we only need 2 to define the plane
    let edgev0v1 = v1 - v0, edgev1v2 = v2 - v1
    
    // Assume the verts are expressed in counter-clockwise order to determine normal
    return edgev0v1.cross(vector: edgev1v2)
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
