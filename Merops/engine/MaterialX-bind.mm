//
//  driverMatX.cpp
//  KARAS
//
//  Created by sumioka-air on 2018/05/22.
//  Copyright © 2018年 sho sumioka. All rights reserved.
//

#import "MaterialX-bind.h"
#import <MaterialXCore/Document.h>

void setD() {
    using namespace MaterialX;
//    MaterialX::DocumentPtr doc = MaterialX::createDocument();
//    // Create a node graph with a single image node and output.
//    MaterialX::NodeGraphPtr nodeGraph = doc->addNodeGraph();
//    NodePtr image = nodeGraph->addNode("image");
//    image->setParameterValue("file", "image1.tif", "filename");
//    OutputPtr output = nodeGraph->addOutput();
//    output->setConnectedNode(image);
//    // Create a simple shader interface.
//    NodeDefPtr shader = doc->addNodeDef("shader1", "surfaceshader", "simpleSrf");
//    InputPtr diffColor = shader->setInputValue("diffColor", Color3(1.0));
//    InputPtr specColor = shader->setInputValue("specColor", Color3(0.0));
//    ParameterPtr roughness = shader->setParameterValue("roughness", 0.25f);
//    // Create a material that instantiates the shader.
//    MaterialPtr material = doc->addMaterial();
//    ShaderRefPtr shaderRef = material->addShaderRef("shaderRef1", "simpleSrf");
//    // Bind roughness to a new value within this material.
//    BindParamPtr bindParam = shaderRef->addBindParam("roughness");
//    bindParam->setValue(0.5f);
}
