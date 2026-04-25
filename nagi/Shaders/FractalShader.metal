#include <metal_stdlib>
using namespace metal;

// Mirror of FluidUniforms defined in FluidShaders.metal (same memory layout)
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

// MARK: - Utility

static float hash21_f(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// HSV -> RGB
static float3 hsv2rgb_f(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// MARK: - Julia set iteration
// Returns smooth iteration count in [0, 1]
static float juliaSmooth(float2 z, float2 c, int maxIter) {
    float2 zn = z;
    for (int i = 0; i < maxIter; i++) {
        // z = z^2 + c
        float zx = zn.x * zn.x - zn.y * zn.y + c.x;
        float zy = 2.0 * zn.x * zn.y + c.y;
        zn = float2(zx, zy);
        if (dot(zn, zn) > 4.0) {
            // Smooth iteration count (Bernstein polynomial)
            float log2_modulus = log2(length(zn));
            float nu = float(i) + 1.0 - log2(log2_modulus);
            return nu / float(maxIter);
        }
    }
    return 0.0; // inside the set
}

// MARK: - fractal_render

kernel void fractal_render(
    texture2d<float, access::write> output [[texture(0)]],
    constant FluidUniforms &u              [[buffer(0)]],
    uint2 gid                              [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    // Map pixel to [-2, 2] with aspect correction
    float2 uv = (float2(gid) / u.resolution) * 2.0 - 1.0;
    uv.x *= u.resolution.x / u.resolution.y;
    uv *= 2.0; // expand to [-2, 2] range for Julia set

    // --- Touch-controlled Julia parameter c ---
    // Default: slowly rotate around a point that produces good Julia sets
    float baseAngle = u.time * 0.15;
    float baseRadius = 0.7885;
    float2 cDefault = float2(cos(baseAngle), sin(baseAngle)) * baseRadius;

    // Touch moves c toward the touch position (normalized to fractal space)
    float2 touchNorm = (u.touch / u.resolution) * 2.0 - 1.0;
    touchNorm.x *= u.resolution.x / u.resolution.y;
    touchNorm *= 1.5; // scale touch to useful c range

    float2 c = u.touchActive > 0.5
        ? mix(cDefault, touchNorm, 0.7)
        : cDefault;

    // Subtle zoom that breathes with time
    float zoom = 1.0 + 0.08 * sin(u.time * 0.3);
    float2 z = uv / zoom;

    // --- Julia iteration ---
    const int MAX_ITER = 100;
    float t = juliaSmooth(z, c, MAX_ITER);

    // --- Color ---
    float3 col;
    if (t == 0.0) {
        // Inside set: black with occasional star twinkle
        float starHash = hash21_f(floor(uv * 80.0));
        float starThresh = 0.97;
        if (starHash > starThresh) {
            float twinkle = sin(u.time * 8.0 + starHash * 40.0) * 0.5 + 0.5;
            float brightness = (starHash - starThresh) / (1.0 - starThresh) * twinkle;
            col = float3(brightness * 0.8, brightness * 0.9, brightness);
        } else {
            col = float3(0.0);
        }
    } else {
        // Outside set: rainbow color based on smooth iteration count + time
        float hue = fract(t * 3.0 + u.time * 0.08);
        float saturation = 0.9;
        // Value: brighter in mid-range escape times, darker near boundary
        float value = smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.85, 1.0, t));
        value = 0.3 + value * 0.7;

        col = hsv2rgb_f(float3(hue, saturation, value));

        // Touch glow: brighten region near touch point (in screen space)
        if (u.touchActive > 0.5) {
            float2 screenUV = (float2(gid) / u.resolution) * 2.0 - 1.0;
            screenUV.x *= u.resolution.x / u.resolution.y;
            float2 touchUV = (u.touch / u.resolution) * 2.0 - 1.0;
            touchUV.x *= u.resolution.x / u.resolution.y;
            float d = length(screenUV - touchUV);
            float glow = exp(-d * d / 0.1) * 0.6;
            float3 glowColor = hsv2rgb_f(float3(fract(hue + 0.5), 1.0, 1.0));
            col += glowColor * glow;
        }
    }

    // --- Vignette ---
    float2 vigUV = (float2(gid) / u.resolution) * 2.0 - 1.0;
    float r = length(vigUV);
    float vignette = 1.0 - smoothstep(0.6, 1.4, r);
    col *= vignette;

    // --- ACES tonemapping ---
    float3 x = col;
    col = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    // Gamma correction
    col = pow(saturate(col), float3(1.0 / 2.2));

    // Apply variant tint
    col *= u.tint;

    output.write(float4(col, 1.0), gid);
}
