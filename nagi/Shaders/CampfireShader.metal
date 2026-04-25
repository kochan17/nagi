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

// MARK: - Hash / Noise utilities

static float cf_hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float cf_hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

static float cf_noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = cf_hash(i);
    float b = cf_hash(i + float2(1, 0));
    float c = cf_hash(i + float2(0, 1));
    float d = cf_hash(i + float2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// FBM for flame body
static float cf_fbm(float2 p, float time, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float2 shift = float2(time * 0.5, time * 0.7);
    for (int i = 0; i < octaves; i++) {
        value += amplitude * cf_noise(p + shift);
        p *= 2.1;
        amplitude *= 0.5;
        shift *= 1.2;
    }
    return value;
}

// FBM for smoke (slower drift)
static float cf_fbm_smoke(float2 p, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float2 shift = float2(time * 0.15, time * 0.25);
    for (int i = 0; i < 4; i++) {
        value += amplitude * cf_noise(p + shift);
        p *= 2.0;
        amplitude *= 0.5;
        shift *= 1.1;
    }
    return value;
}

// MARK: - Color temperature

// Approximate blackbody color for temperature in Kelvin (1500–3000K range)
static float3 blackbody(float t) {
    // t: 0 = 1500K (deep red), 1 = 3000K (white-yellow)
    float3 col;
    col.r = mix(0.8,  1.0,  t);
    col.g = mix(0.05, 0.85, t * t);
    col.b = mix(0.0,  0.3,  t * t * t);
    return col;
}

// MARK: - Wood grain (procedural)

static float woodGrain(float2 uv, float time) {
    float rings = sin(uv.x * 18.0 + cf_noise(uv * 3.0) * 3.0) * 0.5 + 0.5;
    float grain = cf_fbm(uv * float2(20.0, 4.0), 0.0, 3);
    return mix(rings, grain, 0.4);
}

// MARK: - campfire_render kernel

kernel void campfire_render(
    texture2d<float, access::write> output [[texture(0)]],
    constant FluidUniforms &u             [[buffer(0)]],
    uint2 gid                             [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float2 uv = float2(gid) / u.resolution;
    // Y increases downward in Metal textures; flip so 0 = bottom, 1 = top
    float2 fUV = float2(uv.x, 1.0 - uv.y);

    float t = u.time;

    // --- Touch influence ---
    float2 touchUV = float2(u.touch.x / u.resolution.x, 1.0 - u.touch.y / u.resolution.y);
    float touchStrength = (u.touchActive > 0.5) ? 1.0 : 0.0;
    // Lean factor: pushes flame horizontally toward touch
    float2 toTouch = touchUV - float2(0.5, 0.15);
    float leanX = touchStrength * toTouch.x * 0.15;

    // --- Background ---
    // Deep black → faint warm charcoal at the base
    float bgWarm = smoothstep(0.25, 0.0, fUV.y);
    float3 bg = mix(float3(0.0, 0.0, 0.0), float3(0.06, 0.03, 0.01), bgWarm);

    float3 color = bg;

    // ---- Logs / Firewood (bottom 18% of screen) ----
    if (fUV.y < 0.18) {
        // Normalize within log band
        float2 logUV = float2(fUV.x, fUV.y / 0.18);

        // Two crossed logs
        float logMask = 0.0;
        // Log 1: slight negative slope
        float d1 = abs(logUV.y - (0.55 - (logUV.x - 0.5) * 0.4));
        logMask = max(logMask, smoothstep(0.18, 0.08, d1));
        // Log 2: slight positive slope
        float d2 = abs(logUV.y - (0.45 + (logUV.x - 0.5) * 0.35));
        logMask = max(logMask, smoothstep(0.18, 0.08, d2));

        if (logMask > 0.01) {
            float grain = woodGrain(logUV * float2(3.0, 1.0), t);
            float3 woodColor = mix(float3(0.12, 0.06, 0.02), float3(0.25, 0.13, 0.05), grain);
            // Charred dark regions
            float charr = cf_fbm(logUV * 5.0, t * 0.05, 3);
            woodColor = mix(float3(0.03, 0.01, 0.0), woodColor, smoothstep(0.3, 0.7, charr));
            color = mix(color, woodColor, logMask);

            // Embers glow along the logs
            float emberGlow = cf_fbm(logUV * float2(8.0, 4.0) + float2(t * 0.3, 0.0), t, 3);
            emberGlow = smoothstep(0.55, 0.8, emberGlow) * logMask;
            float emberPulse = sin(t * 2.5 + logUV.x * 12.0) * 0.3 + 0.7;
            color += float3(1.2, 0.35, 0.0) * emberGlow * emberPulse * 0.9;
        }
    }

    // ---- Flame body ----
    // Flame occupies roughly x=[0.25,0.75], y=[0.10,0.70]
    float flameBaseY = 0.12;
    float flameCenterX = 0.5 + leanX;

    // UV relative to flame center
    float fx = (fUV.x - flameCenterX) * 2.2;  // horizontal, ±1 at edges
    float fy = (fUV.y - flameBaseY) / 0.60;    // 0=base, 1=tip

    // Low-frequency wind sway (sinusoidal lean)
    float sway = sin(t * 1.1) * 0.07 + sin(t * 0.6) * 0.04;
    fx -= sway * fy * fy;  // more sway toward tip

    // Flame silhouette: tapers to tip, wider at base
    float flameWidth = mix(0.55, 0.05, fy * fy);
    float flameSilhouette = smoothstep(flameWidth, flameWidth * 0.5, abs(fx));

    if (fy > 0.0 && fy < 1.05 && flameSilhouette > 0.0) {
        // Distort UV for FBM sampling → rising motion
        float2 noiseUV = float2(fx * 0.6, fy * 1.8 - t * 1.2);
        noiseUV.x += sway * 0.3;

        float flame = cf_fbm(noiseUV * 2.5, t, 5);
        // Shape: brighter/denser at base, fading at tip
        float heightFade = smoothstep(1.0, 0.0, fy);
        float flameMask = flame * heightFade * flameSilhouette;
        flameMask = pow(flameMask, 0.8);

        // Color temperature gradient
        // t=0 → tip (cool red 1600K), t=1 → core base (white 2800K)
        float tempT = clamp(1.0 - fy + flame * 0.3, 0.0, 1.0);
        float3 flameColor = blackbody(tempT);

        // HDR intensity: core is very bright
        float intensity = mix(0.8, 3.5, tempT * flameMask);
        color += flameColor * flameMask * intensity;

        // Touch: increase intensity near touch point
        if (u.touchActive > 0.5) {
            float distToTouch = length(fUV - touchUV);
            float touchBoost = exp(-distToTouch * distToTouch / 0.025) * 2.0;
            color += flameColor * flameMask * touchBoost;
        }
    }

    // ---- Smoke ----
    // Smoke drifts above the flame tip
    float smokeBaseY = 0.65;
    if (fUV.y > smokeBaseY) {
        float sy = (fUV.y - smokeBaseY) / (1.0 - smokeBaseY); // 0→1 top
        float sx = (fUV.x - 0.5) * 2.0;
        // Drift
        float smokeDrift = sin(t * 0.4) * 0.12 * sy;
        float2 smokeUV = float2(sx + smokeDrift, sy * 1.5 - t * 0.18);
        float smoke = cf_fbm_smoke(smokeUV * 2.0 + float2(2.3, 7.1), t);
        float smokeAlpha = smoothstep(0.42, 0.62, smoke);
        smokeAlpha *= smoothstep(0.0, 0.15, sy) * smoothstep(1.0, 0.5, sy);
        smokeAlpha *= smoothstep(0.6, 0.2, abs(sx));
        float3 smokeColor = float3(0.06, 0.05, 0.04);
        color = mix(color, smokeColor, smokeAlpha * 0.55);
    }

    // ---- Heat distortion (perturb background lookup) ----
    // Self-contained: adds a faint shimmer above the flame core
    {
        float heatZoneY = 0.40;
        if (fUV.y > heatZoneY && fUV.y < 0.80) {
            float heatStrength = smoothstep(0.80, heatZoneY, fUV.y) * 0.012;
            float2 heatUV = fUV * float2(4.0, 8.0) + float2(t * 0.6, -t * 1.4);
            float heatNoise = cf_noise(heatUV) - 0.5;
            // Perturb the base background sample (approximated by recomputing bg at offset UV)
            float2 distortedUV = float2(fUV.x + heatNoise * heatStrength, fUV.y);
            float distBgWarm = smoothstep(0.25, 0.0, distortedUV.y);
            float3 distBg = mix(float3(0.0), float3(0.06, 0.03, 0.01), distBgWarm);
            // Blend distorted bg subtly into area above flame
            float heatAlpha = heatStrength * 8.0 * smoothstep(0.55, heatZoneY, fUV.y);
            color = mix(color, color + (distBg - bg) * 2.0, heatAlpha);
        }
    }

    // ---- Sparks / Embers (pseudo-particles) ----
    {
        // 24 pseudo-particles driven by hash + time
        for (int i = 0; i < 24; i++) {
            float seed = float(i) * 137.508;
            // Birth position near the flame base, random x
            float bx = cf_hash1(seed) * 0.4 + 0.3;           // 0.3..0.7
            float speed = cf_hash1(seed + 1.0) * 0.25 + 0.15; // 0.15..0.40
            float lifetime = cf_hash1(seed + 2.0) * 0.8 + 0.4; // 0.4..1.2 s
            float phase = cf_hash1(seed + 3.0);                 // time offset

            // Cycle time
            float cycleT = fract((t * speed / lifetime) + phase);
            float age = cycleT * lifetime;  // 0..lifetime seconds

            // Position: rises upward, drifts sideways with sway
            float px = bx + sin(age * 3.0 + seed) * 0.04 + leanX * age;
            float py = 0.14 + age * speed * 1.5;

            // Fade out at birth and end of life
            float sparkAlpha = smoothstep(0.0, 0.1, cycleT) * smoothstep(1.0, 0.7, cycleT);
            sparkAlpha *= (1.0 - py); // fade as y→1 (top)

            if (py > 0.0 && py < 1.0 && sparkAlpha > 0.0) {
                // Convert spark position to flipped UV space
                float2 sparkPos = float2(px, py);
                float dist = length(fUV - sparkPos);
                float sparkSize = 0.005 + cf_hash1(seed + 4.0) * 0.006;
                float sparkGlow = exp(-dist * dist / (sparkSize * sparkSize));

                // Color: bright white-orange core
                float3 sparkColor = mix(float3(1.0, 0.4, 0.05), float3(1.0, 0.9, 0.6),
                                       exp(-dist / sparkSize));
                color += sparkColor * sparkGlow * sparkAlpha * 2.5;
            }
        }
    }

    // ---- Bloom ----
    // Luminance extraction + soft spread approximated by 3 Gaussian rings
    {
        float3 bloomAccum = float3(0.0);
        float bloomTotalW = 0.0;
        int bloomR = 5;
        for (int by = -bloomR; by <= bloomR; by++) {
            for (int bx = -bloomR; bx <= bloomR; bx++) {
                // Sample from already-accumulated color by reconstructing it
                // (Since we cannot read output texture, approximate bloom from flame mask)
                float2 sUV = fUV + float2(float(bx), float(by)) / u.resolution * 3.0;
                sUV = clamp(sUV, float2(0.0), float2(1.0));

                // Reconstruct a rough flame brightness sample at sUV
                float sfx = (sUV.x - (0.5 + leanX)) * 2.2;
                float sfy = (sUV.y - flameBaseY) / 0.60;
                float sSway = sway;
                sfx -= sSway * sfy * sfy;
                float sFlameWidth = mix(0.55, 0.05, sfy * sfy);
                float sSilhouette = smoothstep(sFlameWidth, sFlameWidth * 0.5, abs(sfx));
                float2 sNoiseUV = float2(sfx * 0.6, sfy * 1.8 - t * 1.2);
                float sFbm = cf_fbm(sNoiseUV * 2.5, t, 3);
                float sHeightFade = smoothstep(1.0, 0.0, sfy);
                float sBright = sFbm * sHeightFade * sSilhouette;
                float sLum = sBright * mix(0.8, 3.5, sBright);

                if (sLum > 0.3) {
                    float w = exp(-float(bx * bx + by * by) / 16.0);
                    float tempT2 = clamp(1.0 - sfy + sFbm * 0.3, 0.0, 1.0);
                    bloomAccum += blackbody(tempT2) * sLum * w;
                    bloomTotalW += w;
                }
            }
        }
        if (bloomTotalW > 0.0) {
            color += (bloomAccum / bloomTotalW) * 0.5;
        }
    }

    // ---- Vignette ----
    float2 vigUV = uv - 0.5;
    float vignette = 1.0 - dot(vigUV, vigUV) * 1.2;
    color *= saturate(vignette);

    // ---- ACES tonemap ----
    color *= 1.6;
    float3 x = color;
    color = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    // Gamma
    color = pow(saturate(color), float3(1.0 / 2.2));

    // Tint
    color *= u.tint;

    output.write(float4(saturate(color), 1.0), gid);
}
