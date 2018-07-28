import Foundation
import Metal
import MetalKit
import simd


extension HalfEdgeStructure {
    class Model {
        private(set) var polygons: [String: Polygon]
        private(set) var fullEdges: [String: FullEdge]
        
        init() {
            polygons = [String: Polygon]()
            fullEdges = [String: FullEdge]()
        }
        
        private func setPair(halfEdges targetHalfEdges: HalfEdge...) { //ペアのハーフエッジを設定する
            for targetHalfEdge in targetHalfEdges {
                var flag: Bool = false
                for (_, fullEdge) in fullEdges {
                    if fullEdge.startVertex == targetHalfEdge.endVertex && fullEdge.endVertex == targetHalfEdge.startVertex {
                        fullEdge.set(right: targetHalfEdge)
                        flag = true
                        break
                    }
                }
                if flag == false {
                    let fe = FullEdge(left: targetHalfEdge)
                    fullEdges[fe.uuid] = fe
                }
            }
        }
        
        func addPolygon(vertex0: float3, vertex1: float3, vertex2: float3) {
            let he0 = HalfEdge(vertex: vertex0)
            let he1 = HalfEdge(vertex: vertex1)
            let he2 = HalfEdge(vertex: vertex2)
            he0.setHalfEdge(next: he1, prev: he2)
            he1.setHalfEdge(next: he2, prev: he0)
            he2.setHalfEdge(next: he0, prev: he1)
            let polygon = Polygon(halfEdge: he0)
            polygons[polygon.uuid] = polygon
            setPair(halfEdges: he0, he1, he2)
        }
        
        func updateQuadraticErrorMetricsAll() {
            for (_, fullEdge) in fullEdges {
                fullEdge.updateQuadraticErrorMetrics(polygons: &polygons)
            }
        }
        
        func updateQuadraticErrorMetrics(uuids: [String]) {
            for uuid in uuids {
                if let f = fullEdges[uuid] {
                    f.updateQuadraticErrorMetrics(polygons: &polygons)
                }
            }
        }
        
        private func collapse(fullEdge: FullEdge) {
            if fullEdge.isAbleToCollapse == false {
                fullEdge.quadraticErrorMetrics = Double.infinity
                return
            }
            guard let leftHalfEdge = fullEdge.leftHalfEdge,
                let rightHalfEdge = fullEdge.rightHalfEdge else {
                    return
            }
            guard let heLT = leftHalfEdge.prevHalfEdge.pairHalfEdge,
                let heRT = leftHalfEdge.nextHalfEdge.pairHalfEdge,
                let heLB = rightHalfEdge.nextHalfEdge.pairHalfEdge,
                let heRB = rightHalfEdge.prevHalfEdge.pairHalfEdge else {
                    return
            }
            
            var updatedHalfEdge = [String]()
            leftHalfEdge.repeatPrevHalfEdge { halfEdge in
                halfEdge.startVertex = fullEdge.candidateNewVertex
                updatedHalfEdge.append(halfEdge.fullEdgeStatus.uuid)
            }
            leftHalfEdge.repeatNextHalfEdge { halfEdge in
                halfEdge.endVertex = fullEdge.candidateNewVertex
                updatedHalfEdge.append(halfEdge.fullEdgeStatus.uuid)
            }
            
            for id in [fullEdge.uuid, heRT.fullEdgeStatus.uuid, heLT.fullEdgeStatus.uuid,
                       heLB.fullEdgeStatus.uuid, heRB.fullEdgeStatus.uuid] {
                        fullEdges.removeValue(forKey: id)
                        updatedHalfEdge.remove(value: id)
            }
            
            let fe0 = FullEdge(left: heRT, right: heLT)
            let fe1 = FullEdge(left: heLB, right: heRB)
            fullEdges[fe0.uuid] = fe0
            fullEdges[fe1.uuid] = fe1
            
            updatedHalfEdge.append(fe0.uuid)
            updatedHalfEdge.append(fe1.uuid)
            
            polygons.removeValue(forKey: leftHalfEdge.polygonStatus.uuid)
            polygons.removeValue(forKey: rightHalfEdge.polygonStatus.uuid)
            
            self.updateQuadraticErrorMetrics(uuids: updatedHalfEdge.unique)
            return
        }
        
        func polygonReduction(count: Int) {
            for _ in 0..<(count / 2) {
                let v = fullEdges.min(by: { a, b in a.value.quadraticErrorMetrics < b.value.quadraticErrorMetrics })
                if let f = v?.value {
                    collapse(fullEdge: f)
                }
            }
        }
    }
    
    class HalfEdge {
        var vertex: float3                          //始点となる頂点
        private(set) var nextHalfEdge: HalfEdge!    //次のハーフエッジ
        private(set) var prevHalfEdge: HalfEdge!    //前のハーフエッジ
        var pairHalfEdge: HalfEdge?                 //稜線を挟んで反対側のハーフエッジ
        var fullEdgeStatus: FullEdge.Status!        //このハーフエッジを含むフルエッジ
        var polygonStatus: Polygon.Status!          //このハーフエッジを含む面
        
        init(vertex v: float3) {
            vertex = v
        }
        
        var endVertex: float3 {
            get {
                return nextHalfEdge.vertex
            }
            set(v) {
                nextHalfEdge.vertex = v
            }
        }
        var startVertex: float3 {
            get {
                return vertex
            }
            set(v) {
                vertex = v
            }
        }
        
        func setHalfEdge(next: HalfEdge, prev: HalfEdge) {
            prevHalfEdge = prev
            nextHalfEdge = next
        }
        
        func repeatPrevHalfEdge(_ action: (HalfEdge) -> Void) {
            var heCK = self.prevHalfEdge.pairHalfEdge!
            repeat {
                action(heCK)
                heCK = heCK.prevHalfEdge.pairHalfEdge!
            } while heCK !== self
        }
        
        func repeatNextHalfEdge(_ action: (HalfEdge) -> Void) {
            var heCK = self.nextHalfEdge.pairHalfEdge!
            repeat {
                action(heCK)
                heCK = heCK.nextHalfEdge.pairHalfEdge!
            } while heCK !== self
        }
    }
    
    class FullEdge {
        private(set) var uuid: String
        private(set) var leftHalfEdge: HalfEdge!        //順方向のハーフエッジ
        private(set) var rightHalfEdge: HalfEdge?       //逆方向のハーフエッジ
        var quadraticErrorMetrics: Double = 0.0         //QEM
        var candidateNewVertex = float3(0, 0, 0)        //QEMを計算した頂点
        
        init(left: HalfEdge, right: HalfEdge? = nil) {
            uuid = NSUUID().uuidString
            set(left: left)
            if let right = right {
                set(right: right)
                setPairsEachOther()
            }
        }
        
        func set(left: HalfEdge) {
            leftHalfEdge = left
            left.fullEdgeStatus = Status(uuid: self.uuid, side: .left)
            if rightHalfEdge != nil {
                setPairsEachOther()
            }
        }
        
        func set(right: HalfEdge) {
            rightHalfEdge = right
            right.fullEdgeStatus = Status(uuid: self.uuid, side: .right)
            setPairsEachOther()
        }
        
        private func setPairsEachOther() {
            leftHalfEdge.pairHalfEdge = rightHalfEdge
            rightHalfEdge?.pairHalfEdge = leftHalfEdge
        }
        
        var startVertex: float3 {
            return leftHalfEdge.startVertex
        }
        var endVertex: float3 {
            return leftHalfEdge.endVertex
        }
        
        struct Status {
            enum Side {
                case right
                case left
            }
            
            var uuid: String
            var side: Side
        }
        
        func updateQuadraticErrorMetrics(polygons: inout [String: Polygon]) {
            if self.isAbleToCollapse == false {
                quadraticErrorMetrics = Double.infinity
                return
            }
            var updatePolygonID = [String]()
            leftHalfEdge.repeatPrevHalfEdge { halfEdge in
                updatePolygonID.append(halfEdge.polygonStatus.uuid)
            }
            leftHalfEdge.repeatNextHalfEdge { halfEdge in
                updatePolygonID.append(halfEdge.polygonStatus.uuid)
            }
            candidateNewVertex = (self.startVertex + self.endVertex) * 0.5
            quadraticErrorMetrics = 0
            for uuid in updatePolygonID.unique {
                if let f = polygons[uuid] {
                    quadraticErrorMetrics += pow(f.distanceBy(point: candidateNewVertex), 2)
                }
            }
        }
        
        var isAbleToCollapse: Bool {
            guard let leftHalfEdge = self.leftHalfEdge,
                let rightHalfEdge = self.rightHalfEdge else {
                    return false
            }
            guard let heLT = leftHalfEdge.prevHalfEdge.pairHalfEdge,
                let heRT = leftHalfEdge.nextHalfEdge.pairHalfEdge,
                let _ = rightHalfEdge.nextHalfEdge.pairHalfEdge, /*heLB*/
                let _ = rightHalfEdge.prevHalfEdge.pairHalfEdge /*heRB*/ else {
                    return false
            }
            var l_neighborhood = [float3]()
            var r_neighborhood = [float3]()
            var heCK: HalfEdge
            heCK = heLT
            repeat {
                l_neighborhood.append(heCK.endVertex)
                if heCK.prevHalfEdge.pairHalfEdge == nil {
                    return false
                }
                heCK = heCK.prevHalfEdge.pairHalfEdge!
            } while heCK !== self.leftHalfEdge
            heCK = heRT
            repeat {
                r_neighborhood.append(heCK.startVertex)
                if heCK.nextHalfEdge.pairHalfEdge == nil {
                    return false
                }
                heCK = heCK.nextHalfEdge.pairHalfEdge!
            } while heCK !== self.leftHalfEdge
            var cnt: Int = 0
            for l in l_neighborhood {
                for r in r_neighborhood {
                    if l == r {
                        cnt += 1
                    }
                }
            }
            if cnt >= 3 {
                return false
            }
            return true
        }
    }
    
    class Polygon {
        private(set) var uuid: String
        private(set) var halfEdge: HalfEdge  //含むハーフエッジの１つ
        
        struct Status {
            var uuid: String
        }
        
        init(halfEdge h: HalfEdge) {
            uuid = NSUUID().uuidString
            halfEdge = h
            var he = halfEdge
            repeat {
                he.polygonStatus = Status(uuid: self.uuid)
                he = he.nextHalfEdge
            } while he !== halfEdge
        }
        
        private var equation: float4 {
            let v0 = halfEdge.vertex
            let v1 = halfEdge.nextHalfEdge.vertex
            let v2 = halfEdge.prevHalfEdge.vertex
            let c = cross(v1 - v0, v2 - v0)
            let d = -1 * dot(v0, c)
            return float4(c.x, c.y, c.z, d)
        }
        
        func distanceBy(point: float3) -> Double {
            return Double(dot(self.equation, point.toFloat4))
        }
    }
    
    struct myfloat4 {
        var x: Float
        var y: Float
        var z: Float
        var w: Float
    }
    
    struct myfloat3 {
        var x: Float
        var y: Float
        var z: Float
    }
    
    struct myfloat2 {
        var x: Float
        var y: Float
    }
    
    struct MeshPoint {
        var point: myfloat3
        var normal: myfloat3
        var texcoord: myfloat2
    }
}

struct FrameUniforms {
    var projectionViewMatrinx: matrix_float4x4
    var normalMatrinx: matrix_float3x3
}

extension Array where Element: Equatable {
    var unique: [Element] {
        return reduce([Element]()) {
            $0.contains($1) ? $0 : $0 + [$1]
        }
    }
    
    mutating func remove(value: Element) {
        if let i = self.index(of: value) {
            self.remove(at: i)
        }
    }
}

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
        let buffer = render.commandQueue?.makeCommandBuffer()
        let renderCommandEncoder = buffer?.makeRenderCommandEncoder(descriptor: render.renderPassDescriptor())
        renderCommandEncoder?.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        renderCommandEncoder?.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
        renderCommandEncoder?.setFragmentTexture(texture, index: 0)
        renderCommandEncoder?.drawIndexedPrimitives(type: mesh.submeshes[0].primitiveType,
                                                    indexCount: mesh.submeshes[0].indexCount,
                                                    indexType: mesh.submeshes[0].indexType,
                                                    indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                                                    indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)
    }
}



/*
let mesh = HalfEdgeStructure.loadMesh(name: "cube")
drawer = MeshDrawer(mtlEz: world.mtlEz ,mesh: mesh, texture: tex)
*/
