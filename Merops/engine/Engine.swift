//
// Created by sho sumioka on 2018/05/26.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import Metal
import MetalKit
import SceneKit

class MetalRender {
    let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }

    func commandQueue() -> MTLCommandQueue! {
        return self.device.makeCommandQueue()
    }

    func commandBuffer() -> MTLCommandBuffer! {
        let buffer = self.commandQueue().makeCommandBuffer()
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
        renderPipeDescriptor.depthAttachmentPixelFormat = .bgra8Unorm
        renderPipeDescriptor.stencilAttachmentPixelFormat = .bgra8Unorm
        renderPipeDescriptor.tessellationControlPointIndexType = .uint16
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
    var view: SCNView
    
    init (device: MTLDevice, library: MTLLibrary, view: SCNView){
        self.device = device
        self.library = library
        self.view = view
    }
    
    /// - Tag: DrawOverride
    func typeRender(prim: MetalPrimitiveData) {
        switch prim.type {
        case .point:
            setupMetal(node: prim.node, type: .point)
        case .line:
            if prim.vertex.count == 0 {
                prim.node.geometry?.firstMaterial?.fillMode = .lines
            } else {
                setupMetal(node: prim.node, type: .line)
            }
        case .triangleStrip:
            setupMetal(node: prim.node, type: .triangleStrip)
        default:
            break
        }
    }
    
    func setupMetal(node: SCNNode, type: MTLPrimitiveType) {
        guard let commandQueue = device?.makeCommandQueue() else {
            fatalError("Could not create a command queue")
        }
        let allocator = MTKMeshBufferAllocator(device: device!)
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        // Mesh
        let mdlMesh = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
            segments: [100, 100],
            inwardNormals: false,
            geometryType: .triangles,
            allocator: allocator)
        do {
            let mesh = try MTKMesh(mesh: mdlMesh, device: device!)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
            let pipelineState = try device?.makeRenderPipelineState(descriptor: descriptor)
            let passDescripter = MTLRenderPassDescriptor()
            
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescripter)
            else {
                fatalError()
            }
            renderEncoder.setRenderPipelineState(pipelineState!)
            renderEncoder.setVertexBuffer(
                mesh.vertexBuffers[0].buffer, offset: 0, index: 0
            )
            
            guard let submesh = mesh.submeshes.first else {
                fatalError()
            }
            renderEncoder.drawIndexedPrimitives(type: type,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer.buffer,
                                                indexBufferOffset: 0)
            renderEncoder.endEncoding()
            
            if let drawable = (view.layer as! CAMetalLayer).nextDrawable() {
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()
        } catch {
            
        }
    }
}
