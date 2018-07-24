//
//  Shaders.metal
//  RoxigaEngine
//
//  Created by 大西 武 on 2017/06/27.
//  Copyright © 2017年 大西 武. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct
{
	packed_float3 position;
	packed_float3 normal;
	packed_float2 uv;
	float bone;
} vertex_t;

typedef struct
{
	float4 bone0;
	float4 bone1;
	float4 bone2;
	float4 bone3;
} bones;

struct ColorInOut
{
    float4 position [[position]];
    float2 texCoord;
	float3 transformedNormal;
};

vertex ColorInOut vertexShader(device vertex_t* vertex_array [[ buffer(0) ]],
							   device bones*    bone_array   [[ buffer(1) ]],
							   constant Uniforms& uniforms 	 [[ buffer(2) ]],
							   uint   vid    	 			 [[ vertex_id ]])
{
	ColorInOut out;

    float4 position = float4(vertex_array[vid].position, 1.0);
	int boneId = int(vertex_array[vid].bone);
	if (boneId >= 0)
	{
		float4 bone0 = bone_array[boneId].bone0;
		float4 bone1 = bone_array[boneId].bone1;
		float4 bone2 = bone_array[boneId].bone2;
		float4 bone3 = bone_array[boneId].bone3;
		float4x4 bone = float4x4(bone0,bone1,bone2,bone3);
		out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * bone * position;
		float3x3 bone3x3 = float3x3(bone0.xyz,bone1.xyz,bone2.xyz);
		out.transformedNormal = matrix_float3x3(uniforms.normalMatrix) * bone3x3 * vector_float3(vertex_array[vid].normal);
	}
	else
	{
		out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
		out.transformedNormal = matrix_float3x3(uniforms.normalMatrix) * vector_float3(vertex_array[vid].normal);
	}
    out.texCoord = vertex_array[vid].uv;
	
    return out;
}

fragment float4 fragmentShader(ColorInOut in 		   		  [[ stage_in   ]],
                               texture2d<half> texture 		  [[ texture(0) ]],
							   sampler texSampler      		  [[ sampler(0) ]],
							   const constant float4& diffuse [[ buffer(0)  ]])
{
	float3 lightDirection = normalize(float3(-400,-200,-500));
	float3 normal = normalize(in.transformedNormal);
	float lightWeighting = dot(normal,lightDirection);
	if ( lightWeighting < 0.4 )
	{
		lightWeighting = 0.2;
	}
	else if ( lightWeighting < 0.8 )
	{
		lightWeighting = 0.6;
	}
	else
	{
		lightWeighting = 1;
	}
	if ( diffuse.x < 0 )
	{
		return float4(texture.sample(texSampler, in.texCoord.xy)*lightWeighting);
	}
	else
	{
		return float4(diffuse*lightWeighting);
	}
}
