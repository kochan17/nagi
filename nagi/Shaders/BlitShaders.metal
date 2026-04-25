#include <metal_stdlib>
using namespace metal;

struct BlitVertex {
    float4 position [[position]];
    float2 texCoord;
};

// Full-screen quad: 4 vertices as triangle strip
vertex BlitVertex blit_vertex(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1, -1),
        float2( 1, -1),
        float2(-1,  1),
        float2( 1,  1)
    };

    float2 texCoords[4] = {
        float2(0, 1),
        float2(1, 1),
        float2(0, 0),
        float2(1, 0)
    };

    BlitVertex out;
    out.position = float4(positions[vertexID], 0, 1);
    out.texCoord = texCoords[vertexID];
    return out;
}

fragment float4 blit_fragment(
    BlitVertex in [[stage_in]],
    texture2d<float> tex [[texture(0)]]
) {
    constexpr sampler s(filter::linear);
    return tex.sample(s, in.texCoord);
}
