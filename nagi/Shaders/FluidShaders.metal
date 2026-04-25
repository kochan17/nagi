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
    float3 tint; // color multiplier; (1,1,1) = no tint
};

// MARK: - Add Force (touch → velocity + dye injection)

kernel void add_force(
    texture2d<float, access::read>  velocityIn  [[texture(0)]],
    texture2d<float, access::write> velocityOut [[texture(1)]],
    texture2d<float, access::read>  dyeIn       [[texture(2)]],
    texture2d<float, access::write> dyeOut      [[texture(3)]],
    constant FluidUniforms &u                   [[buffer(0)]],
    uint2 gid                                   [[thread_position_in_grid]]
) {
    if (gid.x >= uint(u.resolution.x) || gid.y >= uint(u.resolution.y)) return;

    float2 vel = velocityIn.read(gid).xy;
    float4 dye = dyeIn.read(gid);

    if (u.touchActive > 0.5) {
        float2 pos = float2(gid) / u.resolution;
        float2 touchPos = u.touch / u.resolution;
        float dist = length(pos - touchPos);

        // Splat radius (slightly larger for more dramatic injection)
        float radius = 0.05;
        float strength = exp(-dist * dist / (radius * radius));

        // Add velocity from touch movement (stronger push)
        vel += u.touchVelocity * strength * 1.2;

        // Inject dye — HDR neon magenta above 1.0 for bloom punch
        float3 color = float3(2.5, 0.2, 1.8);
        // Add some color variation based on time
        color.r += sin(u.time * 2.0) * 0.3;
        color.b += cos(u.time * 1.5) * 0.25;

        dye.rgb += color * u.tint * strength * 3.0;
        dye.a = min(dye.a + strength, 1.0);
    }

    velocityOut.write(float4(vel, 0, 0), gid);
    dyeOut.write(dye, gid);
}

// MARK: - Diffuse (Jacobi iteration for viscosity)

kernel void diffuse(
    texture2d<float, access::read>  fieldIn  [[texture(0)]],
    texture2d<float, access::write> fieldOut [[texture(1)]],
    constant FluidUniforms &u                [[buffer(0)]],
    uint2 gid                                [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    int x = int(gid.x);
    int y = int(gid.y);
    if (x >= w || y >= h) return;

    float a = u.dt * u.viscosity * float(w) * float(h);

    float4 center = fieldIn.read(gid);
    float4 left   = fieldIn.read(uint2(max(x - 1, 0), y));
    float4 right  = fieldIn.read(uint2(min(x + 1, w - 1), y));
    float4 down   = fieldIn.read(uint2(x, max(y - 1, 0)));
    float4 up     = fieldIn.read(uint2(x, min(y + 1, h - 1)));

    float4 result = (center + a * (left + right + down + up)) / (1.0 + 4.0 * a);
    fieldOut.write(result, gid);
}

// MARK: - Advect (semi-Lagrangian advection)

kernel void advect(
    texture2d<float, access::read>  fieldIn  [[texture(0)]],
    texture2d<float, access::write> fieldOut [[texture(1)]],
    constant FluidUniforms &u                [[buffer(0)]],
    uint2 gid                                [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float2 vel = fieldIn.read(gid).xy;

    // Trace particle back in time
    float2 pos = float2(gid) - vel * u.dt * float2(w, h);

    // Bilinear interpolation
    pos = clamp(pos, float2(0.5), float2(float(w) - 1.5, float(h) - 1.5));
    int2 i = int2(floor(pos));
    float2 f = fract(pos);

    float4 a = fieldIn.read(uint2(i));
    float4 b = fieldIn.read(uint2(i.x + 1, i.y));
    float4 c = fieldIn.read(uint2(i.x, i.y + 1));
    float4 d = fieldIn.read(uint2(i.x + 1, i.y + 1));

    float4 result = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);

    // Dissipation (dye persists longer for dramatic trailing flows)
    result *= 0.9992;

    fieldOut.write(result, gid);
}

// MARK: - Divergence

kernel void divergence(
    texture2d<float, access::read>  velocity    [[texture(0)]],
    texture2d<float, access::write> divergeOut  [[texture(1)]],
    uint2 gid                                   [[thread_position_in_grid]]
) {
    int w = int(velocity.get_width());
    int h = int(velocity.get_height());
    int x = int(gid.x);
    int y = int(gid.y);
    if (x >= w || y >= h) return;

    float vL = velocity.read(uint2(max(x - 1, 0), y)).x;
    float vR = velocity.read(uint2(min(x + 1, w - 1), y)).x;
    float vD = velocity.read(uint2(x, max(y - 1, 0))).y;
    float vU = velocity.read(uint2(x, min(y + 1, h - 1))).y;

    float div = -0.5 * (vR - vL + vU - vD);
    divergeOut.write(float4(div, 0, 0, 0), gid);
}

// MARK: - Pressure Solve (Jacobi)

kernel void pressure_solve(
    texture2d<float, access::read>  pressureIn  [[texture(0)]],
    texture2d<float, access::write> pressureOut [[texture(1)]],
    texture2d<float, access::read>  divergeIn   [[texture(2)]],
    uint2 gid                                   [[thread_position_in_grid]]
) {
    int w = int(pressureIn.get_width());
    int h = int(pressureIn.get_height());
    int x = int(gid.x);
    int y = int(gid.y);
    if (x >= w || y >= h) return;

    float pL = pressureIn.read(uint2(max(x - 1, 0), y)).x;
    float pR = pressureIn.read(uint2(min(x + 1, w - 1), y)).x;
    float pD = pressureIn.read(uint2(x, max(y - 1, 0))).x;
    float pU = pressureIn.read(uint2(x, min(y + 1, h - 1))).x;
    float div = divergeIn.read(gid).x;

    float p = (pL + pR + pD + pU + div) * 0.25;
    pressureOut.write(float4(p, 0, 0, 0), gid);
}

// MARK: - Gradient Subtract (make divergence-free)

kernel void gradient_subtract(
    texture2d<float, access::read>  velocityIn  [[texture(0)]],
    texture2d<float, access::write> velocityOut [[texture(1)]],
    texture2d<float, access::read>  pressure    [[texture(2)]],
    uint2 gid                                   [[thread_position_in_grid]]
) {
    int w = int(velocityIn.get_width());
    int h = int(velocityIn.get_height());
    int x = int(gid.x);
    int y = int(gid.y);
    if (x >= w || y >= h) return;

    float pL = pressure.read(uint2(max(x - 1, 0), y)).x;
    float pR = pressure.read(uint2(min(x + 1, w - 1), y)).x;
    float pD = pressure.read(uint2(x, max(y - 1, 0))).x;
    float pU = pressure.read(uint2(x, min(y + 1, h - 1))).x;

    float2 vel = velocityIn.read(gid).xy;
    vel -= 0.5 * float2(pR - pL, pU - pD);

    velocityOut.write(float4(vel, 0, 0), gid);
}

// MARK: - Pseudo-random hash for particle effects

float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + float2(1, 0));
    float c = hash(i + float2(0, 1));
    float d = hash(i + float2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for smoke-like patterns
float fbm(float2 p, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float2 shift = float2(time * 0.3, time * 0.2);
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p + shift);
        p *= 2.0;
        amplitude *= 0.5;
        shift *= 1.3;
    }
    return value;
}

// MARK: - Render (dye → screen with bloom/glow/particles/smoke)

kernel void fluid_render(
    texture2d<float, access::read>  dye       [[texture(0)]],
    texture2d<float, access::write> output    [[texture(1)]],
    constant FluidUniforms &u                 [[buffer(0)]],
    uint2 gid                                 [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float2 uv = float2(gid) / u.resolution;
    float4 d = dye.read(gid);
    float3 color = d.rgb;

    // --- Subtle background gradient (near-black teal/purple for context) ---
    float3 bgGradient = mix(
        float3(0.0, 0.02, 0.04),   // Very dark teal (bottom-left)
        float3(0.02, 0.0, 0.04),   // Very dark purple (top-right)
        dot(uv, float2(0.7, 0.7))
    );
    color = bgGradient + color;

    float dyeStrength = dot(d.rgb, float3(0.299, 0.587, 0.114));

    // --- FBM smoke layer reduced to a light edge-detail pass only ---
    if (dyeStrength > 0.05) {
        float smokeDetail = fbm(uv * 16.0 + float2(5.2, 1.3), u.time * 1.5);
        float detail = smoothstep(0.45, 0.55, smokeDetail) * dyeStrength * 0.15;
        // Keep detail tinted to the existing dye color so it doesn't muddy
        color += d.rgb * detail;
    }

    // --- Particle sparkle effect (more visible, lower threshold) ---
    float particleHash = hash(floor(uv * u.resolution * 0.5) + floor(u.time * 3.0));
    if (particleHash > 0.92 && dyeStrength > 0.05) {
        // Bright sparkle point
        float sparkle = (particleHash - 0.92) / 0.08;
        float pulse = sin(u.time * 10.0 + particleHash * 100.0) * 0.5 + 0.5;
        color += float3(1.0, 0.6, 0.9) * sparkle * pulse * dyeStrength * 4.0;
    }

    // --- HDR bloom (larger radius, stronger contribution) ---
    float3 bloom = float3(0);
    float bloomWeight = 0.0;
    int bloomRadius = 6;
    for (int by = -bloomRadius; by <= bloomRadius; by++) {
        for (int bx = -bloomRadius; bx <= bloomRadius; bx++) {
            int2 samplePos = int2(gid) + int2(bx, by);
            samplePos = clamp(samplePos, int2(0), int2(w - 1, h - 1));
            float3 s = dye.read(uint2(samplePos)).rgb;
            float brightness = dot(s, float3(0.299, 0.587, 0.114));
            if (brightness > 0.2) {
                float weight = exp(-float(bx * bx + by * by) / 18.0);
                bloom += s * weight * brightness;
                bloomWeight += weight;
            }
        }
    }
    if (bloomWeight > 0) {
        bloom /= bloomWeight;
    }
    color += bloom * 0.7;

    // --- Central glow orb at touch point (stronger, more visible) ---
    if (u.touchActive > 0.5) {
        float2 touchUV = u.touch / u.resolution;
        float dist = length(uv - touchUV);

        // Inner bright core — HDR punch
        float innerGlow = exp(-dist * dist / 0.002) * 5.0;
        color += float3(1.0, 0.2, 0.9) * innerGlow;

        // Mid-range halo
        float midGlow = exp(-dist * dist / 0.006) * 2.0;
        color += float3(0.9, 0.1, 0.7) * midGlow;

        // Outer soft glow
        float outerGlow = exp(-dist * dist / 0.020) * 1.2;
        color += float3(0.6, 0.0, 0.4) * outerGlow;

        // Pulsating ring
        float ring = smoothstep(0.04, 0.05, dist) * smoothstep(0.07, 0.05, dist);
        float pulse = sin(u.time * 4.0) * 0.3 + 0.7;
        color += float3(0.8, 0.1, 0.6) * ring * pulse * 1.0;
    }

    // --- Vignette (darken edges) ---
    float2 vignetteUV = uv - 0.5;
    float vignette = 1.0 - dot(vignetteUV, vignetteUV) * 0.5;
    color *= vignette;

    // --- Saturation boost before tonemapping ---
    float gray = dot(color, float3(0.299, 0.587, 0.114));
    color = mix(float3(gray), color, 1.3);

    // --- HDR amplify — push ink values up so ACES tonemapper maps to bright output ---
    color *= 1.8;

    // --- Tone mapping (ACES approximation) ---
    float3 x = color;
    color = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    // Gamma correction
    color = pow(saturate(color), float3(1.0 / 2.2));

    // Apply variant tint
    color *= u.tint;

    output.write(float4(color, 1.0), gid);
}
