//
//  AgoraMetalShader.metal
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 03/05/2023.
//

#include <metal_stdlib>

using namespace metal;

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex mapTexture(unsigned int vertex_id [[ vertex_id ]],
                                       const device packed_float4* vertex_array [[ buffer(0) ]]) {

    float4x4 renderedCoordinates = float4x4(vertex_array[0], vertex_array[1], vertex_array[2], vertex_array[3]);
    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));

    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];

    return outVertex;
}


fragment float4 displayNV12Texture(TextureMappingVertex mappingVertex [[stage_in]],
                                   texture2d<float, access::sample> textureY [[ texture(0) ]],
                                   texture2d<float, access::sample> textureUV [[ texture(1) ]],
                                   constant float &brightness [[buffer(0)]]) {
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    // Modify ycbcrToRGBTransform based on brightness value
    float4x4 ycbcrToRGBTransform = float4x4(float4(brightness, brightness, brightness, 0.0f),
                                            float4(0.0f, -0.3441f * brightness, 1.7720f * brightness, 0.0f),
                                            float4(1.4020f * brightness, -0.7141f * brightness, 0.0f, 0.0f),
                                            float4(-0.7010f * brightness, 0.5291f * brightness, -0.8860f * brightness, 1.0f));

    float4 ycbcr = float4(textureY.sample(colorSampler, mappingVertex.textureCoordinate).r,
                          textureUV.sample(colorSampler, mappingVertex.textureCoordinate).rg, 1.0);
    return ycbcrToRGBTransform * ycbcr;
}


