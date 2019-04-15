//
//  spy.swift
//  Merops
//
//  Created by sho sumioka on 2019/04/15.
//  Copyright © 2019 sho sumioka. All rights reserved.
//

#if os(OSX)
import Python
#endif

// Some stuff to make writing Swift code easier on you :)
public typealias PythonObject = UnsafeMutablePointer<PyObject>

extension String {
    func toPyString() -> PythonObject {
        let len = Array(self.utf8).count
        return PyString_FromStringAndSize(self, len)
    }
    static func fromPyString(pyString: PythonObject) -> String? {
        let cstring = PyString_AsString(pyString)
        return String.fromCString(cstring)
    }
}



// Actual function for use in python:
public func mystringdoubler(inPyStr: PythonObject) -> PythonObject {
    let instr = String.fromPyString(inPyStr)!
    return "\(instr) \(instr)".toPyString()
}
