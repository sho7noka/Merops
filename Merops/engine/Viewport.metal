//
//  Viewport.metal
//  Merops
//
//  Created by sho sumioka on 2019/01/14.
//  Copyright © 2019 sho sumioka. All rights reserved.
//

#include "Common.metal"

/// - Tag: Mouse
vertex
float4 vertex_main(const VertexIn4 vertex_in [[ stage_in ]]) {
    return vertex_in.position;
}

fragment
float4 fragment_main() {
    return float4(1, 0, 0, 1);
}

kernel
void compute(texture2d<float, access::write> output [[texture(0)]],
             constant float2 &mouse [[buffer(1)]],
             device float2 *out [[buffer(2)]],
             uint2 gid [[thread_position_in_grid]])
{
    out[0] = mouse[0];
    out[1] = mouse[1];
    output.write(float4(0, 0.5, 0.5, 1), gid);
}

/// - Tag: DrawOverride
struct
VertexIn {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal   [[attribute(SCNVertexSemanticNormal)]];
};

vertex
VertexOut outline_vertex(VertexIn in [[stage_in]], constant NodeConstants &scn_node [[buffer(1)]]) {
    float3 modelNormal = normalize(in.normal);
    float3 modelPosition = in.position;
    const float extrusionMagnitude = 0.05; // Ideally this would scale so as to be resolution and distance independent
    modelPosition += modelNormal * extrusionMagnitude;

    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(modelPosition, 1);
    out.wireColor = fill_line;
    out.normal = (scn_node.normalTransform * float4(in.normal, 1)).xyz;
    return out;
}

fragment
half4 outline_fragment(VertexOut in [[stage_in]]) {
    return half4(in.wireColor);
}

vertex
VertexOut face_vertex(VertexIn in [[stage_in]], constant NodeConstants &scn_node [[buffer(1)]]) {
    float3 modelNormal = normalize(in.normal);
    float3 modelPosition = in.position;
    const float extrusionMagnitude = 0.05; // Ideally this would scale so as to be resolution and distance independent
    modelPosition += modelNormal * extrusionMagnitude;
    
    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(modelPosition, 1);
    out.wireColor = fill_vertex;
    out.normal = (scn_node.normalTransform * float4(in.normal, 1)).xyz;
    return out;
}

fragment
half4 face_fragment(VertexOut in [[stage_in]]) {
    return half4(in.wireColor);
}

vertex
VertexOut point_vertex(VertexIn in [[stage_in]], constant NodeConstants &scn_node [[buffer(1)]]) {
    float3 modelNormal = normalize(in.normal);
    float3 modelPosition = in.position;
    const float extrusionMagnitude = 0.05; // Ideally this would scale so as to be resolution and distance independent
    modelPosition += modelNormal * extrusionMagnitude;
    
    VertexOut out;
    out.pointsize = 10.0;
    out.position = scn_node.modelViewProjectionTransform * float4(modelPosition, 1);
    out.wireColor = fill_vertex;
    out.normal = (scn_node.normalTransform * float4(in.normal, 1)).xyz;
    return out;
}

fragment
half4 point_fragment(VertexOut in [[stage_in]]) {
    return half4(in.wireColor);
}


/// - Tag: BG & Grid
// https://developer.apple.com/documentation/scenekit/scnprogram
vertex
VertexOut sky_vertex(VertexInput in [[stage_in]], constant NodeConstants &scn_node [[buffer(1)]])
{
    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1);
    out.texcoord = in.texcoord;
    return out;
}

fragment
half4 sky_fragment(VertexOut in [[stage_in]],
             texture2d<float, access::sample> skyTexture [[texture(0)]],
             constant SCNSceneBuffer &scn_frame [[buffer(0)]],
             constant float &timeOfDay [[buffer(2)]])
{
    constexpr sampler skySampler(coord::normalized, address::repeat, filter::linear);
    float2 skyCoords(timeOfDay, in.texcoord.y);
    float4 skyColor = skyTexture.sample(skySampler, skyCoords);
    return half4(half3(skyColor.rgb), 1);
}

//vertex
//VertexOut grid_vertex(VertexInput in [[stage_in]])
//{
//    VertexOut out;
//    out.position = in.position;
//    out.texcoord = in.texcoord;
//    return out;
//}

//https://qiita.com/edo_m18/items/5e03f7fa317b922b5a42#gl_fragcoord相当の処理
//fragment
//half4　grid_fragment(VertexOut in [[stage_in]], constant Uniform uniforms [[buffer(0)]]){
//https://www.geeks3d.com/hacklab/20180611/demo-simple-2d-grid-in-glsl/
//    varying vec4 v_uv;
//    uniform vec4 params;
//
//    float grid(vec2 st, float res);
//
//    float2 grid = fract(st * res);
//    step(res, grid.x) * step(res, grid.y);
//
//    float2 grid_uv = float4.xy * params.x; // scale
//    float x = grid(grid_uv, params.y); // resolution
//    return float4(float3(0.5) * x, 1.0);
    
////    float2 pos = gl_FragCoord.xy;
//    float2 resolution = float2(uniforms.resolution[0], uniforms.resolution[1]);
//    float x = pos.x - (resolution.x/2.0);
//    float y = pos.y - (resolution.y/2.0);
//
//    float3 color = float3(sin((pos.x * 100.0)/7500.0)/4.0 + 0.5);
//
//    color += float3(sin((pos.y * 100.0)/7500.0)/4.0 + 0.5);
//
//    if (fmod(pos.x, 40.0) > 0.5 && fmod(pos.y, 40.0) > 0.5)
//    color = float3(0.5);
//
//    return half4(color, 1.0);
//    return fill_vertex;
//}
