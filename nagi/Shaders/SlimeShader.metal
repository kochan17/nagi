#include <metal_stdlib>
using namespace metal;

// Uniform buffer matching FluidUniforms in Swift
struct FluidUniforms {
    float2 resolution;
    float2 touch;
    float2 touchVelocity;
    float touchActive;
    float dt;
    float viscosity;
    float diffusion;
    float time;
    float3 tint;
};

// MARK: - Image-based slime renderer
//
// Samples a pre-loaded texture image and applies:
// 1. Touch-based UV displacement (push surface away from touch like pressing)
// 2. Specular highlight at touch point (wet/glossy feel)
// 3. Soft dark shadow ring around touch (depth/indent feel)
// 4. Ripple wave propagating from touch
//
// The texture is bound at [[texture(2)]].

kernel void slime_render(
    texture2d<float, access::write>  output    [[texture(0)]],
    texture2d<float, access::sample> material  [[texture(2)]],
    constant FluidUniforms &u                  [[buffer(0)]],
    uint2 gid                                  [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    constexpr sampler textureSampler(filter::linear, address::repeat);

    // Normalized UV, aspect-corrected
    float2 uv = float2(gid) / u.resolution;
    float aspect = u.resolution.x / u.resolution.y;
    float2 aspectUV = float2(uv.x * aspect, uv.y);

    // Touch position in aspect-corrected space
    float2 touchUV = u.touch / u.resolution;
    float2 touchAspect = float2(touchUV.x * aspect, touchUV.y);

    float2 toTouch = aspectUV - touchAspect;
    float dist = length(toTouch);

    // Touch deformation (press indent)
    float pressStrength = 0.0;
    if (u.touchActive > 0.5) {
        float pressRadius = 0.12;
        pressStrength = exp(-dist * dist / (pressRadius * pressRadius));
    }

    // Ripple wave expanding from touch
    float rippleWave = 0.0;
    if (u.touchActive > 0.5) {
        float rippleTime = fmod(u.time, 2.0);
        float rippleRadius = rippleTime * 0.3;
        float ring = exp(-pow((dist - rippleRadius) * 10.0, 2.0));
        rippleWave = ring * (1.0 - rippleTime * 0.5);
    }

    // UV displacement toward touch
    float2 dir = normalize(toTouch + float2(0.0001));
    float2 displacement = dir * (pressStrength * 0.02 + rippleWave * 0.015);
    float2 sampleUV = uv + displacement;

    // Very subtle idle drift
    sampleUV += float2(sin(u.time * 0.1) * 0.002, cos(u.time * 0.08) * 0.002);

    // Sample the material texture
    float3 baseColor = material.sample(textureSampler, sampleUV).rgb;

    // Surface normal estimation via touch dome
    float3 normal = float3(0, 0, 1);
    if (u.touchActive > 0.5 && pressStrength > 0.01) {
        float2 domeNormal = -toTouch * pressStrength * 8.0;
        normal = normalize(float3(domeNormal.x, domeNormal.y, 1.0 - pressStrength));
    }

    // Simple directional light from upper-left
    float3 lightDir = normalize(float3(-0.4, -0.6, 0.8));
    float NdotL = max(0.0, dot(normal, lightDir));

    float3 litColor = baseColor * (0.7 + 0.6 * NdotL);

    // Specular highlight at touch (finger-wet look)
    if (u.touchActive > 0.5) {
        float specIntensity = exp(-dist * dist / 0.002) * 1.2;
        litColor += float3(1.0, 0.95, 0.85) * specIntensity;

        float halo = exp(-dist * dist / 0.02) * 0.3;
        litColor += float3(0.9, 0.95, 1.0) * halo;
    }

    // Shadow ring (depth around indent)
    if (u.touchActive > 0.5) {
        float shadowRing = smoothstep(0.06, 0.10, dist) * smoothstep(0.14, 0.10, dist);
        litColor *= (1.0 - shadowRing * 0.4);
    }

    // Color tint for variants
    litColor *= u.tint;

    // ACES tonemapping
    float3 x = litColor;
    litColor = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    // Gamma correction
    litColor = pow(saturate(litColor), float3(1.0 / 2.2));

    // Soft vignette
    float2 vignetteUV = uv - 0.5;
    float vignette = 1.0 - dot(vignetteUV, vignetteUV) * 0.4;
    litColor *= vignette;

    output.write(float4(litColor, 1.0), gid);
}
