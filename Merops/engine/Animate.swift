//
//  KAnimation.swift
//  KARAS
//
//  Created by sumioka-air on 2017/08/20.
//  Copyright © 2017年 sho sumioka. All rights reserved.
//

import SceneKit
import Metal
import MetalKit

func loadAnim(baseNode: SCNNode) {
    let url = Bundle.main.url(forResource: "art.scnassets/boss_attack", withExtension: "dae")
    let sceneSource = SCNSceneSource(url: url!, options: [
        SCNSceneSource.LoadingOption.animationImportPolicy: SCNSceneSource.AnimationImportPolicy.doNotPlay
    ])

    let attackAnimation: CAAnimation = sceneSource!.entryWithIdentifier(
            "attackID", withClass: CAAnimation.self
    )!
    attackAnimation.fadeInDuration = 0.3
    attackAnimation.fadeOutDuration = 0.3

    baseNode.addAnimation(attackAnimation, forKey: "attackID")
}

func animMopher() {
    let scene = SCNScene()
    let o1 = scene.rootNode.childNode(withName: "o", recursively: true)!

    let a2 = CABasicAnimation.init(keyPath: "morpher.weights[0]")
    a2.fromValue = 0.0
    a2.toValue = 1.0
    a2.duration = 0.5
    a2.beginTime = 1.0
    a2.autoreverses = true
    a2.repeatCount = .infinity

    o1.addAnimation(a2, forKey: nil)
}

func keyMorpher() {
    let scene = SCNScene()
    let o1 = scene.rootNode.childNode(withName: "o", recursively: false)!
    o1.morpher?.setWeight(1.0, forTargetAt: 0)
}

func ikconstraint(shoulderNode: SCNNode, handNode: SCNNode) {
    let ik: SCNIKConstraint = SCNIKConstraint.inverseKinematicsConstraint(
            chainRootNode: shoulderNode
    )
    handNode.constraints = [ik]
    ik.targetPosition = SCNVector3(2, 0, 2)
}

class Bone : SCNNode {
    
    func setBoneArray(array: [SCNNode]) {
        
    }
}

//class BoneMgr {
//    static func makeSkinningVertexBuffer(device: MTLDevice, originalVertexBuffer: inout MTLBuffer, rootBone root: Bone) -> MTLBuffer {
//        let c:Float = 16
//        var boneArray = [Bone]()
//        root.setBoneArray(array: &boneArray)
//
//        let pOriBuffer = originalVertexBuffer.contents().assumingMemoryBound(to: MeshPoint.self)
//        let vertexCount:Int = originalVertexBuffer.length / MemoryLayout<MeshPoint>.size
//        let ansBuffer = mtlEz.device.makeBuffer(length: MemoryLayout<MeshSkininghPoint>.size * vertexCount, options: [])
//        let pAnsBuffer = ansBuffer?.contents().assumingMemoryBound(to: MeshSkininghPoint.self)
//
//        for j in 0..<vertexCount {
//            pAnsBuffer?.advanced(by: j).pointee.point = pOriBuffer.advanced(by: j).pointee.point
//            //            pAnsBuffer?.advanced(by: j).pointee.point.x *= 0.01
//            //            pAnsBuffer?.advanced(by: j).pointee.point.y *= 0.01
//            //            pAnsBuffer?.advanced(by: j).pointee.point.z *= 0.01
//
//            pAnsBuffer?.advanced(by: j).pointee.normal = pOriBuffer.advanced(by: j).pointee.normal
//            pAnsBuffer?.advanced(by: j).pointee.texcoord = pOriBuffer.advanced(by: j).pointee.texcoord
//
//            let x = pAnsBuffer?.advanced(by: j).pointee.point.x
//            let y = pAnsBuffer?.advanced(by: j).pointee.point.y
//            let z = pAnsBuffer?.advanced(by: j).pointee.point.z
//            for i in 0..<boneArray.count {
//                boneArray[i].calcDistanceByPoint(point: float3(x!, y!, z!))
//            }
//
//            var num1 = 0
//            var shortBone1 = boneArray[num1]
//            for i in num1+1..<boneArray.count {
//                if shortBone1.distance > boneArray[i].distance {
//                    shortBone1 = boneArray[i]
//                    num1 = i
//                }
//            }
//            var num2 = 0
//            if num1 == 0 { num2 = 1 }
//            var shortBone2 = boneArray[num2]
//            for i in num2+1..<boneArray.count {
//                if i == num1 { continue }
//                if shortBone2.distance > boneArray[i].distance {
//                    shortBone2 = boneArray[i]
//                    num2 = i
//                }
//            }
//            let wd1 = 1.0/pow(shortBone1.distance + 0.01, c)
//            let wd2 = 1.0/pow(shortBone2.distance + 0.01, c)
//            let add = wd1 + wd2
//            let w1 = wd1 / add
//            let w2 = wd2 / add
//            pAnsBuffer?.advanced(by: j).pointee.param = myfloat4(x: Float(num1), y: w1, z: Float(num2), w: w2)
//        }
//        return ansBuffer!
//    }
//}
