//
//  TessellationShader.metal
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/29.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

#include "Common.metal"

typedef VertexInput ControlPoint;


struct PatchIn {
    patch_control_point <ControlPoint> controlPoints;
};

struct TessellationUniforms {
    float phongFactor;
    float displacementFactor;
    float displacementOffset;
};

struct PhongPatch {
    float termIJ;
    float termJK;
    float termIK;
};

float3 PI(ControlPoint q, ControlPoint I);

kernel void tessellationFactorsCompute(constant float2 &

factor [[buffer(0)]],
device MTLTriangleTessellationFactorsHalf
* factors [[buffer(1)]]) {
    factors[0].edgeTessellationFactor[0] = factor.x;
    factors[0].edgeTessellationFactor[1] = factor.x;
    factors[0].edgeTessellationFactor[2] = factor.x;
    factors[0].insideTessellationFactor = factor.y;
}

[[patch(triangle, 3)]]
vertex VertexOut
tessellationTriangleVertex(PatchIn
patchIn [[stage_in]],
constant VertexUniforms
& uniforms [[buffer(1)]],
constant TessellationUniforms
& tessellation [[buffer(2)]],
float3 patchCoord [[position_in_patch]]
) {
auto u = patchCoord.x;
auto v = patchCoord.y;
auto w = patchCoord.z;
auto uu = u * u;
auto vv = v * v;
auto ww = w * w;

auto I = patchIn.controlPoints;
auto t = tessellation.phongFactor;

auto position = I[0].position * ww + I[1].position * uu + I[2].position * vv
        + w * u * (PI(I[0], I[1]) + PI(I[1], I[0]))
        + u * v * (PI(I[1], I[2]) + PI(I[2], I[1]))
        + v * w * (PI(I[2], I[0]) + PI(I[0], I[2]));

position = position * t + (I[0].position * w + I[1].position * u + I[2].position * v) * (1 - t);

auto normal = I[0].normal * w + I[1].normal * u + I[2].normal * v;
normal = normalize(normal);
auto texcoord = I[0].texcoord * w + I[1].texcoord * u + I[2].texcoord * v;

VertexOut out;
out.
position = uniforms.projectionViewMatrix * float4(position, 1);
out.
texcoord = texcoord;
out.
normal = uniforms.normalMatrix * normal;
out.
wireColor = uniforms.wireColor;
return
out;
}

[[patch(triangle, 3)]]
vertex VertexOut
displacementTriangleVertex(PatchIn
patchIn [[stage_in]],
constant VertexUniforms
& uniforms [[buffer(1)]],
constant TessellationUniforms
& tessellation [[buffer(2)]],
float3 patchCoord [[position_in_patch]],
        texture2d<float, access::sample>
texture [[texture(0)]]) {
auto u = patchCoord.x;
auto v = patchCoord.y;
auto w = patchCoord.z;
auto uu = u * u;
auto vv = v * v;
auto ww = w * w;

auto I = patchIn.controlPoints;
auto t = tessellation.phongFactor;

auto position = I[0].position * ww + I[1].position * uu + I[2].position * vv
        + w * u * (PI(I[0], I[1]) + PI(I[1], I[0]))
        + u * v * (PI(I[1], I[2]) + PI(I[2], I[1]))
        + v * w * (PI(I[2], I[0]) + PI(I[0], I[2]));

position = position * t + (I[0].position * w + I[1].position * u + I[2].position * v) * (1 - t);

auto normal = I[0].normal * w + I[1].normal * u + I[2].normal * v;
normal = normalize(normal);
auto texcoord = I[0].texcoord * w + I[1].texcoord * u + I[2].texcoord * v;

constexpr sampler defaultSampler;
auto disp = (texture.sample(defaultSampler, texcoord).r) * tessellation.displacementFactor;
disp += tessellation.
displacementOffset;
position +=
position *disp;

VertexOut out;
out.
position = uniforms.projectionViewMatrix * float4(position, 1);
out.
texcoord = texcoord;
out.
normal = uniforms.normalMatrix * normal;
out.
wireColor = uniforms.wireColor;
return
out;
}

float3 PI(ControlPoint q, ControlPoint I) {
    return q.position - dot(q.position - I.position, I.normal) * I.normal;
}
