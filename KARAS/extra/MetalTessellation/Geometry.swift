//
//  Geometry.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/31.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import MetalKit



extension Geometry {
    static func box(withDimensions dimensions: vector_float3, segments: vector_uint3, device: MTLDevice) -> Geometry? {
        let mdlMesh = MDLMesh.newBox(withDimensions: dimensions,
                segments: segments,
                geometryType: .triangles,
                inwardNormals: false,
                allocator: MTKMeshBufferAllocator(device: device))
        return Geometry(withMDLMesh: mdlMesh, device: device)
    }

    static func sphere(withRadii radii: vector_float3, segments: vector_uint2, device: MTLDevice) -> Geometry? {
        let mdlMesh = MDLMesh.newEllipsoid(withRadii: radii,
                radialSegments: Int(segments.x), verticalSegments: Int(segments.y),
                geometryType: .triangles,
                inwardNormals: false,
                hemisphere: false,
                allocator: MTKMeshBufferAllocator(device: device))
        return Geometry(withMDLMesh: mdlMesh, device: device)
    }

    static func triangle(withDimensions dimensions: vector_float3, device: MTLDevice) -> Geometry? {
        let positions: [Vertex] = [
            Vertex(position: float3(-1, -1, 0), normal: float3(0, 0, 1), texcoord: float2(0, 1)),
            Vertex(position: float3(1, -1, 0), normal: float3(0, 0, 1), texcoord: float2(1, 1)),
            Vertex(position: float3(0, 1, 0), normal: float3(0, 0, 1), texcoord: float2(0.5, 0)),
        ]

        let list = positions.map {
            Vertex(position: $0.position * dimensions, normal: $0.normal, texcoord: $0.texcoord)
        }

        return Geometry.makeWith(vertexList: list, device: device)
    }
}

struct FileMesh: MeshObject {
    let fileURL: URL

    let vertexFunctionName: String
    let fragmentFunctionName: String
    let diffuseTextureURL: URL
    let normalMapURL: URL?
    let setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?

    func makeGeometry(renderer: Renderer) -> Geometry? {
        return Geometry(url: fileURL, device: renderer.device)
    }

    static func meshLambert(fileURL: URL, diffuseTextureURL: URL,
                            setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileMesh {
        return FileMesh(fileURL: fileURL,
                vertexFunctionName: "lambertVertex",
                fragmentFunctionName: "lambertFragment",
                diffuseTextureURL: diffuseTextureURL,
                normalMapURL: nil,
                setupBaseMatrix: setupBaseMatrix)
    }

    static func meshNormalMap(fileURL: URL, diffuseTextureURL: URL, normalMapURL: URL,
                              setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileMesh {
        return FileMesh(fileURL: fileURL,
                vertexFunctionName: "bumpVertex",
                fragmentFunctionName: "bumpFragment",
                diffuseTextureURL: diffuseTextureURL,
                normalMapURL: normalMapURL,
                setupBaseMatrix: setupBaseMatrix)
    }

    static func meshDisplacementMap(fileURL: URL, addNormalThreshold: Float? = nil,
                                    diffuseTextureURL: URL,
                                    normalMapURL: URL? = nil, displacementlMapURL: URL,
                                    setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileTessellationMesh {
        return FileTessellationMesh(fileURL: fileURL,
                addNormalThreshold: addNormalThreshold,
                vertexFunctionName: "lambertVertex",
                fragmentFunctionName: "lambertFragment",
                diffuseTextureURL: diffuseTextureURL,
                normalMapURL: normalMapURL,
                displacementMapURL: displacementlMapURL,
                tessellationVertexFunctionName: "displacementTriangleVertex",
                tessellationFragmentFunctionName: "lambertFragment",
                setupBaseMatrix: setupBaseMatrix)
    }
}

struct FileTessellationMesh: TessellationMeshObject {
    let fileURL: URL
    let addNormalThreshold: Float?

    let vertexFunctionName: String
    let fragmentFunctionName: String
    let diffuseTextureURL: URL
    let normalMapURL: URL?
    let displacementMapURL: URL?

    let tessellationVertexFunctionName: String
    let tessellationFragmentFunctionName: String

    func makeGeometry(renderer: Renderer) -> Geometry? {
        return Geometry(url: fileURL, device: renderer.device, addNormalThreshold: addNormalThreshold)
    }

    let setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?
}

struct GeometryMesh: TessellationMeshObject {
    enum Shape {
        case triangle(dimensions: vector_float3)
        case box(dimensions: vector_float3, segments: vector_uint3)
        case sphere(radii: vector_float3, segments: vector_uint2)
    }

    let shapeType: Shape
    let vertexFunctionName: String
    let fragmentFunctionName: String
    let diffuseTextureURL: URL
    let normalMapURL: URL?
    let displacementMapURL: URL?

    let tessellationVertexFunctionName: String
    let tessellationFragmentFunctionName: String

    func makeGeometory(renderer: Renderer) -> Geometry? {
        switch shapeType {
        case .triangle(let dimensions):
            return Geometry.triangle(withDimensions: dimensions, device: renderer.device)
        case .box(let dimensions, let segments):
            return Geometry.box(withDimensions: dimensions, segments: segments, device: renderer.device)
        case .sphere(let radii, let segments):
            return Geometry.sphere(withRadii: radii, segments: segments, device: renderer.device)
        }
    }

    let setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?

    static func meshLambert(shapeType: Shape, diffuseTextureURL: URL,
                            setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> GeometryMesh {
        return GeometryMesh(shapeType: shapeType,
                vertexFunctionName: "lambertVertex",
                fragmentFunctionName: "lambertFragment",
                diffuseTextureURL: diffuseTextureURL,
                normalMapURL: nil,
                displacementMapURL: nil,
                tessellationVertexFunctionName: "tessellationTriangleVertex",
                tessellationFragmentFunctionName: "lambertFragment",
                setupBaseMatrix: setupBaseMatrix)
    }

    static func meshDisplacementMap(shapeType: Shape, diffuseTextureURL: URL,
                                    normalMapURL: URL? = nil, displacementMapURL: URL,
                                    setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> GeometryMesh {
        return GeometryMesh(shapeType: shapeType,
                vertexFunctionName: "lambertVertex",
                fragmentFunctionName: "normalMapFragment",
                diffuseTextureURL: diffuseTextureURL,
                normalMapURL: normalMapURL,
                displacementMapURL: displacementlMapURL,
                tessellationVertexFunctionName: "displacementTriangleVertex",
                tessellationFragmentFunctionName: "normalMapFragment",
                setupBaseMatrix: setupBaseMatrix)
    }
}
