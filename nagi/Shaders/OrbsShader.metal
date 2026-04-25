#include <metal_stdlib>
using namespace metal;

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

static float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

// Fast hash returning [0,1] from a float2 seed
static float hash2f(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// MARK: - orbs_render kernel

kernel void orbs_render(
    texture2d<float, access::write> output [[texture(0)]],
    constant FluidUniforms &u              [[buffer(0)]],
    uint2 gid                              [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float minDim = min(u.resolution.x, u.resolution.y);

    // NDC: origin at screen center, [-0.5, 0.5] range on shortest axis
    float2 uv = (float2(gid) - 0.5 * u.resolution) / minDim;

    // Touch: move orb center toward touch point
    float2 touchNDC = (u.touch - 0.5 * u.resolution) / minDim;
    float2 center = (u.touchActive > 0.5) ? touchNDC : float2(0.0);

    // Smooth orb center drift toward touch (approximate — instant in shader, Swift lerps over frames)
    float2 pos = uv - center;
    float dist = length(pos);
    float angle = atan2(pos.y, pos.x);

    // Touch pulse: brightens and expands rings when touching
    float touchPulse = (u.touchActive > 0.5) ? 1.0 : 0.0;
    // Smooth pulse using time so it breathes even after lift
    float pulseBeat = sin(u.time * 4.0) * 0.5 + 0.5;
    float pulseAmp = touchPulse * (0.6 + pulseBeat * 0.4);

    float3 color = float3(0.0);

    // ── 1. Background: near-black with subtle warm glow bleed ──────────────────
    float bgGlow = exp(-dist * dist / 0.25) * 0.06;
    color += float3(0.04, 0.08, 0.05) * bgGlow;

    // ── 2. Outer ambient haze ──────────────────────────────────────────────────
    float ambientHaze = exp(-dist * dist / 0.12) * 0.15;
    color += float3(0.05, 0.25, 0.12) * ambientHaze;

    // ── 3. Light rays (radial, angle-modulated) ────────────────────────────────
    // 12 primary rays, 6 secondary rays, rotating slowly
    float rayAngle1 = angle + u.time * 0.18;
    float rayAngle2 = angle - u.time * 0.11 + 0.26;
    float rayPrimary   = pow(abs(sin(rayAngle1 * 6.0)), 14.0);
    float raySecondary = pow(abs(sin(rayAngle2 * 3.0)), 10.0) * 0.5;
    float rayFalloff   = exp(-dist / 0.22) * smoothstep(0.04, 0.12, dist);
    float rayStrength  = (rayPrimary + raySecondary) * rayFalloff * (0.35 + pulseAmp * 0.2);
    color += float3(0.3, 1.1, 0.5) * rayStrength;

    // ── 4. Concentric pulsing rings ────────────────────────────────────────────
    // 5 rings at increasing radii, each rotating and pulsing independently
    const int RING_COUNT = 5;
    float ringRadii[RING_COUNT]  = { 0.07, 0.12, 0.17, 0.23, 0.30 };
    float ringWidths[RING_COUNT] = { 0.004, 0.003, 0.003, 0.0025, 0.002 };
    float ringSpeeds[RING_COUNT] = { 1.8, -1.3, 2.2, -0.9, 1.5 };
    float ringBright[RING_COUNT] = { 1.0, 0.85, 0.70, 0.55, 0.40 };

    for (int i = 0; i < RING_COUNT; i++) {
        float fi = float(i);
        float pulse = sin(u.time * ringSpeeds[i] + fi * 1.2) * 0.5 + 0.5;

        // Radius expands slightly with pulse and touch
        float r = ringRadii[i] + pulse * 0.006 + pulseAmp * 0.008;
        float w = ringWidths[i] * (1.0 + pulseAmp * 0.6);

        // Geometric rotation pattern on ring: 6-fold symmetry that rotates
        float ringRot = u.time * 0.3 * ringSpeeds[i];
        float geoPattern = 0.7 + 0.3 * cos((angle + ringRot) * 6.0);

        // Ring SDF: thin band at radius r
        float ring = smoothstep(w * 2.5, 0.0, abs(dist - r));

        // Touch distortion: slightly warps ring near touch
        float distort = touchPulse * sin(angle * 4.0 + u.time * 3.0) * 0.004;
        ring = smoothstep(w * 2.5, 0.0, abs(dist - r - distort));

        float3 ringColor = mix(float3(0.2, 1.0, 0.5), float3(0.4, 0.7, 1.0), fi / float(RING_COUNT - 1));
        color += ringColor * ring * geoPattern * ringBright[i] * (0.5 + pulse * 0.5);
    }

    // ── 5. Rotating geometric pattern (inner mandala-like rings) ──────────────
    // Two counter-rotating hexagonal grid layers
    float geoAngle1 = angle * 6.0 + u.time * 0.8;
    float geoAngle2 = angle * 4.0 - u.time * 0.6 + 3.14159;
    float geoFade   = smoothstep(0.14, 0.04, dist) * smoothstep(0.005, 0.03, dist);
    float geo1 = 0.5 + 0.5 * cos(geoAngle1);
    float geo2 = 0.5 + 0.5 * cos(geoAngle2);
    float geoPattern = (geo1 * geo2) * geoFade;
    color += float3(0.5, 1.4, 0.6) * geoPattern * 0.8;

    // Additional spokes (8-fold) rotating opposite direction
    float spokeAngle = angle * 8.0 - u.time * 1.1;
    float spoke = pow(max(0.0, cos(spokeAngle)), 20.0);
    float spokeFade = smoothstep(0.18, 0.03, dist) * smoothstep(0.01, 0.06, dist);
    color += float3(0.8, 1.8, 0.8) * spoke * spokeFade * 0.6;

    // ── 6. Middle glow band ────────────────────────────────────────────────────
    float midGlow = exp(-dist * dist / 0.018) * (1.2 + pulseAmp * 0.5);
    color += float3(0.15, 1.2, 0.4) * midGlow;

    // ── 7. Hot core (white-yellow-orange) ─────────────────────────────────────
    // Tiny intensely bright center
    float core = exp(-dist * dist / 0.0018) * (3.0 + pulseAmp * 1.5);
    color += float3(3.0, 2.4, 1.0) * core; // HDR yellow-white

    // Inner corona just outside core
    float corona = exp(-dist * dist / 0.007) * (1.5 + pulseAmp * 0.8);
    color += float3(1.8, 1.2, 0.3) * corona;

    // ── 8. Sparkle points orbiting the edge ───────────────────────────────────
    // Small bright dots at a radius band, time-varied positions
    float sparkleR = 0.19 + sin(u.time * 0.25) * 0.015;
    float sparkleRWidth = 0.0008;
    float sparkleBand = exp(-(dist - sparkleR) * (dist - sparkleR) / sparkleRWidth);

    // Discretize angle into N sectors, each with a random presence
    float sectorCount = 24.0;
    float sectorAngle = floor((angle + u.time * 0.15) * sectorCount / (2.0 * 3.14159265));
    float sparkleHash = hash2f(float2(sectorAngle, floor(u.time * 1.5)));
    float sparklePresent = step(0.78, sparkleHash); // ~22% of sectors lit

    // Secondary faster sparkle ring for shimmer
    float sparkleR2 = 0.215 + cos(u.time * 0.4) * 0.01;
    float sparkleBand2 = exp(-(dist - sparkleR2) * (dist - sparkleR2) / sparkleRWidth);
    float sectorAngle2 = floor((angle - u.time * 0.25) * sectorCount / (2.0 * 3.14159265));
    float sparkleHash2 = hash2f(float2(sectorAngle2 + 100.0, floor(u.time * 2.0 + 7.0)));
    float sparklePresent2 = step(0.82, sparkleHash2);

    color += float3(1.5, 2.0, 1.2) * sparkleBand  * sparklePresent  * 3.0;
    color += float3(1.2, 1.8, 2.0) * sparkleBand2 * sparklePresent2 * 2.5;

    // ── 9. Apply variant tint ──────────────────────────────────────────────────
    // Tint is multiplicative; default tint (1,1,1) leaves color unchanged.
    // For non-white tints, preserve luminance roughly by mixing.
    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    color = mix(color, color * u.tint * 1.3, 0.65);

    // ── 10. Vignette ──────────────────────────────────────────────────────────
    float vignette = 1.0 - saturate(dist * dist * 2.8);
    color *= vignette;

    // ── 11. ACES tonemapping + gamma ──────────────────────────────────────────
    float3 x = color;
    color = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
    color = pow(saturate(color), float3(1.0 / 2.2));

    // Write as bgra8Unorm (matches existing texture format expectation)
    output.write(float4(color.b, color.g, color.r, 1.0), gid);
}
