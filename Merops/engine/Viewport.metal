//
//  Viewport.metal
//  Merops
//
//  Created by sho sumioka on 2019/01/14.
//  Copyright © 2019 sho sumioka. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

fragment float4
vertex_fil() {
    return float4(1, 0, 0, 1);
}

fragment float4
line_fil() {
    return float4(0, 1, 0, 1);
}

fragment float4
face_fill() {
    return float4(0, 0, 1, 1);
}

