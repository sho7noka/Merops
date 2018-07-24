import Foundation
import Metal
import MetalKit
import simd


class MeshDrawer {
    private var device: MTLDevice
    private var mesh: MTKMesh
    private var texture: MTLTexture
    var frameUniformBuffer: MTLBuffer
    
    var cameraMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_float4x4()
    
    var render : MetalRender
    
    init(device d: MTLDevice, mesh v: MTKMesh, texture t: MTLTexture) {
        device = d
        mesh = v
        texture = t
        frameUniformBuffer = device.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])!
        
        render = MetalRender(device: device)
        let model = HalfEdgeStructure.LoadModel(device: device, name: "realship", reduction: 2300)


//        let tex = world.mtlEz.loader.loadTexture(name: "shipDiffuse", type: "png")
//        let mesh = world.mtlEz.loader.loadMesh(name: "realship")
//        let d = MetalEz.MeshDrawer(mtlEz: world.mtlEz ,mesh: mesh, texture: tex)
//        drawers.append(d)
        
//        var mdlBff = world.mtlEz.line.makeVertexBuffer(count: model.polygons.count * 3 * 2)
//        var pnts = [MetalEzLineRendererPoint]()
        for (_, fullEdge) in model.fullEdges {
//            pnts.append(MetalEzLineRendererPoint(point: fullEdge.startVertex.toFloat4))
//            pnts.append(MetalEzLineRendererPoint(point: fullEdge.endVertex.toFloat4))
        }
//        world.mtlEz.line.set(points: pnts, buffer: &mdlBff)
//        mdlBffs.append(mdlBff)
        let vertexCount = model.polygons.count * 3 * 2
//        vertexCounts.append(vertexCount)
        
    }
    
    func set(modelMatrix: matrix_float4x4) {
        let p = frameUniformBuffer.contents().assumingMemoryBound(to: FrameUniforms.self)
        let viewModelMatrix = matrix_multiply(cameraMatrix, modelMatrix)
        p.pointee.projectionViewMatrinx = matrix_multiply(projectionMatrix, viewModelMatrix)
        let mat3 = Matrix.toUpperLeft3x3(from4x4: viewModelMatrix)
        p.pointee.normalMatrinx = mat3.transpose.inverse
    }
    func draw() {
        let buffer = render.commandQueue().makeCommandBuffer()
        let renderCommandEncoder = buffer?.makeRenderCommandEncoder(descriptor: render.renderPassDescriptor())
        renderCommandEncoder?.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)   //do each model
        renderCommandEncoder?.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1) //do each model
        renderCommandEncoder?.setFragmentTexture(texture, index: 0)    //do each model
        renderCommandEncoder?.drawIndexedPrimitives(type: mesh.submeshes[0].primitiveType,
                                                            indexCount: mesh.submeshes[0].indexCount,
                                                            indexType: mesh.submeshes[0].indexType,
                                                            indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                                                            indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)   //do each model
    }
}



/*
let mesh = HalfEdgeStructure.loadMesh(name: "cube")
drawer = MeshDrawer(mtlEz: world.mtlEz ,mesh: mesh, texture: tex)
*/
