//
//  Viewport.metal
//  Merops
//
//  Created by sho sumioka on 2019/01/14.
//  Copyright © 2019 sho sumioka. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

fragment float4
vertex_fill() {
    return float4(1, 0, 0, 1);
}

fragment float4
line_fill() {
    return float4(0, 1, 0, 1);
}

fragment float4
face_fill() {
    return float4(0, 0, 1, 1);
}

struct
PVertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal   [[attribute(SCNVertexSemanticNormal)]];
};

struct
PVertexOut {
    float4 position [[position]];
    float4 color;
    float3 normal;
};

struct
FVertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal   [[attribute(SCNVertexSemanticNormal)]];
};

struct
FVertexOut {
    float4 position [[position]];
    float4 color;
    float3 normal;
};

struct
lVertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal   [[attribute(SCNVertexSemanticNormal)]];
};

struct
lVertexOut {
    float4 position [[position]];
    float4 color;
    float3 normal;
};

struct
lNodeConstants {
    float4x4 modelViewProjectionTransform;
    float4x4 normalTransform;
};

vertex
lVertexOut outline_vertex(lVertexIn in [[stage_in]],
                          constant lNodeConstants &scn_node [[buffer(1)]])
{
    float3 modelNormal = normalize(in.normal);
    float3 modelPosition = in.position;
    const float extrusionMagnitude = 0.05; // Ideally this would scale so as to be resolution and distance independent
    modelPosition += modelNormal * extrusionMagnitude;

    lVertexOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(modelPosition, 1);
    out.color = float4(1, 1, 0, 1);
    out.normal = (scn_node.normalTransform * float4(in.normal, 1)).xyz;
    return out;
}

fragment half4
outline_fragment(lVertexOut in [[stage_in]]) {
    return half4(in.color);
}

vertex
FVertexOut face_vertex(FVertexIn in [[stage_in]],
                       constant lNodeConstants &scn_node [[buffer(1)]])
{
    float3 modelNormal = normalize(in.normal);
    float3 modelPosition = in.position;
    const float extrusionMagnitude = 0.05; // Ideally this would scale so as to be resolution and distance independent
    modelPosition += modelNormal * extrusionMagnitude;
    
    FVertexOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(modelPosition, 1);
    out.color = float4(1, 1, 0, 1);
    out.normal = (scn_node.normalTransform * float4(in.normal, 1)).xyz;
    return out;
}

fragment half4
face_fragment(FVertexOut in [[stage_in]]) {
    return half4(in.color);
}

vertex
PVertexOut point_vertex(PVertexIn in [[stage_in]],
                       constant lNodeConstants &scn_node [[buffer(1)]])
{
    float3 modelNormal = normalize(in.normal);
    float3 modelPosition = in.position;
    const float extrusionMagnitude = 0.05; // Ideally this would scale so as to be resolution and distance independent
    modelPosition += modelNormal * extrusionMagnitude;
    
    PVertexOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(modelPosition, 1);
    out.color = float4(1, 1, 0, 1);
    out.normal = (scn_node.normalTransform * float4(in.normal, 1)).xyz;
    return out;
}

fragment half4
point_fragment(PVertexOut in [[stage_in]]) {
    return half4(in.color);
}





struct
VertexIn {
    float3 position  [[attribute(SCNVertexSemanticPosition)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct
VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

// 自前定義
struct
NodeConstants {
    float4x4 modelTransform;
    float4x4 modelViewProjectionTransform;
};

vertex
VertexOut sky_vertex(VertexIn in [[stage_in]],
                     constant NodeConstants &scn_node [[buffer(1)]])
{
    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1);
    out.texCoords = in.texCoords;
    return out;
}

fragment half4
sky_fragment(VertexOut in [[stage_in]],
             texture2d<float, access::sample> skyTexture [[texture(0)]],
             constant SCNSceneBuffer &scn_frame [[buffer(0)]],
             constant float &timeOfDay [[buffer(2)]])
{
    constexpr sampler skySampler(coord::normalized, address::repeat, filter::linear);
    float2 skyCoords(timeOfDay, in.texCoords.y);
    float4 skyColor = skyTexture.sample(skySampler, skyCoords);
    return half4(half3(skyColor.rgb), 1);
}
