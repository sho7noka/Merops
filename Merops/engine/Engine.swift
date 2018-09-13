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


struct MetalPrimitiveData {
    var node: SCNNode
    var type: MTLPrimitiveType
    var vertex: [Float]
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
    
//    commandBuffer?.commit()
//    commandBuffer?.popDebugGroup()
}
