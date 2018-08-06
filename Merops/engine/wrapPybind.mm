//
//  wrapPybind.m
//  Merops
//
//  Created by sho sumioka on 2018/08/01.
//  Copyright © 2018 sho sumioka. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <pybind11/pybind11.h>

namespace py = pybind11;

int add(int i, int j) {
    return i + j;
}

PYBIND11_MODULE(example, m) {
    m.doc() = "pybind11 example plugin"; // optional module docstring
    
    m.def("add", &add, "A function which adds two numbers");
}
