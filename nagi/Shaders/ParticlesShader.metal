#include <metal_stdlib>
using namespace metal;

// Matches FluidUniforms in FluidShaders.metal and Swift side
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

// MARK: - Hash utilities

static float hash11(float n) {
    return fract(sin(n) * 43758.5453123);
}

static float2 hash21(float n) {
    return fract(sin(float2(n, n + 1.7)) * float2(43758.5453, 22578.1459));
}

static float2 hash22(float2 p) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// MARK: - Tiled particle field
//
// Strategy: divide UV space into a GRID_SIZE x GRID_SIZE grid.
// Each cell contains PARTICLES_PER_CELL particles at procedural positions.
// Per pixel, check the 3x3 neighborhood of the pixel's cell.
// Total logical particles = GRID_SIZE * GRID_SIZE * PARTICLES_PER_CELL
// At 64x64 grid, 8 particles/cell -> 32768 particles, O(72) work per pixel.

static constant int   GRID_SIZE          = 64;
static constant int   PARTICLES_PER_CELL = 8;   // particles per grid cell
static constant float CELL_SIZE          = 1.0 / float(GRID_SIZE);

// Particle type distribution within a cell (by index):
// 0-4  -> sparkle (5/8 = 62.5%)
// 5-6  -> ember   (2/8 = 25%)
// 7    -> firefly (1/8 = 12.5%)
static int particleTypeForIndex(int idx) {
    if (idx < 5) return 0; // sparkle
    if (idx < 7) return 3; // ember
    return 1;              // firefly
}

// Particle base size in UV space (gaussian sigma)
static float particleSigma(int type) {
    if (type == 0) return 0.0028; // sparkle: tiny
    if (type == 1) return 0.007;  // firefly: soft glow
    return 0.005;                 // ember: medium
}

// MARK: - Per-particle evaluation (tiled)
//
// cell: integer grid coords
// pidx: particle index within cell [0, PARTICLES_PER_CELL)
// Returns UV position and visual properties of this particle at this moment.

struct TileParticle {
    float2 pos;
    float3 color;
    float  alpha;
    float  sigma;
};

static TileParticle evaluateTileParticle(
    int2   cell,
    int    pidx,
    float  time,
    float2 touchPos,
    float  touchActive
) {
    // Unique seed per cell+particle
    float seed = float(cell.x * 1031 + cell.y * 2053 + pidx * 7919);

    int type = particleTypeForIndex(pidx);

    // Lifetime and phase
    float lifetime;
    if (type == 0) lifetime = 0.8 + hash11(seed * 1.3) * 0.6;   // sparkle: 0.8-1.4s
    else if (type == 1) lifetime = 2.0 + hash11(seed * 0.7) * 2.0; // firefly: 2-4s
    else lifetime = 1.0 + hash11(seed * 2.1) * 0.8;              // ember: 1-1.8s

    float spawnPhase = hash11(seed * 0.531);
    float cycleTime  = fmod(time + spawnPhase * lifetime, lifetime);
    float age        = cycleTime / lifetime; // 0..1

    // Spawn position: base cell position + per-particle offset within cell
    float2 cellOrigin = (float2(cell) + 0.5) * CELL_SIZE;
    float2 localOffset = (hash22(float2(seed, seed * 0.4)) - 0.5) * CELL_SIZE;
    float2 spawnPos   = cellOrigin + localOffset;

    // Touch attraction: pull spawn toward touch point when active
    if (touchActive > 0.5) {
        float2 toTouch = touchPos - spawnPos;
        float  tDist   = length(toTouch) + 0.001;
        float  attract = 0.18 * touchActive * (1.0 / (1.0 + tDist * 8.0));
        spawnPos += normalize(toTouch) * attract;
    }

    // Velocity: type-specific drift direction + random scatter
    float2 rndDir = normalize(hash22(float2(seed * 3.1, seed * 1.7)) * 2.0 - 1.0);
    float  speed;
    float2 gravity;

    if (type == 0) {
        // Sparkle: fast outward scatter, slight upward drift
        speed   = 0.08 + hash11(seed * 5.3) * 0.14;
        gravity = float2(0.0, -0.04); // rises
    } else if (type == 1) {
        // Firefly: gentle wandering
        speed   = 0.015 + hash11(seed * 2.9) * 0.025;
        gravity = float2(0.0, -0.015);
    } else {
        // Ember: moderate scatter upward
        speed   = 0.05 + hash11(seed * 4.1) * 0.08;
        gravity = float2(0.0, -0.07);
    }

    float2 vel = rndDir * speed;
    float  t   = cycleTime;
    float2 pos = spawnPos + vel * t + 0.5 * gravity * t * t;

    // Firefly: sinusoidal wander
    if (type == 1) {
        pos.x += sin(time * 1.4 + seed) * 0.025;
        pos.y += cos(time * 1.1 + seed * 1.7) * 0.018;
    }

    // Alpha: quick fade-in, gradual fade-out
    float fadeIn  = smoothstep(0.0, 0.06, age);
    float fadeOut = 1.0 - smoothstep(0.55, 1.0, age);
    float alpha   = fadeIn * fadeOut;

    // Colors
    float3 color;
    if (type == 0) {
        // Sparkle: white-gold to cool silver, with rapid flicker
        float variant  = hash11(seed * 9.7);
        float3 warm    = float3(1.0, 0.88, 0.45);  // gold
        float3 cool    = float3(0.7, 0.88, 1.0);   // silver-blue
        float3 base    = mix(warm, cool, step(0.45, variant));
        base           = mix(base, float3(1.0), 0.55); // whiten
        float flicker  = sin(time * 38.0 + seed * 73.0) * 0.35 + 0.65;
        color = base * flicker;
        // Occasional hard flash
        float flash    = step(0.94, hash11(floor(time * 12.0) + seed));
        color += float3(1.5, 1.4, 1.2) * flash;
    } else if (type == 1) {
        // Firefly: lime-green to warm yellow, gentle pulse
        float hueVar  = hash11(seed * 5.3);
        float3 c1     = float3(0.25, 1.0, 0.35);  // lime green
        float3 c2     = float3(0.4, 0.95, 1.0);   // cyan
        color = mix(c1, c2, hueVar);
        float pulse   = sin(time * 1.8 + seed * 6.3) * 0.28 + 0.72;
        color *= pulse;
    } else {
        // Ember: hot orange-white core, fading to dark red
        float burn    = 1.0 - age * age;
        float3 hot    = float3(1.2, 0.7, 0.15);  // bright orange (HDR)
        float3 cool   = float3(0.55, 0.08, 0.0); // dark ember red
        color = mix(cool, hot, burn);
        float flare   = step(0.91, hash11(floor(time * 10.0) + seed * 1.3));
        color += float3(1.4, 1.0, 0.3) * flare;
    }

    TileParticle p;
    p.pos   = pos;
    p.color = color;
    p.alpha = alpha;
    p.sigma = particleSigma(type);
    return p;
}

// MARK: - Dense particle layer (tiled grid accumulation)
//
// Check 3x3 neighborhood of cells around `uv`. For each cell, evaluate
// PARTICLES_PER_CELL particles and accumulate their gaussian contribution.
// Also adds a second, offset grid layer at half phase for extra fill density.

static float3 accumulateTiledParticles(
    float2 uv,
    float  time,
    float2 touchPos,
    float  touchActive
) {
    float3 acc = float3(0.0);

    // Primary grid pass
    int2 centerCell = int2(floor(uv / CELL_SIZE));

    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            int2 cell = centerCell + int2(dx, dy);
            // Wrap cell coordinates so field is infinite / no edge gaps
            cell = ((cell % GRID_SIZE) + GRID_SIZE) % GRID_SIZE;

            for (int p = 0; p < PARTICLES_PER_CELL; p++) {
                TileParticle tp = evaluateTileParticle(cell, p, time, touchPos, touchActive);

                float2 delta = uv - tp.pos;
                float  d2    = dot(delta, delta);
                float  sig2  = tp.sigma * tp.sigma;

                // Soft gaussian splat
                float glow = exp(-d2 / (sig2 * 8.0));
                // Sharp bright core for sparkle feel
                float core = exp(-d2 / (sig2 * 0.6));

                float contrib = (glow * 0.6 + core * 2.5) * tp.alpha;
                acc += tp.color * contrib;
            }
        }
    }

    // Second grid pass: offset by half a cell and half time phase for extra fill
    float2 uvOffset  = uv + float2(CELL_SIZE * 0.5, CELL_SIZE * 0.5);
    float  timeShift = time + 17.3; // prime offset so phases don't align
    int2   centerCell2 = int2(floor(uvOffset / CELL_SIZE));

    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            int2 cell = centerCell2 + int2(dx, dy);
            cell = ((cell % GRID_SIZE) + GRID_SIZE) % GRID_SIZE;

            for (int p = 0; p < PARTICLES_PER_CELL; p++) {
                TileParticle tp = evaluateTileParticle(cell, p, timeShift, touchPos, touchActive);

                float2 delta = uvOffset - tp.pos;
                float  d2    = dot(delta, delta);
                float  sig2  = tp.sigma * tp.sigma;

                float glow = exp(-d2 / (sig2 * 8.0));
                float core = exp(-d2 / (sig2 * 0.6));

                float contrib = (glow * 0.4 + core * 1.8) * tp.alpha;
                acc += tp.color * contrib;
            }
        }
    }

    return acc;
}

// MARK: - Luminous center haze
//
// Dense, layered radial glow at the center of the screen (or touch point)
// that gives the "explosion center" feel. Uses multiple octaves of noise.

static float3 centerHaze(float2 uv, float2 focusPos, float time) {
    float2 d    = uv - focusPos;
    float  dist = length(d);

    // Inner dense core
    float core  = exp(-dist * dist / 0.006) * 1.8;
    // Mid haze ring
    float mid   = exp(-dist * dist / 0.04) * 0.55;
    // Outer soft aura
    float outer = exp(-dist * dist / 0.18) * 0.15;

    float total = core + mid + outer;

    // Subtle rotation animation to make the haze feel alive
    float angle = atan2(d.y, d.x);
    float swirl = sin(angle * 6.0 + time * 0.8) * 0.12 + 1.0;
    total *= swirl;

    // Warm white center fading to gold
    float3 innerColor = float3(1.3, 1.2, 1.0);  // HDR warm white
    float3 outerColor = float3(0.9, 0.6, 0.2);  // gold aura
    float3 hazeColor  = mix(outerColor, innerColor, smoothstep(0.15, 0.0, dist));

    return hazeColor * total;
}

// MARK: - Starfield background sparkle
//
// Very fine, mostly-static pinprick stars that never move — adds depth.

static float3 starfield(float2 uv, float time) {
    float3 stars = float3(0.0);

    // Two star layers at different scales for depth illusion
    for (int layer = 0; layer < 2; layer++) {
        float scale    = layer == 0 ? 180.0 : 300.0;
        float2 cellUV  = uv * scale;
        int2   cellIdx = int2(floor(cellUV));
        float2 frac    = fract(cellUV);

        float seed      = float(cellIdx.x * 1301 + cellIdx.y * 4999 + layer * 7121);
        float starProb  = hash11(seed);

        // Only ~12% of cells contain a star
        if (starProb > 0.12) continue;

        float2 starUV  = hash21(seed + 1.0) * 0.9 + 0.05;
        float2 delta   = frac - starUV;
        float  d2      = dot(delta, delta);

        float brightness = hash11(seed * 3.7);
        float twinkle   = sin(time * (2.0 + brightness * 4.0) + seed * 20.0) * 0.4 + 0.6;
        float glow      = exp(-d2 / 0.0002) * brightness * twinkle;

        float3 starColor = mix(float3(0.7, 0.8, 1.0), float3(1.0, 0.95, 0.8),
                               hash11(seed * 2.3));
        stars += starColor * glow * (layer == 0 ? 0.9 : 0.5);
    }
    return stars;
}

// MARK: - particles_render kernel

kernel void particles_render(
    texture2d<float, access::write> output [[texture(0)]],
    constant FluidUniforms &u              [[buffer(0)]],
    uint2 gid                              [[thread_position_in_grid]]
) {
    int w = int(u.resolution.x);
    int h = int(u.resolution.y);
    if (int(gid.x) >= w || int(gid.y) >= h) return;

    float2 uv       = float2(gid) / u.resolution;
    float2 touchPos = u.touch / u.resolution;

    // Aspect correction so grid cells are square regardless of screen ratio
    float aspect = u.resolution.x / u.resolution.y;
    float2 uvAspect = float2(uv.x * aspect, uv.y);

    // --- Background: deep indigo-black gradient ---
    float3 bgTop    = float3(0.018, 0.016, 0.055);
    float3 bgBottom = float3(0.005, 0.004, 0.022);
    float3 color    = mix(bgBottom, bgTop, uv.y);

    // --- Starfield depth layer ---
    color += starfield(uv, u.time) * 0.7;

    // --- Dense tiled particle field ---
    // Pass aspect-corrected UV so grid cells appear square
    float2 uvForGrid = uvAspect;
    float2 touchForGrid = float2(touchPos.x * aspect, touchPos.y);
    color += accumulateTiledParticles(uvForGrid, u.time, touchForGrid, u.touchActive);

    // --- Luminous center haze ---
    float2 focusPos = u.touchActive > 0.5 ? touchPos : float2(0.5, 0.5);
    color += centerHaze(uv, focusPos, u.time) * 0.45;

    // --- Touch glow orb (contact point) ---
    if (u.touchActive > 0.5) {
        float dist      = length(uv - touchPos);
        float innerGlow = exp(-dist * dist / 0.0008) * 5.0;
        float midGlow   = exp(-dist * dist / 0.008) * 1.2;
        float outerGlow = exp(-dist * dist / 0.04)  * 0.4;
        color += float3(1.4, 1.25, 0.9) * innerGlow;   // HDR warm white core
        color += float3(0.8, 0.95, 1.0) * midGlow;     // cool blue ring
        color += float3(0.3, 0.7, 1.0) * outerGlow;    // cyan aura
    }

    // --- Radial vignette (darkens corners, focuses eye on center) ---
    float2 vigUV  = uv - 0.5;
    float vignette = 1.0 - dot(vigUV, vigUV) * 2.2;
    vignette = saturate(vignette);
    vignette = vignette * vignette; // squared for stronger falloff
    color *= vignette;

    // --- ACES filmic tonemapping ---
    // Compresses HDR values (>1.0) into displayable range with filmic look
    float3 x = color;
    color = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);

    // Gamma correction (sRGB)
    color = pow(saturate(color), float3(1.0 / 2.2));

    // Apply variant tint (existing system)
    color *= u.tint;

    output.write(float4(color, 1.0), gid);
}
