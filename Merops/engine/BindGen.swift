//
//  BindGen.swift
//  Merops
//
//  Created by sho sumioka on 2019/04/17.
//  Copyright © 2019 sho sumioka. All rights reserved.
//

import Foundation

private var callback: ((Int)->Void)? = nil
private let number: Int = 123

@_silgen_name("set_callback")
public func setCallback(pointerToCTypesFunction: UnsafeMutablePointer<(Int)->Void>) {
//    print("swift: setting callback")
    callback = pointerToCTypesFunction.pointee
}

@_silgen_name("execute_callback")
public func executeCallback() {
    if let callback = callback {
        let model = Model.init()
        print("swift: executing callback with number ", number, model.name)
//        model._copy()
        callback(number)
    } else {
        print("swift: no callback was set")
    }
}


