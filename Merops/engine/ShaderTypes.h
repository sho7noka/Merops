#ifndef ShaderTypes_h
#define ShaderTypes_h

#import <simd/simd.h>

typedef struct
{
	simd::float4x4 projectionMatrix;
	simd::float4x4 modelViewMatrix;
	simd::float3x3 normalMatrix;
} Uniforms;

#endif /* ShaderTypes_h */
