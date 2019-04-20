//
// Created by sumioka-air on 2018/05/17.
// Copyright (c) 2018 sho sumioka. All rights reserved.
//

import Foundation
import Metal
import SceneKit
import MetalKit
import simd
//#import <simd/simd.h
//#import <ModelIO/ModelIO.h
//#import <vector>

////static const NSUInteger kMaxBuffersInFlight = 3

class Renderer {
//    let _inFlightSemaphore : dispatch_semaphore_t
    let device: MTLDevice
    var commandQueue: MTLCommandQueue
//    let pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
//    var projectionMatrix: simd_float4x4
//    var models: [RoxigaModel]
//    let sampler: MTLSamplerState

    init? (device : MTLDevice) {
        self.device = device
//        self._inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight)

        let defaultLibrary = device.makeDefaultLibrary()
        
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "MyPipeline"
        pipelineStateDescriptor.sampleCount = 1
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
        pipelineStateDescriptor.stencilAttachmentPixelFormat = MTLPixelFormat.depth32Float_stencil8
        
//        pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = .less
        depthStateDesc.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthStateDesc)!
        commandQueue = device.makeCommandQueue()!

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
    //    _sampler = [_device newSamplerStateWithDescriptor:samplerDescriptor

        let renderbufferAttachment = pipelineStateDescriptor.colorAttachments[0]
        renderbufferAttachment?.isBlendingEnabled = true
        renderbufferAttachment?.rgbBlendOperation = .add
        renderbufferAttachment?.alphaBlendOperation = .add
        renderbufferAttachment?.sourceRGBBlendFactor = .sourceAlpha
        renderbufferAttachment?.sourceAlphaBlendFactor = .sourceAlpha
        renderbufferAttachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderbufferAttachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }

    func loadModel (model: Model) {
//    func loadModel (model : RoxigaModel) -> RoxigaModel {
//        RoxigaModel instance = [model initWithDevice:_device

//        [instance setTexture:_device
//        [instance setColor:_device
//        [instance setMatrixAnimation:_device
//        [instance setUniformBuffer:_device
//        _models.push_back(instance)
//
//        return instance
    }

    func drawInMTKView(device : MTLDevice) {
//        DispatchSemaphore.wait(_inFlightSemaphore)

        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.label = "MyCommand"
//
//        __block dispatch_semaphore_t block_sema = _inFlightSemaphore
//        commandBuffer.addCompletedHandler(buffer) {
//            dispatch_semaphore_signal(block_sema)
//        }
//
        // Delay getting the currentRenderPassDescriptor until we absolutely need it to avoid
        // holding onto the drawable and blocking the display pipeline any longer than necessary
        let renderPassDescriptor = MTLRenderPassDescriptor()
//            simd::float4x4 viewMatrix = AAPL::Math::lookAt(_eye, _center, _up)
            // Final pass rendering code here
//            let colorAttachment = renderPassDescriptor.colorAttachments[0]
//            colorAttachment.clearColor = _bgColor
//
        
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.label = "MyRenderEncoder"
        
//            [renderEncoder pushDebugGroup:"DrawModel"
//            [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise
//            [renderEncoder setCullMode:MTLCullModeBack
//            [renderEncoder setRenderPipelineState:_pipelineState
//            [renderEncoder setDepthStencilState:_depthState
//            [renderEncoder setFragmentSamplerState:_sampler atIndex:0
//
//        for model in models {
//                model.updateDynamicBufferState()
//                model.transform:_projectionMatrix viewMatrix:viewMatrix]
//                model.encoderrenderEncoder()
//            }
//
        renderEncoder?.popDebugGroup()
        renderEncoder?.endEncoding()
//            commandBuffer.presentDrawable(view.currentDrawable)
        commandBuffer?.commit()
    }
}

//
//#import <Metal/Metal.h>
//#import <MetalKit/MetalKit.h>
//#import <simd/simd.h>
//
//#import "RoxigaModel.h"
//#import "ShaderTypes.h"
//#import "AAPLTransforms.h"

import Foundation
import Metal

//class RoxigaModel {

//    let _texture : [MTL]
//    std::vector<std::vector<float>> _vertices;
//    std::vector<std::vector<float>> _matricies;
//    std::vector<id<MTLBuffer>> _vertexBuffer;
//    std::vector<id <MTLBuffer>>  _matrixBuffer;
//    id <MTLBuffer> _dynamicUniformBuffer;
//    std::vector<id<MTLBuffer>> _colorBuffer;
//    uint32_t _uniformBufferOffset;
//    uint8_t _uniformBufferIndex;
//    void* _uniformBufferAddress;
//    std::vector<NSString*> _textureName;
//    std::vector<simd::float4> _diffuse;
//    std::vector<uint32_t> _vertexSize;
//    uint32_t _animationSize;
//    float _time;
//    Uniforms * _uniforms;
//}

//static const NSUInteger kMaxBuffersInFlight = 3;
//static const size_t kAlignedUniformsSize = (sizeof(Uniforms) & ~0xFF) + 0x100;

//-(instancetype)
//do {
//    super.init()
//    for i in 0..<vertices.size() {
//        vertexBuffer.push_back(device.makeBuffer(bytes: vertices[i].data(), length: uint32_t(vertices[i].size() * MemoryLayout<Float>.size), options: []))
//        vertexSize.push_back(uint32_t(vertices[i].size() / 9))
//    }
//    time = 0
//    visible = true
//    currentAnimation = 0
//    isPlaying = true
//    loop = true
//    translation = 0.0, 0.0, 0.0
//}
//rotation = 0.0, 0.0, 0.0
//
//
//- (void)setMaterial:(NSString *)texture r:(float)red g:(float)green b:(float)blue a:(float)alpha {
//    _textureName.push_back(texture);
//    if (texture.length > 0) red = -1;
//    simd::float4 diffuse = {red, green, blue, alpha};
//    _diffuse.push_back(diffuse);
//}
//
//- (void)setTexture:(id <MTLDevice>)device {
//    NSError *error;
//    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];
//    for (int i = 0; i < _textureName.size(); ++i) {
//        if (_textureName[i].length > 0) {
//            NSString *path = [[NSBundle mainBundle] pathForResource:_textureName[i]
//                                                             ofType:@""];
//            _texture.push_back([textureLoader newTextureWithContentsOfURL:[NSURL fileURLWithPath:path]
//                                                                  options:nil
//                                                                    error:&error]);
//            if (!_texture[i] || error) {
//                NSLog(@"Error creating texture %@", error.localizedDescription);
//            }
//        } else {
//            _texture.push_back(nil);
//        }
//    }
//}
//
//- (void)setColor:(id <MTLDevice>)device {
//    for (int i = 0; i < _diffuse.size(); ++i) {
//        _colorBuffer.push_back([device newBufferWithBytes:&_diffuse[i]
//                                                   length:uint32_t(4 * sizeof(float))
//                                                  options:MTLResourceOptionCPUCacheModeDefault]);
//        if (!_colorBuffer.back()) {
//            NSLog(@"Error creating color buffer");
//        }
//    }
//}
//
//- (void)setMatrixAnimation:(id <MTLDevice>)device {
//    if (_maxBonesSize > 0) {
//        _animationSize = uint32_t(_matricies[0].size() / (_maxBonesSize * 16));
//    } else {
//        _matricies = {{1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}};
//        _animationSize = 0;
//    }
//    for (int i = 0; i < _matricies.size(); ++i) {
//        _matrixBuffer.push_back([device newBufferWithBytes:_matricies[i].data()
//                                                    length:uint32_t(_matricies[i].size() * sizeof(float))
//                                                   options:MTLResourceOptionCPUCacheModeDefault]);
//    }
//}
//
//- (void)setUniformBuffer:(id <MTLDevice>)device {
//    NSUInteger uniformBufferSize = kAlignedUniformsSize * kMaxBuffersInFlight;
//    _dynamicUniformBuffer = [device newBufferWithLength:uniformBufferSize
//                                                options:MTLResourceStorageModeShared];
//    _dynamicUniformBuffer.label = @"UniformBuffer";
//}
//
//- (void)encoder:(id <MTLRenderCommandEncoder>)renderEncoder {
//    if (!_visible) return;
//    if (_isPlaying) {
//        _time += 30.0 / 60.0;
//    }
//    if (_time >= _animationSize) {
//        _time = 0;
//        if (!_loop) _isPlaying = false;
//    }
//    for (int i = 0; i < _vertexSize.size(); ++i) {
//        if (_vertexSize[i] <= 0) continue;
//
//        [renderEncoder setVertexBuffer:_vertexBuffer[i]
//                                offset:0
//                               atIndex:0];
//
//        [renderEncoder setVertexBuffer:_matrixBuffer[_currentAnimation]
//                                offset:uint32_t(_maxBonesSize * 16 * (int) (_time) * sizeof(float))
//                               atIndex:1];
//
//        [renderEncoder setVertexBuffer:_dynamicUniformBuffer
//                                offset:_uniformBufferOffset
//                               atIndex:2];
//
//        if (_textureName[i].length > 0) {
//            [renderEncoder setFragmentTexture:_texture[i]
//                                      atIndex:0];
//        }
//
//        [renderEncoder setFragmentBuffer:_colorBuffer[i]
//                                  offset:0
//                                 atIndex:0];
//
//        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
//                          vertexStart:0
//                          vertexCount:_vertexSize[i]];
//    }
//}
//
//- (void)playAnimation:(int)animation loop:(bool)loop {
//    _isPlaying = true;
//    _loop = loop;
//    if (animation < 0) {
//        _currentAnimation = 0;
//    } else if (animation < _matricies.size()) {
//        _currentAnimation = animation;
//    } else {
//        _currentAnimation = 0;
//    }
//    if (_maxBonesSize > 0) {
//        _animationSize = uint32_t(_matricies[_currentAnimation].size() / (_maxBonesSize * 16));
//    } else {
//        _animationSize = 0;
//    }
//    NSLog(@"%d", _animationSize);
//    _time = 0;
//}
//
//- (void)stopAnimation {
//    _isPlaying = false;
//}
//
//- (void)transform:(simd::float4x4)projectionMatrix viewMatrix:(simd::float4x4)viewMatrix {
//    _uniforms = (Uniforms *) _uniformBufferAddress;
//    _uniforms->projectionMatrix = projectionMatrix;
//
//    simd::float4x4 translate = AAPL::Math::translate(_translation);
//    simd::float4x4 rotateX = AAPL::Math::rotateX(_rotation.x);
//    simd::float4x4 rotateY = AAPL::Math::rotateY(_rotation.y);
//    simd::float4x4 rotateZ = AAPL::Math::rotateZ(_rotation.z);
//    simd::float4x4 scale = AAPL::Math::scale(_scaling);
//    simd::float4x4 matrix = rotateX * scale;
//    matrix = rotateY * matrix;
//    matrix = rotateZ * matrix;
//    matrix = translate * matrix;
//    matrix = viewMatrix * matrix;
//    _uniforms->modelViewMatrix = matrix;
//
//    simd::float3x3 normalMatrix = AAPL::Math::toFloat3x3(matrix_invert(matrix));
//    normalMatrix = matrix_transpose(normalMatrix);
//    _uniforms->normalMatrix = normalMatrix;
//}
//
//- (void)updateDynamicBufferState {
//    /// Update the state of our uniform buffers before rendering
//
//    _uniformBufferIndex = (_uniformBufferIndex + 1) % kMaxBuffersInFlight;
//
//    _uniformBufferOffset = kAlignedUniformsSize * _uniformBufferIndex;
//
//    _uniformBufferAddress = ((uint8_t *) _dynamicUniformBuffer.contents) + _uniformBufferOffset;
//}
//
//@end
//
