//
//  USDObject.swift
//
//  Created by sumioka-air on 2017/03/28.
//  Copyright © 2017年 sho sumioka. All rights reserved.
//

import ModelIO
import SceneKit
import SceneKit.ModelIO
/*
 root __
        |___ master.usd
        |___ geo.abc
        |___ mtl.mtlx
        |___ cam.usd
        |___ light.usd
        |___ skin.usd
        |___ tex.png
 */
final class USDExporter {

    public static func initialize(scene: SCNScene) -> URL {
        scene.rootNode.name = "root"
        let asset = MDLAsset(scnScene: scene)
        let exportFile = userDocument(fileName: "geo.usda")
        gitInit(dir: exportFile.deletingLastPathComponent().path)
        
    #if os(OSX)
        // export with ascii format
        try! asset.exportWriter(to: exportFile, text: "\ndef Cube \"cy\" {\n}")
    #endif
        
        gitCommit(url: exportFile.absoluteString, msg: "export")
        return exportFile
    }

    public static func exportFromAsset(scene: SCNScene) -> MDLAsset {

        // MARK: Y-Up
        let exportFile = USDExporter.initialize(scene: scene)
        let asset = MDLAsset(scnScene: scene)
        asset.upAxis = vector_float3([0, 1, 0])
        
        // add MDLLight and MDLMaterial
        scene.rootNode.enumerateChildNodes({ child, _ in

            // MARK: del
            if child.categoryBitMask == NodeOptions.noExport.rawValue {
                child.removeFromParentNode()
            }

            // MARK: camera
            if (child.camera != nil) {
                child.removeFromParentNode()
            }

            // MARK: light
            if (child.light != nil) {
                let exportFile = userDocument(fileName: "light.usda")
                try! asset.exportWriter(to: exportFile, text: "\ndef Cube \"cy\" {\n}")
            }
            
            // MARK: skin
            if (child.skinner != nil) {
                let exportFile = userDocument(fileName: "skin.usd")
                try! asset.exportWriter(to: exportFile, text: "\ndef Cube \"cy\" {\n}")
            }

            // MARK: material
            if (child.geometry != nil) {
                let scatteringFunction = MDLScatteringFunction()
                let material = MDLMaterial(name: "baseMaterial", scatteringFunction: scatteringFunction)

                // Apply the texture to every submesh of the asset
                for submesh in (MDLMesh(scnGeometry: child.geometry!).submeshes!) {
                    if let submesh = submesh as? MDLSubmesh {
                        submesh.material = material
                    }
                }
            }
        })

        // import from ascii
        scene.rootNode.enumerateChildNodes({ child, _ in
            child.removeFromParentNode()
        })
        let masset = MDLAsset(url: URL(fileURLWithPath: exportFile.path))
//        let object = asset.childObjects(of: MDLMesh.self) as? [MDLMesh]
        return masset
    }

    public static func exportFromText(fileName: String, fileObject: String) {
        do {
            try ("#usda 1.0¥n" + fileObject).write(
                    to: userDocument(fileName: fileName), atomically: true, encoding: String.Encoding.utf8
            )
        } catch {
            // Failed to write file
        }
    }
}

public func write(url: URL, text: String) -> Bool {
    guard let stream = OutputStream(url: url, append: true) else {
        return false
    }
    stream.open()
    
    defer {
        stream.close()
    }
    
    guard let data = text.data(using: .utf8) else {
        return false
    }
    
    let result = data.withUnsafeBytes {
        stream.write($0, maxLength: data.count)
    }
    return (result > 0)
}

public func userDocument(fileName: String) -> URL {
    let documentsPath = NSURL(fileURLWithPath:
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    
    let path = documentsPath.appendingPathComponent("Merops")
    do {
        try FileManager.default.createDirectory(at: path!, withIntermediateDirectories: true, attributes: nil)
    } catch let error as NSError {
        NSLog("Unable to create directory \(error.debugDescription)")
    }
    
    let exportFile = path?.appendingPathComponent(fileName)
    return exportFile!
}

extension MDLAsset {
    func exportWriter(to: URL, text: String) throws {
        try self.export(to: to)
//        USDCat(infile: to.path, outfile: to.path)
        let _ = write(url: to, text: text)
    }
}

extension MDLMaterial {
//    self.setTextureProperties(textures:[.baseColor: "diffuse.png", .specular: "specular.png"])
    func setTextureProperties(textures: [MDLMaterialSemantic: URL]) -> Void {
        for (key, value) in textures {
            let name = value.path
            let property = MDLMaterialProperty(name: name, semantic: key, url: value)
            self.setProperty(property)
        }
    }
}
