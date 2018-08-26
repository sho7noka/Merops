//
//  wrapPybind.m
//  Merops
//
//  Created by sho sumioka on 2018/08/01.
//  Copyright © 2018 sho sumioka. All rights reserved.
//

#include <Foundation/Foundation.h>
#include <ModelIO/MDLMesh.h>
#include <pybind11/pybind11.h>

int add(int i, int j) {
    return i + j;
}

// bind
namespace py = pybind11;

PYBIND11_MODULE(merops, m) {
    m.doc() = "pybind11 example plugin"; // optional module docstring
    
    m.def("add", &add, "A function which adds two numbers");
}
