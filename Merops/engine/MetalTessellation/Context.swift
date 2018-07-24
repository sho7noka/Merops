//
//  Context.swift
//

import Foundation
import MetalKit
import simd


protocol MetalEzClassDelegate {
    func update()
    func draw(type: MetalEzRenderingEngine.RendererType)
}

class MetalEz: NSObject, MTKViewDelegate {
    var delegate: MetalEzClassDelegate?
    var mtkView: MTKView!
    var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var depthStencilState: MTLDepthStencilState!
    private var depthStencilStateForBlending: MTLDepthStencilState!
    private let semaphore = DispatchSemaphore(value: 1)
    private var mtlRenderPipelineStateArray = [(MetalEzRenderingEngine.RendererType, MTLRenderPipelineState)]()
    private var mtlRenderPipelineStateArrayForBlending = [(MetalEzRenderingEngine.RendererType, MTLRenderPipelineState)]()

    var mtlRenderCommandEncoder: MTLRenderCommandEncoder!
    var cameraMatrix = matrix_identity_float4x4 //use by drawers, camera matrix update by look at
    var projectionMatrix = matrix_float4x4()    //use by drawers
    var mtlEzRenderingEngineArray = [MetalEzRenderingEngine]()
    var mesh: MetalEzMmeshRenderer!
    var loader: MetalEzLoader!
    var explosionEmitter: MetalEzExplosionRenderer!
    var line: MetalEzLineRenderer!

    func setupMetal(mtkView view: MTKView) {
        mtkView = view
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()

        mtkView.sampleCount = 4
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0)
        mtkView.device = device
        mtkView.delegate = self

        projectionMatrix = Matrix.perspective(toRad(fromDeg: 75),
                aspectRatio: Float(mtkView.drawableSize.width / mtkView.drawableSize.height),
                zFar: 255,
                zNear: 0.1)

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)

        let depthDescriptorForBlending = MTLDepthStencilDescriptor()
        depthDescriptorForBlending.depthCompareFunction = .less
        depthDescriptorForBlending.isDepthWriteEnabled = false
        depthStencilStateForBlending = device.makeDepthStencilState(descriptor: depthDescriptorForBlending)

        var mtlRenderPipelineStateDictionary = Dictionary<MetalEzRenderingEngine.RendererType, MTLRenderPipelineState>()

        loader = MetalEzLoader(MetalEz: self)
        mesh = MetalEzMmeshRenderer(MetalEz: self, pipelineDic: &mtlRenderPipelineStateDictionary)
        explosionEmitter = MetalEzExplosionRenderer(MetalEz: self, pipelineDic: &mtlRenderPipelineStateDictionary)
        line = MetalEzLineRenderer(MetalEz: self, pipelineDic: &mtlRenderPipelineStateDictionary)

        for (key, val) in mtlRenderPipelineStateDictionary {
            if val.label != nil {
                if (val.label?.contains(MetalEzRenderingEngine.blendingIsEnabled))! {
                    mtlRenderPipelineStateArrayForBlending.append((key, val))
                } else {
                    mtlRenderPipelineStateArray.append((key, val))
                }
            } else {
                mtlRenderPipelineStateArray.append((key, val))
            }
        }
    }

    func lookAt(from: float3, direction: float3, up: float3) {
        cameraMatrix = Matrix.lookAt(from: from, direction: direction, up: up)
    }

    func draw(in view: MTKView) {
        self.delegate?.update()
        autoreleasepool {
            semaphore.wait()
            let commandBuffer = commandQueue.makeCommandBuffer()
            mtlRenderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)
            mtlRenderCommandEncoder.pushDebugGroup("Render Object")
            mtlRenderCommandEncoder.setDepthStencilState(depthStencilState)

            mtlRenderPipelineStateArray.forEach { (key, val) in
                mtlRenderCommandEncoder.setRenderPipelineState(val)
                self.delegate?.draw(type: key)
            }
            mtlRenderCommandEncoder.setDepthStencilState(depthStencilStateForBlending)
            mtlRenderPipelineStateArrayForBlending.forEach { (key, val) in
                mtlRenderCommandEncoder.setRenderPipelineState(val)
                self.delegate?.draw(type: key)
            }

            mtlRenderCommandEncoder.popDebugGroup()
            mtlRenderCommandEncoder.endEncoding()
            commandBuffer?.present(view.currentDrawable!)
            commandBuffer?.addCompletedHandler { _ in
                self.semaphore.signal()
            }
            commandBuffer?.commit()
        }
    }
}

extension MetalEz {
    class MeshDrawer {
        private var mesh: MTKMesh
        private var texture: MTLTexture
        var frameUniformBuffer: MTLBuffer
        private weak var mtlEz: MetalEz!
        var hidden: Bool = false

        init(mtlEz m: MetalEz, mesh v: MTKMesh, texture t: MTLTexture) {
            mtlEz = m
            mesh = v
            texture = t
            frameUniformBuffer = mtlEz.device.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])!
        }

        func set(modelMatrix: matrix_float4x4) {
            let p = frameUniformBuffer.contents().assumingMemoryBound(to: FrameUniforms.self)
            let viewModelMatrix = matrix_multiply(mtlEz.cameraMatrix, modelMatrix)
            p.pointee.projectionViewMatrinx = matrix_multiply(mtlEz.projectionMatrix, viewModelMatrix)
            let mat3 = Matrix.toUpperLeft3x3(from4x4: viewModelMatrix)
            p.pointee.normalMatrinx = mat3.transpose.inverse
        }

        func draw() {
            if hidden == true {
                return
            }
            mtlEz.mtlRenderCommandEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)   //do each model
            mtlEz.mtlRenderCommandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1) //do each model
            mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texture, index: 0)    //do each model
            mtlEz.mtlRenderCommandEncoder.drawIndexedPrimitives(type: mesh.submeshes[0].primitiveType,
                    indexCount: mesh.submeshes[0].indexCount,
                    indexType: mesh.submeshes[0].indexType,
                    indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                    indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)   //do each model
        }
    }
}
