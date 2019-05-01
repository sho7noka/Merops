//
//  Lighting.metal
//


#include "Common.metal"

fragment
half4 fragmentLight(VertexOut in [[stage_in]], texture2d <half> diffuseTexture [[texture(0)]])
{
    constexpr sampler defaultSampler;
    float lt = saturate(dot(in.normal, lightDirection));
    if (lt < 0.1)
        lt = 0.1;
    half4 color = diffuseTexture.sample(defaultSampler, float2(in.texcoord)) * lt;
    return color;
};

fragment
half4 fragmentLightAdd(VertexOut in [[stage_in]], texture2d <half> diffuseTexture [[texture(0)]])
{
    constexpr sampler defaultSampler;
    half4 color = diffuseTexture.sample(defaultSampler, float2(in.texcoord));
    if (color.a < 0.5)
        discard_fragment();

    return color;
};

fragment
half4 fragmentLightNonl(VertexOut in [[stage_in]], texture2d <half> diffuseTexture [[texture(0)]])
{
    constexpr sampler defaultSampler;
    half4 color = diffuseTexture.sample(defaultSampler, float2(in.texcoord));
    if (color.a < 0.5)
        discard_fragment();

    return color;
};

struct
VertexInExplosion {
    float4 position [[position]];
    float size;
    float len;
    float gain;
    float dummy;
};

struct
VertexOutExplosion {
    float4 position [[position]];
    float size   [[point_size]];
    float gain;
    float2 option;
};

vertex
VertexOutExplosion lambertVertexExplosion(uint vid [[vertex_id]],
                                          constant VertexInExplosion *vin  [[buffer(0)]],
                                          constant VertexUniforms &uniforms [[buffer(1)]])
{
    VertexOutExplosion outVertex;
    float4 _p = vin[0].len * vin[vid].position;
    _p.w = 1;
    outVertex.position = uniforms.projectionViewMatrix * _p;
    float _s = vin[vid].size;
    outVertex.size = _s / outVertex.position.z * vin[0].gain;
    outVertex.gain = vin[0].gain;
    return outVertex;
};

fragment
half4 fragmentLightExplosion(VertexOutExplosion vert [[stage_in]],
                             float2 uv [[point_coord]],
                             texture2d<half>diffuseTexture [[texture(0)]])
{
    float2 uvPos = uv;
    constexpr sampler defaultSampler;
    half4 color = diffuseTexture.sample(defaultSampler, float2(uvPos));
    color *= vert.gain;
    return color;
};

struct
VertexInLine {
    float4 position [[position]];
};

struct
VertexOutLine {
    float4 position [[position]];
};

vertex
VertexOutLine lambertVertexLine(uint vid [[vertex_id]],
                                constant VertexInLine *vin [[buffer(0)]],
                                constant VertexUniforms &uniforms [[buffer(1)]])
{
    VertexOutLine out;
    out.position = uniforms.projectionViewMatrix * vin[vid].position;
    return out;
};

fragment
half4 fragmentLightLine(VertexOutExplosion vert [[stage_in]],
                        float2 uv[[point_coord]],
                        texture2d<half> diffuseTexture [[texture(0)]])
{
    return half4(1, 1, 1, 1);
};
