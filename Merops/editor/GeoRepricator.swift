//
//  GeoRepricator.swift
//  KARAS
//
//  Created by sumioka-air on 2018/04/14.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

import SceneKit

class SCNReplicatorNode: SCNNode, SCNNodeRendererDelegate {

    init(geometry: SCNGeometry, positions: [SCNVector3], normals: [SCNVector3] = [], upVector: SCNVector3 = SCNVector3(0, 1, 0), localFrontVector: SCNVector3 = SCNVector3(0, 0, 1)) {
        super.init()

        let baseNode = SCNNode(geometry: geometry)

        for i in 0..<positions.count {
            // Position
            baseNode.position = positions[i]

            // Normals
            if !normals.isEmpty {
                let pos = SCNVector3(
                        positions[i].x + normals[i].x,
                        positions[i].y + normals[i].y,
                        positions[i].z + normals[i].z
                )


                baseNode.look(at: pos, up: upVector, localFront: localFrontVector)
            }

            self.addChildNode(baseNode.clone())
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Action
    func replicatorAction(_ action: SCNAction) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].removeAllActions()
            self.childNodes[i].runAction(action)
        }
    }

    func replicatorAction(_ action: SCNAction, delay: Double) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].removeAllActions()
            self.childNodes[i].runAction(
                    SCNAction.sequence([
                        SCNAction.wait(duration: Double(i) * delay),
                        action
                    ])
            )
        }
    }

    // Pivot
    func geometryPivot(_ x: Float, _ y: Float, _ z: Float) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].pivot = SCNMatrix4MakeTranslation(CGFloat(x), CGFloat(y), CGFloat(z))
        }
    }

    // Scale
    func geometryScale(_ x: Float, _ y: Float, _ z: Float) {
        for i in 0..<self.childNodes.count {
            self.childNodes[i].scale = SCNVector3(x, y, z)
        }
    }
}

class SCNPositionVectors {

    init() {
    }

    enum Pivot: Int {
        case center
        case left
        case right
    }

    // Line
    class func line(count: UInt, margin: Double = 1, position: Pivot = .center) -> [SCNVector3] {

        if count == 0 {
            return [SCNVector3Zero]
        }

        var pivot: Double = 0
        switch position {
        case .center:
            pivot = -(Double(count - 1) * margin / 2)
        case .left:
            pivot = 0
        case .right:
            pivot = -(Double(count - 1) * margin)
        }

        var position: [SCNVector3] = []
        for i in 0..<count {
            position.append(SCNVector3(Double(i) * margin + pivot, 0, 0))
        }

        return position
    }

    // Box
    class func box(widthCount: UInt, heightCount: UInt, lengthCount: UInt, margin: Double = 1) -> [SCNVector3] {

        if widthCount == 0 || lengthCount == 0 || heightCount == 0 {
            return [SCNVector3Zero]
        }

        var position: [SCNVector3] = []
        let pivotX = -(Double(widthCount - 1) * margin / 2)
        let pivotY = -(Double(heightCount - 1) * margin / 2)
        let pivotZ = -(Double(lengthCount - 1) * margin / 2)
        for x in 0..<widthCount {
            for y in 0..<heightCount {
                for z in 0..<lengthCount {
                    position.append(SCNVector3(
                            Double(x) * margin + pivotX,
                            Double(y) * margin + pivotY,
                            Double(z) * margin + pivotZ
                    ))
                }
            }
        }

        return position
    }

    // Circle
    class func circle(divide: UInt, radius: Double) -> [SCNVector3] {

        if divide == 0 {
            return [SCNVector3Zero]
        }

        var position: [SCNVector3] = []
        let divideCount = 2.0 * Double.pi / Double(divide)
        for r in 0..<divide {
            position.append(SCNVector3(
                    cos(divideCount * Double(r)) * radius,
                    0,
                    sin(divideCount * Double(r)) * radius
            ))
        }

        return position
    }
}
