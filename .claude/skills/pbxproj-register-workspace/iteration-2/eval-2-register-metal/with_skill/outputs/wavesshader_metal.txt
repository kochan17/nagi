#include <metal_stdlib>
using namespace metal;

// Same layout as FluidShaders.metal
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

// MARK: - Helpers

static float hash2(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float noise2(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash2(i);
    float b = hash2(i + float2(1.0, 0.0));
    float c = hash2(i + float2(0.0, 1.0));
    float d = hash2(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float fbm2(float2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        v += amp * noise2(p);
        p *= 2.1;
        amp *= 0.5;
    }
    return v;
}

// MARK: - Wave height field
// Simulates N concentric ripple rings originating from touch.
// Each ring has a birth time encoded via a repeating sawtooth so
// a single touch point produces an infinite train of rings.

static float waveHeight(float2 uv, float2 center, float t, float aspect) {
    float2 d = uv - center;
    d.x *= aspect;
    float r = length(d);

    float height = 0.0;
    float numRings = 6.0;
    for (float k = 0.0; k < numRings; k++) {
        float offset = k / numRings;
        float phase = fract(t * 0.4 + offset);      // 0..1 expanding phase
        float radius = phase * 0.55;                  // max travel distance in UV
        float envelope = (1.0 - phase) * (1.0 - phase); // decay
        float wave = sin((r - radius) * 60.0 - phase * 3.14159) * envelope;
        float mask = smoothstep(0.012, 0.0, abs(r - radius)); // thin ring band
        height += wave * mask * 0.8;
    }
    return height;
}

// MARK: - Caustic pattern
// Simple multi-frequency interference to mimic underwater caustics.

static float caustics(float2 uv, float t) {
    float2 p = uv * 6.0;
    float c = 0.0;
    c += sin(p.x * 1.3 + t * 0.7) * cos(p.y * 1.1 - t * 0.5);
    c += sin(p.x * 2.1 - t * 0.4) * cos(p.y * 2.3 + t * 0.6);
    c += sin((p.x + p.y) * 1.7 + t * 0.3) * 0.5;
    c = pow(max(c * 0.33 + 0.5, 0.0), 3.0);
    return c * 0.3;
}

// MARK: - waves_render

kernel void waves_render(
    texture2d<float, access::write> output [[texture(0)]],
    constant FluidUniforms &u              [[buffer(0)]],
    uint2 gid                              [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float2 uv = float2(gid) / u.resolution;          // 0..1
    float aspect = u.resolution.x / u.resolution.y;

    float t = u.time;

    // --- Ambient background ripples (auto-generated, always present) ---
    float2 ambientCenter1 = float2(0.3, 0.4);
    float2 ambientCenter2 = float2(0.7, 0.6);
    float2 ambientCenter3 = float2(0.5, 0.2);

    float ambientH = 0.0;
    ambientH += waveHeight(uv, ambientCenter1, t * 0.6 + 0.0, aspect) * 0.35;
    ambientH += waveHeight(uv, ambientCenter2, t * 0.6 + 0.33, aspect) * 0.35;
    ambientH += waveHeight(uv, ambientCenter3, t * 0.6 + 0.66, aspect) * 0.3;

    // --- Touch ripple ---
    float touchH = 0.0;
    float touchInfluence = 0.0;
    if (u.touchActive > 0.5) {
        float2 touchUV = u.touch / u.resolution;
        touchH = waveHeight(uv, touchUV, t, aspect);
        touchInfluence = 1.0;
    }

    float totalH = ambientH + touchH * touchInfluence;

    // --- Normal from height field (central differences via analytic gradient) ---
    float eps = 1.5 / max(u.resolution.x, u.resolution.y);
    float2 uvR = uv + float2(eps, 0.0);
    float2 uvU = uv + float2(0.0, eps);

    float hR = ambientH + (u.touchActive > 0.5 ? waveHeight(uvR, u.touch / u.resolution, t, aspect) : 0.0);
    float hU = ambientH + (u.touchActive > 0.5 ? waveHeight(uvU, u.touch / u.resolution, t, aspect) : 0.0);

    float3 normal = normalize(float3(totalH - hR, totalH - hU, 0.015));

    // --- Refraction offset (simulate looking through disturbed water surface) ---
    float2 refractOffset = normal.xy * 0.04;
    float2 refractUV = uv + refractOffset;

    // --- Deep water base color (dark teal/navy) ---
    float depthNoise = fbm2(refractUV * 3.0 + float2(t * 0.05, t * 0.04));
    float3 deepColor  = float3(0.01, 0.06, 0.12);  // near-black deep blue
    float3 shallowColor = float3(0.05, 0.22, 0.32); // teal
    float3 waterBase = mix(deepColor, shallowColor, depthNoise * 0.6 + 0.2);

    // --- Specular highlight (sun/light reflection) ---
    float3 lightDir = normalize(float3(0.4, 0.6, 1.0));
    float specular = pow(max(dot(normal, lightDir), 0.0), 48.0);
    float3 specColor = float3(0.8, 0.95, 1.0) * specular * 1.2;

    // --- Caustic light dappling on water floor ---
    float causticVal = caustics(refractUV, t);
    float3 causticColor = float3(0.0, 0.35, 0.45) * causticVal;

    // --- Wave crest foam (white on high positive height) ---
    float crestMask = smoothstep(0.25, 0.6, totalH);
    float3 foamColor = float3(0.85, 0.95, 1.0) * crestMask;

    // --- Touch epicentre glow ---
    float3 touchGlow = float3(0.0);
    if (u.touchActive > 0.5) {
        float2 touchUV = u.touch / u.resolution;
        float2 dTouch = uv - touchUV;
        dTouch.x *= aspect;
        float distToTouch = length(dTouch);
        float innerGlow = exp(-distToTouch * distToTouch / 0.003) * 1.5;
        float outerGlow = exp(-distToTouch * distToTouch / 0.02) * 0.4;
        touchGlow = float3(0.2, 0.7, 0.9) * (innerGlow + outerGlow);
    }

    // --- Compose ---
    float3 color = waterBase + causticColor + specColor + foamColor + touchGlow;

    // --- Vignette ---
    float2 vig = uv - 0.5;
    float vignette = 1.0 - dot(vig, vig) * 1.2;
    color *= max(vignette, 0.0);

    // --- Tone map (Reinhard) + gamma ---
    color = color / (color + 1.0);
    color = pow(saturate(color), float3(1.0 / 2.2));

    // Apply variant tint
    color *= u.tint;

    output.write(float4(color, 1.0), gid);
}
