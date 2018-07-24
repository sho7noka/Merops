//
//  Renderer.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/28.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Foundation
import MetalKit
import simd




class Renderer: NSObject, MTKViewDelegate {
    struct Vertex {
        let position: float3
        let normal: float3
        let texcoord: float2

        static func vertexDescriptor() -> MTLVertexDescriptor {
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float4
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0;
            vertexDescriptor.attributes[1].format = .float3
            vertexDescriptor.attributes[1].offset = 16
            vertexDescriptor.attributes[1].bufferIndex = 0;
            vertexDescriptor.attributes[2].format = .float2
            vertexDescriptor.attributes[2].offset = 28
            vertexDescriptor.attributes[2].bufferIndex = 0;
            vertexDescriptor.layouts[0].stepRate = 1
            vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
            return vertexDescriptor
        }
    }

    enum VertexBufferIndex: Int {
        case vertexData = 0
        case frameUniforms
    }

    struct FrameUniforms {
        var projectionViewMatrix: matrix_float4x4
        var normalMatrix: matrix_float3x3
        var inverseViewMatrix: matrix_float4x4
        var modelMatrix: matrix_float4x4
        var wireColor: float4
    }

    // MARK: Camera
    struct CameraParameter {
        var fovY: Float
        var nearZ: Float
        var farZ: Float
    }

    var camera = CameraParameter(fovY: toRad(fromDegrees: 75), nearZ: 0.1, farZ: 100)
    var projectionMatrix = matrix_float4x4()
    var cameraMatrix = Matrix.lookAt(eye: float3(0, 2, 4), center: float3(), up: float3(0, 1, 0))

    // MARK: Status
    private var lastTime = Date()
    private(set) var deltaTime = TimeInterval(0)
    private(set) var totalTime = TimeInterval(0)
    private(set) var drawTime = TimeInterval(Double.greatestFiniteMagnitude)

    private(set) var totalVertexCount = 0

    var isWireFrame = false
    var wireColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)

    // MARK: Renderer
    private let semaphore = DispatchSemaphore(value: 1)

    private(set) weak var view: MTKView!
    private(set) var device: MTLDevice
    private(set) var commandQueue: MTLCommandQueue
    private(set) var library: MTLLibrary
    private let frameUniformBuffer: MTLBuffer

    var preUpdate: ((Renderer) -> Void)? = nil

    var targets = [RenderObject]()

    init?(view: MTKView) {
        /* Metalの初期設定 */
        self.view = view

        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        guard let library = device.makeDefaultLibrary() else {
            return nil
        }
        self.library = library

        self.frameUniformBuffer = device.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])!

        super.init()

//        view.device = device
//        view.delegate = self
//        projectionMatrix = Matrix.perspective(fovyRadians: camera.fovY,
//                aspect: Float(view.drawableSize.width / view.drawableSize.height),
//                nearZ: camera.nearZ,
//                farZ: camera.farZ)
    }

    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        projectionMatrix = Matrix.perspective(fovyRadians: camera.fovY,
                aspect: Float(size.width / size.height),
                nearZ: camera.nearZ,
                farZ: camera.farZ)
    }

    func draw(in view: MTKView) {
        autoreleasepool {
            semaphore.wait()

            guard let drawable = view.currentDrawable else {
                return
            }
            guard let renderDescriptor = view.currentRenderPassDescriptor else {
                return
            }

            deltaTime = Date().timeIntervalSince(lastTime)
            lastTime = Date()
            totalTime += deltaTime

            let commandBuffer = commandQueue.makeCommandBuffer()
            compute(commandBuffer: commandBuffer!)

            update()

            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderDescriptor)
            render(encoder: renderEncoder!)
            renderEncoder?.endEncoding()
            commandBuffer?.present(drawable)

            commandBuffer?.addCompletedHandler { _ in
                self.drawTime = Date().timeIntervalSince(self.lastTime)
                self.semaphore.signal()
            }

            commandBuffer?.commit()
        }
    }

    // MARK: - private
    private func compute(commandBuffer: MTLCommandBuffer) {
        targets.forEach {
            guard $0.isActive else {
                return
            }
            $0.compute(renderer: self, commandBuffer: commandBuffer)
        }
    }

    private func update() {
        preUpdate?(self)
        targets.forEach {
            guard $0.isActive else {
                return
            }
            $0.update(renderer: self)
        }
    }

    private func render(encoder: MTLRenderCommandEncoder) {
        let fillMode: MTLTriangleFillMode = isWireFrame ? .lines : .fill
        totalVertexCount = 0

        targets.forEach {
            guard $0.isActive else {
                return
            }
            encoder.pushDebugGroup($0.name)
            encoder.setRenderPipelineState($0.renderState)
            encoder.setDepthStencilState($0.depthStencilState)

            updateFramUniforms(modelMatrix: $0.modelMatrix)

            encoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: VertexBufferIndex.frameUniforms.rawValue)
            encoder.setVertexBuffer($0.vertexBuffer, offset: 0, index: VertexBufferIndex.vertexData.rawValue)
            encoder.setVertexTexture($0.vertexTexture, index: 0)
            encoder.setFragmentTexture($0.fragmentTexture, index: 0)
            encoder.setTriangleFillMode(fillMode)

            $0.render(renderer: self, encoder: encoder)
            totalVertexCount += $0.vertexCount
            encoder.popDebugGroup()
        }
    }

    private func updateFramUniforms(modelMatrix: matrix_float4x4) {
        let p = frameUniformBuffer.contents().assumingMemoryBound(to: FrameUniforms.self)
        let mat4 = matrix_multiply(cameraMatrix, modelMatrix)
        p.pointee.projectionViewMatrix = matrix_multiply(projectionMatrix, mat4)
        let mat3 = Matrix.toUpperLeft3x3(from4x4: mat4)
        p.pointee.normalMatrix = matrix_invert(matrix_transpose(mat3))
        p.pointee.modelMatrix = modelMatrix
        p.pointee.inverseViewMatrix = matrix_invert(cameraMatrix)
        let col = float4(Float(wireColor.redComponent), Float(wireColor.greenComponent),
                Float(wireColor.blueComponent), isWireFrame ? 1 : 0)
        p.pointee.wireColor = col
    }
}

struct FrameUniforms {
    var projectionViewMatrinx: matrix_float4x4
    var normalMatrinx: matrix_float3x3
}

class MetalEzRenderingEngine {
    enum RendererType: Int {
        case mesh
        case mesh_add
        case mesh_no_lighting
        case skinning
        case targetMarker
        case points
        case explosion
        case sea
        case line
        case myDefault
    }

    weak var mtlEz: MetalEz!
    static let blendingIsEnabled = "BlendingIsEnabled"

    init(MetalEz _metalEz: MetalEz) {
        mtlEz = _metalEz
    }
}

class MetalEzMmeshRenderer: MetalEzRenderingEngine {
    init(MetalEz metalEz: MetalEz, pipelineDic: inout Dictionary<MetalEzRenderingEngine.RendererType, MTLRenderPipelineState>) {
        super.init(MetalEz: metalEz)
        let mtlVertex = makeMTLVertexDescriptor()

        pipelineDic[.mesh] =
                try! mtlEz.device.makeRenderPipelineState(descriptor: makeMTLRenderPassDescriptor(vertex: mtlVertex))

        pipelineDic[.mesh_add] =
                try! mtlEz.device.makeRenderPipelineState(descriptor: makeMTLRenderPassDescriptor4add(vertex: mtlVertex))

        pipelineDic[.mesh_no_lighting] =
                try! mtlEz.device.makeRenderPipelineState(descriptor: makeMTLRenderPassDescriptor4nonlighting(vertex: mtlVertex))
    }

    private func makeMTLVertexDescriptor() -> MTLVertexDescriptor {
        let mtlVertex = MTLVertexDescriptor()   //MTLRenderPipelineDescriptor.vertexDescriptor

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

        return mtlVertex
    }

    private func makeMTLRenderPassDescriptor(vertex: MTLVertexDescriptor) -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderDescriptor = MTLRenderPipelineDescriptor()

        renderDescriptor.vertexDescriptor = vertex
        renderDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "lambertVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLight")
        renderDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat

        return renderDescriptor
    }

    private func makeMTLRenderPassDescriptor4add(vertex: MTLVertexDescriptor) -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderDescriptor = MTLRenderPipelineDescriptor()

        renderDescriptor.vertexDescriptor = vertex
        renderDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "lambertVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLightAdd")
        renderDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderDescriptor.colorAttachments[0].isBlendingEnabled = true   //blending alpha config is here
        renderDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        renderDescriptor.label = MetalEzRenderingEngine.blendingIsEnabled

        return renderDescriptor
    }

    private func makeMTLRenderPassDescriptor4nonlighting(vertex: MTLVertexDescriptor) -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderDescriptor = MTLRenderPipelineDescriptor()

        renderDescriptor.vertexDescriptor = vertex
        renderDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "lambertVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLightNonl")
        renderDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat

        return renderDescriptor
    }

    func draw(mesh: MTKMesh, texture: MTLTexture, fuBuffer: MTLBuffer) {
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0) //do each model
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(fuBuffer, offset: 0, index: 1) //do each model
        mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texture, index: 0) //do each model
        mtlEz.mtlRenderCommandEncoder.drawIndexedPrimitives(
                type: mesh.submeshes[0].primitiveType,
                indexCount: mesh.submeshes[0].indexCount,
                indexType: mesh.submeshes[0].indexType,
                indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                indexBufferOffset: mesh.submeshes[0].indexBuffer.offset
        ) //do each model
    }
}

struct MetalEzExplosionRendererPoint {
    var point: float4
    var size: Float
    var len: Float
    var gain: Float = 0
    var dummy: Float = 0
}

class MetalEzExplosionRenderer: MetalEzRenderingEngine {
    init(MetalEz metalEz: MetalEz, pipelineDic: inout Dictionary<MetalEzRenderingEngine.RendererType, MTLRenderPipelineState>) {
        super.init(MetalEz: metalEz)

        let renderDescriptor = makeMTLRenderPassDescriptor()
        let mtlRenderPipelineState = try! mtlEz.device.makeRenderPipelineState(descriptor: renderDescriptor)
        pipelineDic[.explosion] = mtlRenderPipelineState
    }

    private func makeMTLRenderPassDescriptor() -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()

        renderPipelineDescriptor.label = MetalEzRenderingEngine.blendingIsEnabled
        renderPipelineDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "lambertVertexExplosion")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLightExplosion")
        renderPipelineDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderPipelineDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true   //blending alpha config is here
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one

        return renderPipelineDescriptor
    }

    func draw(vaertex: MTLBuffer, frameUniformBuffer: MTLBuffer, texure: MTLTexture, count: Int) {
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(vaertex, offset: 0, index: 0)
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
        mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texure, index: 0)
        mtlEz.mtlRenderCommandEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: count, instanceCount: 1)
    }

    func makeVertexBuffer(count: Int) -> MTLBuffer {
        let verBff = mtlEz.device.makeBuffer(length: MemoryLayout<MetalEzExplosionRendererPoint>.size * count, options: [])
        return verBff!
    }

    func set(points: [MetalEzExplosionRendererPoint], buffer: inout MTLBuffer) {
        let pvb = buffer.contents().assumingMemoryBound(to: MetalEzExplosionRendererPoint.self)
        for i in 0..<points.count {
            pvb.advanced(by: i).pointee = points[i]
        }
    }

    func set(modelMatrix: matrix_float4x4, frameUniformBuffer _myfubuff: inout MTLBuffer) {
        let p = _myfubuff.contents().assumingMemoryBound(to: FrameUniforms.self)
        let viewModelMatrix = matrix_multiply(mtlEz.cameraMatrix, modelMatrix)
        p.pointee.projectionViewMatrinx = matrix_multiply(mtlEz.projectionMatrix, viewModelMatrix)
        let mat3 = Matrix.toUpperLeft3x3(from4x4: viewModelMatrix)
        p.pointee.normalMatrinx = mat3.transpose.inverse
    }
}

struct MetalEzLineRendererPoint {
    var point: float4
}

class MetalEzLineRenderer: MetalEzRenderingEngine {
    init(MetalEz metalEz: MetalEz, pipelineDic: inout Dictionary<MetalEzRenderingEngine.RendererType, MTLRenderPipelineState>) {
        super.init(MetalEz: metalEz)
        let renderDescriptor = makeMTLRenderPassDescriptor()
        let mtlRenderPipelineState = try! mtlEz.device.makeRenderPipelineState(descriptor: renderDescriptor)
        pipelineDic[.line] = mtlRenderPipelineState
    }

    private func makeMTLRenderPassDescriptor() -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()

        renderPipelineDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "lambertVertexLine")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLightLine")
        renderPipelineDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderPipelineDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat

        return renderPipelineDescriptor
    }

    func draw(vaertex: MTLBuffer, frameUniformBuffer: MTLBuffer, count: Int) {
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(vaertex, offset: 0, index: 0)
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
        mtlEz.mtlRenderCommandEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: count, instanceCount: 1)
    }

    func makeVertexBuffer(count: Int) -> MTLBuffer {
        let verBff = mtlEz.device.makeBuffer(length: MemoryLayout<MetalEzLineRendererPoint>.size * count, options: [])
        return verBff!
    }

    func set(points: [MetalEzLineRendererPoint], buffer: inout MTLBuffer) {
        let pvb = buffer.contents().assumingMemoryBound(to: MetalEzLineRendererPoint.self)
        for i in 0..<points.count {
            pvb.advanced(by: i).pointee = points[i]
        }
    }

    func set(modelMatrix: matrix_float4x4, frameUniformBuffer _myfubuff: inout MTLBuffer) {
        let p = _myfubuff.contents().assumingMemoryBound(to: FrameUniforms.self)
        let viewModelMatrix = matrix_multiply(mtlEz.cameraMatrix, modelMatrix)
        p.pointee.projectionViewMatrinx = matrix_multiply(mtlEz.projectionMatrix, viewModelMatrix)
        let mat3 = Matrix.toUpperLeft3x3(from4x4: viewModelMatrix)
        p.pointee.normalMatrinx = mat3.transpose.inverse
    }
}
