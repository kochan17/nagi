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

// MARK: - Hash / noise utilities (forest_ prefix to avoid collisions)

static float forest_hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float forest_hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

static float forest_noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = forest_hash(i);
    float b = forest_hash(i + float2(1, 0));
    float c = forest_hash(i + float2(0, 1));
    float d = forest_hash(i + float2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

static float forest_fbm(float2 p, int octaves) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < octaves; i++) {
        v += a * forest_noise(p);
        p *= 2.1;
        a *= 0.5;
    }
    return v;
}

// FBM with time-driven drift — used for canopy leaf animation
static float forest_fbm_drift(float2 p, float time, int octaves) {
    float v = 0.0;
    float a = 0.5;
    float2 shift = float2(time * 0.08, time * 0.05);
    for (int i = 0; i < octaves; i++) {
        v += a * forest_noise(p + shift);
        p *= 2.1;
        a *= 0.5;
        shift *= 1.3;
    }
    return v;
}

// MARK: - Bark / wood texture

static float barkTexture(float2 uv, float seed) {
    float stripes = sin(uv.x * 22.0 + forest_noise(uv * float2(2.0, 1.0)) * 4.0) * 0.5 + 0.5;
    float grain   = forest_fbm(uv * float2(4.0, 12.0) + seed, 3);
    return mix(stripes, grain, 0.35);
}

// MARK: - forest_render kernel

kernel void forest_render(
    texture2d<float, access::write> output [[texture(0)]],
    constant FluidUniforms &u             [[buffer(0)]],
    uint2 gid                             [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float2 uv = float2(gid) / u.resolution;
    // Y-flip: Metal texture origin is top-left; flip so 0=ground, 1=sky
    float2 fUV = float2(uv.x, 1.0 - uv.y);

    float t = u.time;

    // ---- Touch UV (normalized, y-flipped) ----
    float2 touchUV = float2(u.touch.x / u.resolution.x, 1.0 - u.touch.y / u.resolution.y);
    float touchStrength = (u.touchActive > 0.5) ? 1.0 : 0.0;

    // ---- Sky / background: deep forest canopy atmosphere ----
    // Deep teal-green shadows at top, warm dark amber at ground
    float skyT = fUV.y;
    float3 skyTop    = float3(0.01, 0.06, 0.04);  // near-black deep green
    float3 skyBottom = float3(0.05, 0.03, 0.01);  // earthy dark amber
    float3 bg = mix(skyBottom, skyTop, skyT * skyT);

    // Subtle atmospheric haze (FBM fog band in the midground)
    float fogBand = smoothstep(0.30, 0.60, fUV.y) * smoothstep(0.80, 0.55, fUV.y);
    float fogNoise = forest_fbm_drift(fUV * float2(3.0, 6.0) + float2(0.0, t * 0.02), t, 3);
    float fogAlpha = fogBand * fogNoise * 0.18;
    float3 fogColor = float3(0.12, 0.18, 0.10);
    bg = mix(bg, fogColor, fogAlpha);

    float3 color = bg;

    // ---- Ground: fallen leaves carpet (bottom 22%) ----
    if (fUV.y < 0.22) {
        float leafNoise = forest_fbm(fUV * float2(14.0, 8.0) + float2(t * 0.03, 0.0), 4);
        // Multi-color leaf mosaic: amber, rust, brown, olive
        float3 leafA = float3(0.40, 0.18, 0.05);   // amber-brown
        float3 leafB = float3(0.25, 0.12, 0.03);   // deep rust
        float3 leafC = float3(0.15, 0.18, 0.04);   // dark olive
        float3 leafColor = mix(leafA, leafB, smoothstep(0.3, 0.6, leafNoise));
        leafColor = mix(leafColor, leafC, smoothstep(0.65, 0.85, leafNoise));

        // Shadow deeper at very bottom (ground level)
        float groundShadow = smoothstep(0.22, 0.0, fUV.y) * 0.5;
        leafColor = mix(leafColor, float3(0.02, 0.01, 0.0), groundShadow);
        color = mix(color, leafColor, smoothstep(0.0, 0.12, fUV.y)); // blend in
    }

    // ---- Tree trunks (3 main trunks, procedural) ----
    {
        // Trunk 1 — left, leans slightly right
        float tx1 = 0.22 + sin(t * 0.04) * 0.002;
        float tw1 = 0.045;
        float td1 = abs(fUV.x - tx1) / tw1;
        float trunkMask1 = smoothstep(1.0, 0.5, td1);
        // Trunk 2 — center-right
        float tx2 = 0.65 + sin(t * 0.03 + 1.1) * 0.002;
        float tw2 = 0.055;
        float td2 = abs(fUV.x - tx2) / tw2;
        float trunkMask2 = smoothstep(1.0, 0.5, td2);
        // Trunk 3 — far right, thinner
        float tx3 = 0.88;
        float tw3 = 0.028;
        float td3 = abs(fUV.x - tx3) / tw3;
        float trunkMask3 = smoothstep(1.0, 0.5, td3);

        float trunkMask = max(max(trunkMask1, trunkMask2), trunkMask3);

        if (trunkMask > 0.01 && fUV.y < 0.78) {
            // Which trunk am I on?
            float seed = (trunkMask1 >= trunkMask2 && trunkMask1 >= trunkMask3) ? 0.0
                       : (trunkMask2 >= trunkMask3) ? 1.7
                       : 3.3;
            float bark = barkTexture(fUV * float2(1.0, 3.0), seed);
            float3 barkDark  = float3(0.06, 0.04, 0.02);
            float3 barkLight = float3(0.16, 0.10, 0.05);
            float3 barkColor = mix(barkDark, barkLight, bark);

            // Moss streak on shadowed side
            float mossT = forest_noise(fUV * float2(2.0, 5.0) + float2(seed, 0.0));
            float3 mossColor = float3(0.08, 0.14, 0.05);
            barkColor = mix(barkColor, mossColor, smoothstep(0.55, 0.72, mossT) * 0.55);

            // Fade trunks toward sky (upper portion thins out into canopy)
            float trunkFade = smoothstep(0.78, 0.55, fUV.y);
            color = mix(color, barkColor, trunkMask * trunkFade);
        }
    }

    // ---- Canopy: swaying leaf clusters (upper 55%) ----
    if (fUV.y > 0.40) {
        // Wind sway: gentle horizontal oscillation, varies with height
        float windFreq = 0.55;
        float windAmp  = 0.012 * smoothstep(0.40, 1.0, fUV.y);
        float windSway = sin(t * windFreq + fUV.x * 3.1) * windAmp
                       + sin(t * 0.31 + fUV.x * 1.7) * windAmp * 0.5;

        // Touch: fan the canopy away from touch point
        if (u.touchActive > 0.5) {
            float2 toTouch = touchUV - fUV;
            windSway += touchStrength * toTouch.x * 0.018 * smoothstep(0.3, 0.0, length(toTouch));
        }

        float2 leafUV = float2(fUV.x + windSway, fUV.y);
        float leafDensity = forest_fbm_drift(leafUV * float2(4.0, 2.5), t, 5);

        // Threshold into distinct leaf masses
        float leafMask = smoothstep(0.48, 0.72, leafDensity);

        if (leafMask > 0.01) {
            // Layer of greens: deep shadow green → mid canopy green → light edge
            float lightDir = forest_fbm(leafUV * 3.5 + float2(1.5, t * 0.07), 3);
            float3 leafShadow = float3(0.02, 0.07, 0.01);
            float3 leafMid    = float3(0.06, 0.18, 0.04);
            float3 leafBright = float3(0.14, 0.35, 0.06);
            float3 leafColor  = mix(leafShadow, leafMid, smoothstep(0.3, 0.6, lightDir));
            leafColor         = mix(leafColor, leafBright, smoothstep(0.65, 0.85, lightDir));

            // Fade out at very top (open sky above canopy)
            float canopyFade = smoothstep(1.0, 0.75, fUV.y);
            color = mix(color, leafColor, leafMask * canopyFade);
        }
    }

    // ---- God rays / dappled light shafts ----
    {
        // 4 god-ray shafts from the canopy, narrow and subtly animated
        for (int i = 0; i < 4; i++) {
            float seed = float(i) * 1.618;
            float shaftX = forest_hash1(seed) * 0.8 + 0.1;       // 0.1..0.9
            float shaftW = forest_hash1(seed + 0.5) * 0.025 + 0.008; // narrow
            float shaftAngle = (forest_hash1(seed + 1.0) - 0.5) * 0.08; // slight lean
            float shaftDrift = sin(t * 0.18 + seed) * 0.004;      // slow drift

            // Ray starts from canopy top, falls to mid-ground
            float rayX = shaftX + shaftAngle * (1.0 - fUV.y) + shaftDrift;
            float dx = abs(fUV.x - rayX);
            float rayMask = smoothstep(shaftW, 0.0, dx);
            rayMask *= smoothstep(0.20, 0.55, fUV.y); // bottom fade
            rayMask *= smoothstep(0.95, 0.65, fUV.y); // top fade into canopy

            // Flicker: simulate leaves passing through the shaft
            float flicker = forest_noise(float2(t * 0.6 + seed * 7.3, fUV.y * 4.0));
            rayMask *= mix(0.3, 1.0, smoothstep(0.3, 0.7, flicker));

            float3 rayColor = float3(0.55, 0.50, 0.20); // warm golden-green
            color += rayColor * rayMask * 0.38;
        }
    }

    // ---- Dappled light circles on ground (leaf shadow inversions) ----
    if (fUV.y < 0.28) {
        for (int i = 0; i < 10; i++) {
            float seed = float(i) * 2.718;
            float cx = forest_hash1(seed) * 0.9 + 0.05;
            float cy = forest_hash1(seed + 1.0) * 0.22;
            float cr = forest_hash1(seed + 2.0) * 0.025 + 0.008;
            // Gentle drift from wind
            cx += sin(t * 0.22 + seed) * 0.008;

            float dist = length(fUV - float2(cx, cy));
            float dapple = smoothstep(cr, cr * 0.4, dist);
            float3 dappleColor = float3(0.38, 0.28, 0.08); // warm leaf-light spot
            color += dappleColor * dapple * 0.55;
        }
    }

    // ---- Touch: scatter falling leaves / rustle burst at contact point ----
    if (u.touchActive > 0.5) {
        float distToTouch = length(fUV - touchUV);
        // Bright scatter ring
        float ring = exp(-pow(distToTouch - 0.06, 2.0) / 0.001) * 0.6;
        float3 scatterColor = float3(0.30, 0.50, 0.10);
        color += scatterColor * ring;
        // Soft fill under touch
        float fill = exp(-distToTouch * distToTouch / 0.012) * 0.25;
        color += float3(0.18, 0.30, 0.06) * fill;
    }

    // ---- Vignette: deep forest darkness at edges ----
    float2 vigUV = uv - 0.5;
    float vignette = 1.0 - dot(vigUV, vigUV) * 1.5;
    color *= saturate(vignette);

    // ---- ACES tonemap ----
    color *= 1.4;
    float3 x = color;
    color = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    // Gamma
    color = pow(saturate(color), float3(1.0 / 2.2));

    // Tint
    color *= u.tint;

    output.write(float4(saturate(color), 1.0), gid);
}
