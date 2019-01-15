//
//  Extensions.swift
//
//  Created by Glenn Crownover on 4/27/15.
//  Copyright (c) 2015 bluejava. All rights reserved.
//
// This is a collection of utilities and extensions that aid in working with SceneKit
// The SCNVector3 extensions were largely copied from Kim Pedersen's SCNVector3Extensions project. Thanks Kim!

import Foundation
import SceneKit

#if os(OSX)
typealias mFloat = Float
#elseif os(iOS)
typealias mFloat = SCNFloat
#endif

class Matrix {
    static func perspective(fovyRadians: mFloat, aspect: mFloat, nearZ: mFloat, farZ: mFloat) -> matrix_float4x4 {
        let ys = 1 / tanf(mFloat(fovyRadians * 0.5))
        let xs = ys / aspect
        let zs = farZ / (nearZ - farZ)
        return matrix_float4x4(columns: (vector_float4(xs, 0, 0, 0),
                vector_float4(0, ys, 0, 0),
                vector_float4(0, 0, zs, -1),
                vector_float4(0, 0, zs * nearZ, 0)))
    }

    static func lookAt(eye: float3, center: float3, up: float3) -> matrix_float4x4 {
        let z = normalize(eye - center)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        let t = float3(-dot(x, eye), -dot(y, eye), -dot(z, eye))
        return matrix_float4x4(columns: (vector_float4(x.x, y.x, z.x, 0),
                vector_float4(x.y, y.y, z.y, 0),
                vector_float4(x.z, y.z, z.z, 0),
                vector_float4(t.x, t.y, t.z, 1)))
    }

    static func rotation(radians: mFloat, axis: float3) -> matrix_float4x4 {
        let normalizeAxis = normalize(axis)
        let ct = cosf(radians)
        let st = sinf(radians)
        let ci = 1 - ct
        let x = normalizeAxis.x
        let y = normalizeAxis.y
        let z = normalizeAxis.z
        return matrix_float4x4(columns: (
                vector_float4(ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                vector_float4(x * y * ci - z * st, ct + y * y * ci, z * y * ci + x * st, 0),
                vector_float4(x * z * ci + y * st, y * z * ci - x * st, ct + z * z * ci, 0),
                vector_float4(0, 0, 0, 1)))
    }

    static func scale(x: mFloat, y: mFloat, z: mFloat) -> matrix_float4x4 {
        return matrix_float4x4(columns: (vector_float4(x, 0, 0, 0),
                vector_float4(0, y, 0, 0),
                vector_float4(0, 0, z, 0),
                vector_float4(0, 0, 0, 1)))
    }

    static func translation(x: mFloat, y: mFloat, z: mFloat) -> matrix_float4x4 {
        return matrix_float4x4(columns: (vector_float4(1, 0, 0, 0),
                vector_float4(0, 1, 0, 0),
                vector_float4(0, 0, 1, 0),
                vector_float4(x, y, z, 1)))
    }

    static func toUpperLeft3x3(from4x4 m: matrix_float4x4) -> matrix_float3x3 {
        let x = m.columns.0
        let y = m.columns.1
        let z = m.columns.2

        return matrix_float3x3(columns: (vector_float3(x.x, x.y, x.z),
                vector_float3(y.x, y.y, y.z),
                vector_float3(z.x, z.y, z.z)))
    }
}

/*
 * The following SCNVector3 extension comes from
 * https://github.com/devindazzle/SCNVector3Extensions - with some changes by me
 */

extension SCNVector3: Equatable {
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
}

extension SCNVector4 {

    var xyzw: [SCNFloat] {
        return [self.x, self.y, self.z, self.w].map({ round($0) })
    }
}

extension SCNVector3 {
    
    var xyz : [SCNFloat] {
        return [self.x, self.y, self.z].map({ round($0) })
    }
    
    func v(_ x: SCNFloat, _ y: SCNFloat, _ z: SCNFloat) -> SCNVector3{
        return SCNVector3(x: x, y: y, z: z)
    }
    
    func negate() -> SCNVector3 {
        return self * -1
    }

    /**
     * Negates the vector described by SCNVector3
     */
    mutating func negated() -> SCNVector3 {
        self = negate()
        return self
    }

    /**
     * Returns the length (magnitude) of the vector described by the SCNVector3
     */
    func length() -> SCNFloat {
        return sqrt(x * x + y * y + z * z)
    }

    /**
     * Negates the vector described by SCNVector3 and returns
     * the result as a new SCNVector3.
     */
    func length²() -> SCNFloat {
        return (x * x) + (y * y) + (z * z)
    }


    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
     * the result as a new SCNVector3.
     */
    func normalized() -> SCNVector3? {

        let len = length()
        if (len > 0) {
            return self / length()
        } else {
            return nil
        }
    }

    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0.
     */
    mutating func normalize() -> SCNVector3? {
        if let vn = normalized() {
            self = vn
            return self
        }
        return nil
    }

    mutating func normalizeOrZ() -> SCNVector3 {
        if let vn = normalized() {
            self = vn
            return self
        }
        return SCNVector3()
    }

    /**
     * Calculates the distance between two SCNVector3. Pythagoras!
     */
    func distance(vector: SCNVector3) -> SCNFloat {
        return (self - vector).length()
    }

    /**
     * Calculates the dot product between two SCNVector3.
     */
    func dot(vector: SCNVector3) -> SCNFloat {
        return x * vector.x + y * vector.y + z * vector.z
    }

    /**
     * Calculates the cross product between two SCNVector3.
     */
    func cross(vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }

    func angle(vector: SCNVector3) -> SCNFloat {
        // angle between 3d vectors P and Q is equal to the arc cos of their dot products over the product of
        // their magnitudes (lengths).
        //	theta = arccos( (P • Q) / (|P||Q|) )
        let dp = dot(vector: vector) // dot product
        let magProduct = length() * vector.length() // product of lengths (magnitudes)
        return acos(dp / magProduct) // DONE
    }

    // Constrains (or reposition) this vector to fall within the specified min and max vectors.
    // Note - this assumes the max vector points to the outer-most corner (farthest from origin) while the
    // min vector represents the inner-most corner of the valid constraint space
    mutating func constrain(min: SCNVector3, max: SCNVector3) -> SCNVector3 {
        if (x < min.x) {
            self.x = min.x
        }
        if (x > max.x) {
            self.x = max.x
        }

        if (y < min.y) {
            self.y = min.y
        }
        if (y > max.y) {
            self.y = max.y
        }

        if (z < min.z) {
            self.z = min.z
        }
        if (z > max.z) {
            self.z = max.z
        }

        return self
    }
}

/**
 * Adds two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

/**
 * Increments a SCNVector3 with the value of another.
 */
func +=(left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

/**
 * Subtracts two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

/**
 * Decrements a SCNVector3 with the value of another.
 */
func -=(left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}

/**
 * Multiplies two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func *(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

/**
 * Multiplies a SCNVector3 with another.
 */
func *=(left: inout SCNVector3, right: SCNVector3) {
    left = left * right
}

/**
 * Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
 * returns the result as a new SCNVector3.
 */
func *(vector: SCNVector3, scalar: SCNFloat) -> SCNVector3 {
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

/**
 * Multiplies the x and y fields of a SCNVector3 with the same scalar value.
 */
func *=(vector: inout SCNVector3, scalar: SCNFloat) {
    vector = vector * scalar
}

/**
 * Divides two SCNVector3 vectors abd returns the result as a new SCNVector3
 */
func /(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    var x = left.x / right.x
    x = x.isNaN ? 0 : x
    var y = left.y / right.y
    y = y.isNaN ? 0 : y
    var z = left.z / right.z
    z = z.isNaN ? 0 : z
    
    return SCNVector3Make(x, y, z)
}

/**
 * Divides a SCNVector3 by another.
 */
func /=(left: inout SCNVector3, right: SCNVector3) {
    left = left / right
}

/**
 * Divides the x, y and z fields of a SCNVector3 by the same scalar value and
 * returns the result as a new SCNVector3.
 */
func /(vector: SCNVector3, scalar: SCNFloat) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}

/**
 * Divides the x, y and z of a SCNVector3 by the same scalar value.
 */
func /=(vector: inout SCNVector3, scalar: SCNFloat) {
    vector = vector / scalar
}

/**
 * Calculates the SCNVector from lerping between two SCNVector3 vectors
 */
func SCNVector3Lerp(vectorStart: SCNVector3, vectorEnd: SCNVector3, t: SCNFloat) -> SCNVector3 {
    return SCNVector3Make(vectorStart.x + ((vectorEnd.x - vectorStart.x) * t), vectorStart.y + ((vectorEnd.y - vectorStart.y) * t), vectorStart.z + ((vectorEnd.z - vectorStart.z) * t))
}

/**
 * Project the vector, vectorToProject, onto the vector, projectionVector.
 */
func SCNVector3Project(vectorToProject: SCNVector3, projectionVector: SCNVector3) -> SCNVector3 {
    let scale: SCNFloat = projectionVector.dot(vector: vectorToProject) / projectionVector.dot(vector: projectionVector)
    let v: SCNVector3 = projectionVector * scale
    return v
}

func SCNVector3ApplyAffineTransform(vector: SCNVector3, _ t: SCNMatrix4) -> SCNVector3 {
    let x = vector.x * t.m11 + vector.y * t.m21 + vector.z * t.m31 + t.m41
    let y = vector.x * t.m12 + vector.y * t.m22 + vector.z * t.m32 + t.m42
    let z = vector.x * t.m13 + vector.y * t.m23 + vector.z * t.m33 + t.m43
    return SCNVector3Make(x, y, z)
}

extension float3 {
    var toFloat4: float4 {
        return float4(self.x, self.y, self.z, 1)
    }
}

func toRad(fromDeg degrees: Float) -> Float {
    return degrees / 180.0 * .pi
}
