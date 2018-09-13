//
//  TessellationMeshRenderer.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/29.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Foundation
import ModelIO
import MetalKit

protocol RenderObject {
    var name: String { get }
    var renderState: MTLRenderPipelineState { get }
    var depthStencilState: MTLDepthStencilState { get }
    
    var vertexBuffer: MTLBuffer { get }
    var vertexTexture: MTLTexture? { get }
    var fragmentTexture: MTLTexture? { get }
    
    var isActive: Bool { get set }
    var modelMatrix: matrix_float4x4 { get }
    var vertexCount: Int { get }
    
    func compute(renderer: Renderer, commandBuffer: MTLCommandBuffer)
    func update(renderer: Renderer)
    func render(renderer: Renderer, encoder: MTLRenderCommandEncoder)
}

class Geometry {
    let vertexDescriptor: MTLVertexDescriptor
    let vertexCount: Int
    let vertexBuffer: MTLBuffer
    let normalizeMatrix: matrix_float4x4
    
    init(vertexBuffer: MTLBuffer, vertexCount: Int, vertexDescriptor: MTLVertexDescriptor, normalizeMatrix: matrix_float4x4) {
        self.vertexBuffer = vertexBuffer
        self.vertexCount = vertexCount
        self.vertexDescriptor = vertexDescriptor
        self.normalizeMatrix = normalizeMatrix
    }
    
    convenience init?(url: URL, device: MTLDevice, addNormalThreshold: Float? = nil) {
        
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
        
        let modelDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertex)
        (modelDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (modelDescriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (modelDescriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        let asset = MDLAsset(url: url,
                             vertexDescriptor: modelDescriptor,
                             bufferAllocator: MTKMeshBufferAllocator(device: device))
        // 0決め打ち
        do {
            var mdlArray: NSArray?
            let _ = try MTKMesh.newMeshes(from: asset, device: device, sourceMeshes: &mdlArray)
            
            guard let mdl = mdlArray?[0] as? MDLMesh else {
                return nil
            }
            if let threshold = addNormalThreshold {
                mdl.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: threshold)
            }
            
            guard let geometry = Geometry(withMDLMesh: mdl, device: device) else {
                return nil
            }
            self.init(vertexBuffer: geometry.vertexBuffer,
                      vertexCount: geometry.vertexCount,
                      vertexDescriptor: geometry.vertexDescriptor,
                      normalizeMatrix: geometry.normalizeMatrix)
        } catch {
            print(error)
            return nil
        }
    }
    
    convenience init?(withMDLMesh mdl: MDLMesh, device: MTLDevice) {
        guard let mesh = try? MTKMesh(mesh: mdl, device: device) else {
            return nil
        }
        guard let vertex = Geometry.vertexFromMTK(mesh: mesh, device: device) else {
            return nil
        }
        
        self.init(vertexBuffer: vertex.buffer,
                  vertexCount: vertex.count,
                  vertexDescriptor: vertex.descriptor,
                  normalizeMatrix: Geometry.calcNormalizeMatrix(withMdlMesh: mdl))
    }
    
    private static func calcNormalizeMatrix(withMdlMesh mdl: MDLMesh) -> matrix_float4x4 {
        let diff = mdl.boundingBox.maxBounds - mdl.boundingBox.minBounds
        let scale = 1.0 / max(diff.x, max(diff.y, diff.z))
        let center = (mdl.boundingBox.maxBounds + mdl.boundingBox.minBounds) / vector_float3(2)
        return matrix_multiply(Matrix.scale(x: scale, y: scale, z: scale),
                               Matrix.translation(x: -center.x, y: -center.y, z: -center.z))
    }
    
    private static func vertexFromMTK(mesh: MTKMesh, device: MTLDevice) -> (buffer: MTLBuffer, count: Int, descriptor: MTLVertexDescriptor)? {
        //        for a in mesh.vertexDescriptor.attributes.enumerated() {
        //            let b = a.1 as! MDLVertexAttribute
        //            print("\(a.0): " + b.name + " \(b.offset) \(b.bufferIndex) \(b.format.rawValue)")
        //        }
        
        /*
         pos float3, normal float3, tex float2
         */
        guard let attrPosition = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributePosition),
            attrPosition.format == .float3 else {
                return nil
        }
        
        let ofsPosition = attrPosition.offset / MemoryLayout<Float>.size
        guard let attrNormal = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributeNormal),
            attrNormal.format == .float3 else {
                return nil
        }
        
        let ofsNormal = attrNormal.offset / MemoryLayout<Float>.size
        guard let attrTexcoord = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributeTextureCoordinate),
            attrTexcoord.format == .float2 else {
                return nil
        }
        
        let ofsTexcoord = attrTexcoord.offset / MemoryLayout<Float>.size
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        var buf = [Float]()
        var count = 0
        
        mesh.submeshes.forEach { subMesh in
            let indices: [UInt32]
            if subMesh.indexType == .uint16 {
                let pIndex = subMesh.indexBuffer.buffer.contents().assumingMemoryBound(to: UInt16.self)
                indices = UnsafeBufferPointer(start: pIndex, count: subMesh.indexCount).map {
                    UInt32($0)
                }
            } else {
                let pIndex = subMesh.indexBuffer.buffer.contents().assumingMemoryBound(to: UInt32.self)
                indices = UnsafeBufferPointer(start: pIndex, count: subMesh.indexCount).map {
                    $0
                }
            }
            count += indices.count
            
            let element = (vertexDescriptor?.layouts[0].stride)! / MemoryLayout<Float>.size
            let p = mesh.vertexBuffers[0].buffer.contents().assumingMemoryBound(to: Float.self)
            let data = UnsafeBufferPointer(start: p, count: mesh.vertexCount * element)
            
            indices.forEach {
                let i = Int($0) * element
                let pos = i + ofsPosition
                buf.append(contentsOf: data[pos..<pos + 3])
                let normal = i + ofsNormal
                buf.append(contentsOf: data[normal..<normal + 3])
                let texcoord = i + ofsTexcoord
                buf.append(contentsOf: data[texcoord..<texcoord + 2])
            }
        }
        
        return (buffer: device.makeBuffer(bytes: &buf, length: MemoryLayout<Float>.stride * buf.count, options: []),
                count: count,
                descriptor: vertexDescriptor) as! (buffer: MTLBuffer, count: Int, descriptor: MTLVertexDescriptor)
    }
    
    struct Vertex {
        let position: float3
        let normal: float3
        let texcoord: float2
        
        static func vertexDescriptor() -> MTLVertexDescriptor {
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float3
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0;
            vertexDescriptor.attributes[1].format = .float3
            vertexDescriptor.attributes[1].offset = MemoryLayout<float3>.stride
            vertexDescriptor.attributes[1].bufferIndex = 0;
            vertexDescriptor.attributes[2].format = .float2
            vertexDescriptor.attributes[2].offset = MemoryLayout<float3>.stride * 2
            vertexDescriptor.attributes[2].bufferIndex = 0;
            vertexDescriptor.layouts[0].stepRate = 1
            vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
            return vertexDescriptor
        }
    }
    
    static func makeWith(vertexList: [Vertex], device: MTLDevice) -> Geometry? {
        let buffer: MTLBuffer? = vertexList.withUnsafeBufferPointer {
            return device.makeBuffer(bytes: UnsafeRawPointer($0.baseAddress!),
                                     length: vertexList.count * MemoryLayout<Vertex>.stride,
                                     options: .storageModeShared)
        }
        
        guard let vertexBuffer = buffer else {
            return nil
        }
        return Geometry(vertexBuffer: vertexBuffer,
                        vertexCount: vertexList.count,
                        vertexDescriptor: Vertex.vertexDescriptor(),
                        normalizeMatrix: matrix_identity_float4x4)
    }
}

protocol MeshObject {
    func makeGeometry(renderer: Renderer) -> Geometry?
    var setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)? { get }
    var vertexFunctionName: String { get }
    var fragmentFunctionName: String { get }
    var diffuseTextureURL: URL { get }
    var normalMapURL: URL? { get }
}

protocol TessellationMeshObject: MeshObject {
    var tessellationVertexFunctionName: String { get }
    var tessellationFragmentFunctionName: String { get }
    var displacementMapURL: URL? { get }
}

class TessellationMeshRenderer: RenderObject {
    var isTesselasiton = false

    private let standardRenderState: MTLRenderPipelineState
    private let tesselasitonRenderState: MTLRenderPipelineState

    var baseMatrix: matrix_float4x4

    // MARK: Tesselasiton

    let triangleVertex = 3

    struct TessellationUniforms {
        var phongFactor: Float
        var displacementFactor: Float
        var displacementOffset: Float
    }

    private let tessellationFactorsBuffer: MTLBuffer
    private let tessellationUniformsBuffer: MTLBuffer

    var edgeFactor = Float(2)
    var insideFactor = Float(2)

    var phongFactor = Float(0) {
        didSet {
            updateUniforms()
        }
    }
    var displacementFactor = Float(0.1) {
        didSet {
            updateUniforms()
        }
    }
    var displacementOffset = Float(0) {
        didSet {
            updateUniforms()
        }
    }

    private let computePipeline: MTLComputePipelineState

    // MARK: - RenderObject Common
    var name = "MeshRenderer"

    var renderState: MTLRenderPipelineState {
        return isTesselasiton ? tesselasitonRenderState : standardRenderState
    }

    let depthStencilState: MTLDepthStencilState

    let vertexCount: Int
    let vertexBuffer: MTLBuffer
    var vertexTexture: MTLTexture?
    var fragmentTexture: MTLTexture?
    var normalMapTexture: MTLTexture?

    var isActive = true
    var modelMatrix = matrix_identity_float4x4

    init(renderer: Renderer, mesh: TessellationMeshObject) {
        let device = renderer.device
        let library = renderer.library

        // make geometory
        let model = mesh.makeGeometory(renderer: renderer)!
        self.baseMatrix = mesh.setupBaseMatrix?(model.normalizeMatrix) ?? model.normalizeMatrix
        self.vertexCount = model.vertexCount
        self.vertexBuffer = model.vertexBuffer

        // make renderstate
        self.standardRenderState = TessellationMeshRenderer.makeStandardRenderState(
                renderer: renderer, vertexDescriptor: model.vertexDescriptor, mesh: mesh)
        self.tesselasitonRenderState = TessellationMeshRenderer.makeTessellationRenderState(
                renderer: renderer, vertexDescriptor: model.vertexDescriptor, mesh: mesh)

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)

        // make texture
        let loader = MTKTextureLoader(device: device)
        self.fragmentTexture = try! loader.newTexture(withContentsOf: mesh.diffuseTextureURL, options: nil)
        if let displacementMap = mesh.displacementMapURL {
            self.vertexTexture = try? loader.newTexture(withContentsOf: displacementMap, options: nil)
        } else {
            self.vertexTexture = nil
        }
        if let normalMap = mesh.normalMapURL {
            self.normalMapTexture = try? loader.newTexture(withContentsOf: normalMap, options: nil)
        } else {
            self.normalMapTexture = nil
        }

        // init tessellation
        self.tessellationFactorsBuffer = device.makeBuffer(length: MemoryLayout<uint2>.stride,
                options: .storageModePrivate)
        tessellationFactorsBuffer.label = "Tessellation Factors"
        self.tessellationUniformsBuffer = device.makeBuffer(length: MemoryLayout<TessellationUniforms>.stride,
                options: .storageModeShared)
        tessellationUniformsBuffer.label = "Tessellation Uniforms"

        let kernel = library.makeFunction(name: "tessellationFactorsCompute")
        computePipeline = try! device.makeComputePipelineState(function: kernel!)

        updateUniforms()
    }

    func compute(renderer: Renderer, commandBuffer: MTLCommandBuffer) {
        if isTesselasiton {
            let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
            computeCommandEncoder?.label = "Compute Tessellation Factors"
            computeCommandEncoder?.pushDebugGroup("Compute Tessellation Factors")

            computeCommandEncoder?.setComputePipelineState(computePipeline)

            var factor = float2(edgeFactor, insideFactor)
            withUnsafePointer(to: &factor) {
                computeCommandEncoder?.setBytes(UnsafeRawPointer($0), length: MemoryLayout<float2>.stride, index: 0)
            }

            computeCommandEncoder?.setBuffer(tessellationFactorsBuffer, offset: 0, index: 1)
            computeCommandEncoder?.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1),
                    threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))

            computeCommandEncoder?.popDebugGroup()
            computeCommandEncoder?.endEncoding()
        }
    }

    func update(renderer: Renderer) {
        modelMatrix = matrix_multiply(modelMatrix, baseMatrix)
    }

    func render(renderer: Renderer, encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentTexture(normalMapTexture, index: 1)
        if isTesselasiton {
            encoder.setVertexBuffer(tessellationUniformsBuffer, offset: 0, index: 2)
            encoder.setTessellationFactorBuffer(tessellationFactorsBuffer, offset: 0, instanceStride: 0)
            encoder.drawPatches(numberOfPatchControlPoints: triangleVertex,
                    patchStart: 0,
                    patchCount: vertexCount / triangleVertex,
                    patchIndexBuffer: nil,
                    patchIndexBufferOffset: 0,
                    instanceCount: 1,
                    baseInstance: 0)
        } else {
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        }
    }

    // MARK: - private
    private static func makeStandardRenderState(renderer: Renderer, vertexDescriptor: MTLVertexDescriptor, mesh: MeshObject) -> MTLRenderPipelineState {
        let device = renderer.device
        let library = renderer.library

        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertexDescriptor
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: mesh.vertexFunctionName)
        renderDescriptor.fragmentFunction = library.makeFunction(name: mesh.fragmentFunctionName)
        renderDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        return try! device.makeRenderPipelineState(descriptor: renderDescriptor)
    }

    private static func makeTessellationRenderState(renderer: Renderer, vertexDescriptor: MTLVertexDescriptor, mesh: TessellationMeshObject) -> MTLRenderPipelineState {
        let device = renderer.device
        let library = renderer.library

        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint

        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertexDescriptor
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: mesh.tessellationVertexFunctionName)
        renderDescriptor.fragmentFunction = library.makeFunction(name: mesh.tessellationFragmentFunctionName)
        renderDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat

        renderDescriptor.isTessellationFactorScaleEnabled = false
        renderDescriptor.tessellationFactorFormat = .half
        renderDescriptor.tessellationControlPointIndexType = .none
        renderDescriptor.tessellationFactorStepFunction = .constant
        renderDescriptor.tessellationOutputWindingOrder = .clockwise
        renderDescriptor.tessellationPartitionMode = .fractionalEven
        renderDescriptor.maxTessellationFactor = 16

        return try! device.makeRenderPipelineState(descriptor: renderDescriptor)
    }

    private func updateUniforms() {
        let p = tessellationUniformsBuffer.contents().assumingMemoryBound(to: TessellationUniforms.self)
        p.pointee.phongFactor = phongFactor
        p.pointee.displacementFactor = displacementFactor
        p.pointee.displacementOffset = displacementOffset
    }
}
