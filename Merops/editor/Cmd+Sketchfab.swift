//
//  Cmd+WebPolySketchfab.swift
//  KARAS
//
//  Created by sumioka-air on 2018/03/20.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

import Foundation
//import Alamofire

#if os(iOS)

import PolyKit

func search() {
    let query = PolyAssetsQuery(keywords: "Cat", format: Poly3DFormat.obj)
    let polyApi = PolyAPI(apiKey: "Poly API Key is HERE!!!")
    polyApi.assets(with: query) { (result) in
        switch result {
        case .success(let assets):
            self.dataSource.assets = assets.assets ?? []
        case .failure(_):
            self.showFetchFailedAlert()
        }
    }
}

func download() {
    let asset: PolyAsset = ""
    // Download obj and mtl files from Poly
    asset.downloadObj { (result) in
        switch result {
        case .success(let localUrl):
            let mdlAsset = MDLAsset(url: localUrl)
            mdlAsset.loadTextures()
            let node = SCNNode(mdlObject: mdlAsset.object(at: 0))
                // do something with node
        case .failure(let error):
            debugPrint(#function, "error", error)
        }
    }
}

#endif
