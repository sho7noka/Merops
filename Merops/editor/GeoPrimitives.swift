//
//  GeoPrimitives.swift
//  KARAS
//
//  Created by sumioka-air on 2018/02/04.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

import Foundation
import SceneKit

class SCNLine: SCNNode {

    // 直線
    init(from: SCNVector3, to: SCNVector3) {
        super.init()

        let source = SCNGeometrySource.init(vertices: [from, to])
        let indices: [UInt8] = [0, 1]
        let data = Data.init(bytes: indices)
        let element = SCNGeometryElement.init(data: data, primitiveType: .line,
                primitiveCount: 1, bytesPerIndex: 1)
        let geometry = SCNGeometry.init(sources: [source], elements: [element])
        self.geometry = geometry

        // Material
        let material = SCNMaterial.init()
        material.diffuse.contents = Color.white.cgColor
        self.geometry!.insertMaterial(material, at: 0)
    }

    // Bezier
    init(path: SCNPath) {
        super.init()

        let source = SCNGeometrySource(vertices: path.points)
        let indices: [UInt32] = {
            var rtn = [UInt32]();
            for i in 0..<path.points.count - 1 {
                rtn += [UInt32(i), UInt32(i + 1)]
            };
            return rtn
        }()

        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        self.geometry = geometry

        // Material
        let material = SCNMaterial()
        material.diffuse.contents = Color.white
        self.geometry!.insertMaterial(material, at: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

infix operator =>

public func =><T, U>(lhs: T, rhs: (T) throws -> U) rethrows -> U {
    return try rhs(lhs)
}

public class SCNPath {
    
    private var current: SCNVector3 = SCNVector3(0, 0, 0)
    var points: [SCNVector3] = [] //曲線を構成する点の座標を保存する
    
    /// 始点を設定します。pointsは上書きされます。デフォルトでは(0, 0, 0)です。
    func start(from point: SCNVector3) -> SCNPath {
        current = point
        points = [point]
        return self
    }
    
    func addLine(to point: SCNVector3) -> SCNPath {
        var rtn = [SCNVector3]()
        points.append(current)
        rtn.append(current)
        current = point
        return self
    }
    
    func addQuadCurve(to point: SCNVector3, control: SCNVector3) -> SCNPath {
        var rtn = [SCNVector3]()
        let n = 1 //((control - current).length + (point - control).length) * 12
        for i in 0..<n {
            let t = SCNFloat(i / n)
            
            let q1 = current + (control - current) * t
            let q2 = control + (point - control) * t
            
            let r = q1 + (q2 - q1) * t
            rtn.append(r)
        }
        points += rtn
        current = point
        return self
    }
    
    func addCurve(to point: SCNVector3, control1: SCNVector3, control2: SCNVector3) -> SCNPath {
        var rtn = [SCNVector3]()
        let n = 1 //Int((control1 - current).length + (control2 - control1).length + (point - control2).length) * 12
        for i in 0..<n {
            let t = SCNFloat(i / n)
            
            let q1 = current + (control1 - current) * t
            let q2 = control1 + (control2 - control1) * t
            let q3 = control2 + (point - control2) * t
            
            let r1 = q1 + (q2 - q1) * t
            let r2 = q2 + (q3 - q2) * t
            
            let s = r1 + (r2 - r1) * t
            rtn.append(s)
        }
        points += rtn
        current = point
        return self
    }
    
    func end() {
        points.append(current)
    }
    
    func close() -> SCNPath {
        _ = addLine(to: self.points[0])
        if let last = points.last, last == current {
        } else {
            points.append(current)
        }
        current = self.points[0]
        return self
    }
}

class Quad {
    let v0: SCNVector3
    let v1: SCNVector3
    let v2: SCNVector3
    let v3: SCNVector3

    init(v0: SCNVector3, v1: SCNVector3, v2: SCNVector3, v3: SCNVector3) {
        self.v0 = v0
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
    }
}

class QuadBuilder {
    var quads: [Quad]

    enum UVModeType {
        case StretchToFitXY, StretchToFitX,
             StretchToFitY, SizeToWorldUnitsXY, SizeToWorldUnitsX
    }

    var uvMode = UVModeType.StretchToFitXY

    init(uvMode: UVModeType = .StretchToFitXY) {
        self.uvMode = uvMode
        quads = []
    }

    // Add a quad to the geometry
    // - list verticies in counter-clockwise order
    // when looking from the "outside" of the square
    func addQuad(quad: Quad) {
        quads.append(quad)
    }

    func getGeometry() -> SCNGeometry {
        var verts: [SCNVector3] = []
        var faceIndices: [CInt] = []
        var normals: [SCNVector3] = []
        var uvs: [CGPoint] = []

        // Walk through the quads, adding 4 vertices, 2 faces and 4 normals per quad
        //  v1 --------------v0
        //  |             __/ |
        //  | face     __/    |
        //  | 1     __/       |
        //  |    __/     face |
        //  | __/           2 |
        //  v2 ------------- v3
        for quad in quads {
            verts.append(quad.v0)
            verts.append(quad.v1)
            verts.append(quad.v2)
            verts.append(quad.v3)

            // add face 1
            faceIndices.append(CInt(verts.count - 4)) // v0
            faceIndices.append(CInt(verts.count - 3)) // v1
            faceIndices.append(CInt(verts.count - 2)) // v2

            // add face 2
            faceIndices.append(CInt(verts.count - 4)) // v0
            faceIndices.append(CInt(verts.count - 2)) // v2
            faceIndices.append(CInt(verts.count - 1)) // v3

            // add normals for each vertice (compute seperately for face1 and face2 - common edge gets avg)
            let nvf1 = getNormal(v0: quad.v0, v1: quad.v1, v2: quad.v2)
            let nvf2 = getNormal(v0: quad.v0, v1: quad.v2, v2: quad.v3)
            normals.append(nvf1 + nvf2) // v0
            normals.append(nvf1) // v1
            normals.append(nvf1 + nvf2) // v2
            normals.append(nvf2) // v3

            let longestUEdgeLength = max((quad.v1 - quad.v0).length(), (quad.v2 - quad.v3).length())
            let longestVEdgeLength = max((quad.v1 - quad.v2).length(), (quad.v0 - quad.v3).length())

            switch uvMode {
                    // The longest sides dictate the texture tiling, then it is stretched (if nec) across
            case .SizeToWorldUnitsX:
                uvs.append(CGPoint(x: Double(longestUEdgeLength), y: Double(longestVEdgeLength)))
                uvs.append(CGPoint(x: 0, y: Double(longestVEdgeLength)))
                uvs.append(CGPoint(x: 0, y: 0))
                uvs.append(CGPoint(x: Double(longestUEdgeLength), y: 0))

            case .SizeToWorldUnitsXY:
                // For this uvMode, we allign the texture to the "upper left corner" (v1) and tile
                // it to the "right" and "down" (and "up") based on the coordinate units and the
                // texture/units ratio

                let v2v0 = quad.v0 - quad.v2 // v2 to v0 edge
                let v2v1 = quad.v1 - quad.v2 // v2 to v1 edge
                let v2v3 = quad.v3 - quad.v2 // v2 to v3 edge

                let v2v0Mag = v2v0.length() // length of v2 to v0 edge
                let v2v1Mag = v2v1.length() // length of v2 to v1 edge
                let v2v3Mag = v2v3.length() // length of v2 to v3 edge

                let v0angle = v2v3.angle(vector: v2v0) // angle of v2v0 edge against v2v3 edge
                let v1angle = v2v3.angle(vector: v2v1) // angle of v2v1 edge against v2v3 edge

                // now its just some simple trig - yay!
                uvs.append(CGPoint(x: CGFloat(cos(v0angle) * v2v0Mag), y: CGFloat(sin(v0angle) * v2v0Mag))) // V0
                uvs.append(CGPoint(x: CGFloat(cos(v1angle) * v2v1Mag), y: CGFloat(sin(v1angle) * v2v1Mag))) // V1
                uvs.append(CGPoint(x: 0, y: 0)) // V2
                uvs.append(CGPoint(x: CGFloat(v2v3Mag), y: 0)) // V3
                
//                print("v0 texture point is at \(CGPoint(x: cos(v0angle) * v2v0Mag, y: sin(v0angle) * v2v0Mag))")
//                print("v1 texture point is at \(CGPoint(x: cos(v1angle) * v2v1Mag, y: sin(v1angle) * v2v1Mag))")
//                print("v2 texture point is at \(CGPoint(x: 0, y: 0))")
//                print("v3 texture point is at \(CGPoint(x: v2v3Mag, y: 0))")

            case .StretchToFitXY:
                uvs.append(CGPoint(x: 1, y: 1))
                uvs.append(CGPoint(x: 0, y: 1))
                uvs.append(CGPoint(x: 0, y: 0))
                uvs.append(CGPoint(x: 1, y: 0))

            default:
                print("Unknown uv mode \(uvMode)") // no uv mapping for you!
            }
        }

        // Define our sources
        let vertexSource = SCNGeometrySource(vertices: verts)
        let normalSource = SCNGeometrySource(normals: normals)
        let textureSource = SCNGeometrySource(textureCoordinates: uvs)

        // Define elements Data
        let indexData = NSData(bytes: faceIndices, length: MemoryLayout<CInt>.size * faceIndices.count)
        let element = SCNGeometryElement(data: indexData as Data, primitiveType: .triangles, primitiveCount: faceIndices.count / 3, bytesPerIndex: MemoryLayout<CInt>.size)

        let geometry = SCNGeometry(sources: [vertexSource, normalSource, textureSource], elements: [element])
        return geometry
    }
}

extension SCNGeometry {
    func square(length: Float) -> [SCNVector3] {
        let m = SCNFloat(length / Float(2)), q = SCNFloat(Float(1))
        
        let topLeft = SCNVector3Make(-m - q, m + q, m + q),
        topRight = SCNVector3Make(m + q, m + q, m + q),
        bottomLeft = SCNVector3Make(-m - q, -m - q, m + q),
        bottomRight = SCNVector3Make(m + q, -m - q, m + q)
        
        return [topLeft, topRight, bottomLeft, bottomRight]
    }

    func vertices() -> [SCNVector3] {
        var vectors = [SCNVector3]()
        let vertexSources = sources(for: .vertex)
        if let v = vertexSources.first {
            v.data.withUnsafeBytes { (p: UnsafePointer<Float32>) in
                for i in 0..<v.vectorCount {
                    let index = (i * v.dataStride + v.dataOffset) / 4
                    vectors.append(SCNVector3Make(
                        SCNFloat(p[index + 0]),
                        SCNFloat(p[index + 1]),
                        SCNFloat(p[index + 2])
                    ))
                }
            }
            return vectors
        }
        return []
    }
    
    func normals() -> [SCNVector3] {
        var vectors = [SCNVector3]()
        let normalSources = sources(for: .normal)
        if let v = normalSources.first {
            v.data.withUnsafeBytes { (p: UnsafePointer<Float32>) in
                for i in 0..<v.vectorCount {
                    let index = (i * v.dataStride + v.dataOffset) / 4
                    vectors.append(SCNVector3Make(
                        SCNFloat(p[index + 0]),
                        SCNFloat(p[index + 1]),
                        SCNFloat(p[index + 2])
                    ))
                }
            }
            return vectors
        }
        return []
    }
}

// experimental

//func points(result: SCNHitTestResult) {
//    let node = SCNNode(geometry: SCNSphere(radius: 0.3))
//    node.categoryBitMask = NodeOptions.noExport.rawValue
//    
//    let vectors = vertices(node: node)
//    for (index, vec) in vectors.enumerated() {
//        NSLog("\(vec)")
//        let pointNode = node.flattenedClone()
//        pointNode.name = "vertex_\(index)"
//        //        pointNode.position = self.projectPoint(vec)
//        result.node.addChildNode(pointNode)
//    }
//}
//
//func lines(result: SCNHitTestResult) {
//    let node = SCNNode()
//    node.categoryBitMask = NodeOptions.noExport.rawValue
//    
//    for (index, vec) in vertices(node: node).enumerated() {
//        let source = SCNGeometrySource(
//            vertices: [vec, vec]),
//        indices: [UInt8] = [0, 1],
//        data = Data(bytes: indices
//        ),
//        element = SCNGeometryElement(
//            data: data, primitiveType: .line, primitiveCount: 1, bytesPerIndex: 1
//        )
//        node.geometry = SCNGeometry(sources: [source], elements: [element])
//        let lineNode = node.flattenedClone()
//        lineNode.name = "line\(index)"
//        
//        let material = SCNMaterial()
//        material.diffuse.contents = Color.red
//        lineNode.geometry!.insertMaterial(material, at: 0)
//        result.node.addChildNode(lineNode)
//    }
//}

//extension SCNGeometrySource {
//    convenience init(textureCoordinates texcoord: [float2]) {
//        let data = Data(bytes: texcoord, length: sizeof(float2) * texcoord.count)
//        self.init(data: data, semantic: SCNGeometrySourceSemanticTexcoord,
//                  vectorCount: texcoord.count, floatComponents: true,
//                  componentsPerVector: 2, bytesPerComponent: sizeof(Float),
//                  dataOffset: 0, dataStride: sizeof(float2)
//        )
//    }
//}
