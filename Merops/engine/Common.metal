//
//  Common.metal
//  MetalTessellation
//
//  Created by M.Ike on 2016/09/07.
//  Copyright © 2016年 M.Ike. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct VertexInput {
    float3 position    [[attribute(0)]];
    float3 normal      [[attribute(1)]];
    float2 texcoord    [[attribute(2)]];
};

struct VertexUniforms {
    float4x4 projectionViewMatrix;
    float3x3 normalMatrix;
    float4x4 inverseViewMatrix;
    float4x4 modelMatrix;
    float4 wireColor;
};

struct VertexOut {
    float4 position    [[position]];
    float3 normal;
    float2 texcoord;
    float4 wireColor;
};

struct BumpOut {
    float4 position    [[position]];
    float3 light;
    float3 eye;
    float2 texcoord;
};

#define lightDirection float3(1, -4, -5)
#define lightWorldPosition float3(0.1, -0.577, 0)
#define eyeWorldPosition float3(0.1, 0, 5)
