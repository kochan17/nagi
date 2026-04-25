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

static float2 rotate2D(float2 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float2(v.x * c - v.y * s, v.x * s + v.y * c);
}

static float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// HSV → RGB
static float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// MARK: - Kaleidoscope fold
// Folds UV into a single fundamental domain for N-fold symmetry.
static float2 kaleidoscopeFold(float2 uv, int segments) {
    float angle = M_PI_F / float(segments);
    // Convert to polar
    float r = length(uv);
    float theta = atan2(uv.y, uv.x);
    // Wrap into [0, 2*angle)
    theta = fmod(theta, 2.0 * angle);
    // Mirror within sector
    if (theta > angle) {
        theta = 2.0 * angle - theta;
    }
    return float2(cos(theta), sin(theta)) * r;
}

// MARK: - Pattern SDF
// Returns a scalar field value for the base tile (before mirroring).
static float patternField(float2 p, float time) {
    // Nested spinning rings
    float r = length(p);
    float theta = atan2(p.y, p.x);

    float rings = sin(r * 14.0 - time * 1.5) * 0.5 + 0.5;
    float spokes = sin(theta * 6.0 + time * 0.8) * 0.5 + 0.5;

    // Rippling lattice
    float2 q = p * 5.0;
    float lattice = sin(q.x + time * 0.7) * sin(q.y - time * 0.5);

    return rings * 0.4 + spokes * 0.35 + lattice * 0.25;
}

// MARK: - kaleidoscope_render

kernel void kaleidoscope_render(
    texture2d<float, access::write> output [[texture(0)]],
    constant FluidUniforms &u              [[buffer(0)]],
    uint2 gid                              [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float2 uv = (float2(gid) / u.resolution) * 2.0 - 1.0;
    uv.x *= u.resolution.x / u.resolution.y; // Correct aspect ratio

    // --- Touch influence ---
    float2 touchUV = (u.touch / u.resolution) * 2.0 - 1.0;
    touchUV.x *= u.resolution.x / u.resolution.y;
    float touchDist = length(uv - touchUV);
    float touchSpeed = length(u.touchVelocity) / u.resolution.x * 10.0;

    // Touch warps the UV slightly outward
    float warpStrength = u.touchActive > 0.5 ? 0.12 * exp(-touchDist * touchDist / 0.15) : 0.0;
    uv += normalize(uv - touchUV + float2(0.001)) * warpStrength;

    // Slow global spin that accelerates with touch
    float spinSpeed = 0.15 + touchSpeed * 0.8;
    uv = rotate2D(uv, u.time * spinSpeed);

    // --- Kaleidoscope fold (8-fold symmetry = 16 petals) ---
    const int SEGMENTS = 8;
    float2 folded = kaleidoscopeFold(uv, SEGMENTS);

    // Zoom breathing
    float zoom = 1.0 + 0.12 * sin(u.time * 0.4);
    folded *= zoom;

    // --- Base pattern field ---
    float field = patternField(folded, u.time);

    // Second layer with slight rotation offset for depth
    float2 folded2 = kaleidoscopeFold(rotate2D(uv, M_PI_F / float(SEGMENTS)), SEGMENTS);
    folded2 *= zoom * 1.1;
    float field2 = patternField(folded2, u.time * 0.7 + 1.3);

    float combined = field * 0.6 + field2 * 0.4;

    // --- Color mapping ---
    // Hue cycles over time and with radial distance
    float r = length(uv);
    float touchHueShift = u.touchActive > 0.5 ? touchSpeed * 0.4 : 0.0;
    float hue = u.time * 0.07 + r * 0.18 + combined * 0.3 + touchHueShift;

    // Three palette bands: purple, cyan, pink
    float3 col = float3(0.0);
    {
        float h1 = hue;                          // purple ~0.75
        float h2 = hue + 0.33;                   // cyan   ~0.5 offset
        float h3 = hue + 0.16;                   // pink   ~0.9 offset

        float3 c1 = hsv2rgb(float3(fract(h1 + 0.75), 0.85, combined));
        float3 c2 = hsv2rgb(float3(fract(h2 + 0.50), 0.80, field2));
        float3 c3 = hsv2rgb(float3(fract(h3 + 0.90), 0.90, field));

        col = c1 * 0.5 + c2 * 0.3 + c3 * 0.2;
    }

    // Boost saturation in the hot zone around touch
    if (u.touchActive > 0.5) {
        float touchGlow = exp(-touchDist * touchDist / 0.08) * 1.6;
        float3 glowColor = hsv2rgb(float3(fract(hue + 0.9), 1.0, 1.0));
        col += glowColor * touchGlow * 0.5;
    }

    // --- Bloom (sample neighbour pixels via analytically extrapolated brightness) ---
    // We approximate bloom by adding a soft halo based on local brightness
    float brightness = dot(col, float3(0.299, 0.587, 0.114));
    float3 bloom = float3(0.0);
    if (brightness > 0.4) {
        // Inner halo based on field gradient
        float glowRing = smoothstep(0.55, 0.9, field) * smoothstep(1.0, 0.7, field);
        float3 glowHue = hsv2rgb(float3(fract(hue + 0.05), 0.7, 1.0));
        bloom = glowHue * glowRing * 0.6;
    }
    col += bloom;

    // Sparkle: random bright points that appear in high-field regions
    float sparkleHash = hash21(floor(folded * 18.0) + floor(u.time * 5.0));
    if (sparkleHash > 0.94 && field > 0.5) {
        float sparkle = (sparkleHash - 0.94) / 0.06;
        float pulse = sin(u.time * 12.0 + sparkleHash * 80.0) * 0.5 + 0.5;
        col += float3(0.9, 0.7, 1.0) * sparkle * pulse * 2.0;
    }

    // --- Vignette ---
    float vignette = 1.0 - smoothstep(0.5, 1.3, r);
    col *= vignette;

    // --- Tone mapping (ACES approximation) ---
    float3 x = col;
    col = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    // Gamma
    col = pow(saturate(col), float3(1.0 / 2.2));

    // Apply variant tint
    col *= u.tint;

    output.write(float4(col, 1.0), gid);
}
