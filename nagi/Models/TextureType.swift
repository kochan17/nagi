import SwiftUI
import simd

struct TextureVariant: Identifiable {
    let id: String
    let nameKey: L10nKey
    let baseType: TextureType
    let tintColor: SIMD3<Float>
    let gradientColors: [Color]
    var materialTextureName: String? = nil

    static let allVariants: [TextureVariant] = [
        // Fluids
        TextureVariant(
            id: "fluids_magenta",
            nameKey: .variantFluidsMagenta,
            baseType: .fluids,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.purple.opacity(0.8), .pink.opacity(0.5)]
        ),
        TextureVariant(
            id: "fluids_cyan_mist",
            nameKey: .variantFluidsCyanMist,
            baseType: .fluids,
            tintColor: SIMD3<Float>(0.4, 1.0, 1.0),
            gradientColors: [.cyan.opacity(0.8), .teal.opacity(0.5)]
        ),
        TextureVariant(
            id: "fluids_sunset_gold",
            nameKey: .variantFluidsSunsetGold,
            baseType: .fluids,
            tintColor: SIMD3<Float>(1.0, 0.75, 0.2),
            gradientColors: [.orange.opacity(0.8), .yellow.opacity(0.5)]
        ),
        // Kaleidoscope
        TextureVariant(
            id: "kaleidoscope_purple_cyan",
            nameKey: .variantKaleidoscopePurpleCyan,
            baseType: .kaleidoscope,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.blue.opacity(0.7), .purple.opacity(0.5)]
        ),
        TextureVariant(
            id: "kaleidoscope_rose_garden",
            nameKey: .variantKaleidoscopeRoseGarden,
            baseType: .kaleidoscope,
            tintColor: SIMD3<Float>(1.0, 0.5, 0.6),
            gradientColors: [.pink.opacity(0.8), .red.opacity(0.4)]
        ),
        TextureVariant(
            id: "kaleidoscope_emerald",
            nameKey: .variantKaleidoscopeEmerald,
            baseType: .kaleidoscope,
            tintColor: SIMD3<Float>(0.3, 1.0, 0.5),
            gradientColors: [.green.opacity(0.7), .teal.opacity(0.5)]
        ),
        // Orbs
        TextureVariant(
            id: "orbs_warm_sunset",
            nameKey: .variantOrbsWarmSunset,
            baseType: .orbs,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.orange.opacity(0.6), .yellow.opacity(0.4)]
        ),
        TextureVariant(
            id: "orbs_deep_ocean",
            nameKey: .variantOrbsDeepOcean,
            baseType: .orbs,
            tintColor: SIMD3<Float>(0.2, 0.6, 1.0),
            gradientColors: [.blue.opacity(0.8), .cyan.opacity(0.5)]
        ),
        TextureVariant(
            id: "orbs_aurora",
            nameKey: .variantOrbsAurora,
            baseType: .orbs,
            tintColor: SIMD3<Float>(0.4, 1.0, 0.7),
            gradientColors: [.green.opacity(0.6), .purple.opacity(0.4)]
        ),
        // Particles
        TextureVariant(
            id: "particles_sparkle",
            nameKey: .variantParticlesSparkle,
            baseType: .particles,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.cyan.opacity(0.6), .white.opacity(0.3)]
        ),
        TextureVariant(
            id: "particles_fireflies",
            nameKey: .variantParticlesFireflies,
            baseType: .particles,
            tintColor: SIMD3<Float>(0.6, 1.0, 0.3),
            gradientColors: [.green.opacity(0.5), .yellow.opacity(0.3)]
        ),
        TextureVariant(
            id: "particles_ember_rain",
            nameKey: .variantParticlesEmberRain,
            baseType: .particles,
            tintColor: SIMD3<Float>(1.0, 0.4, 0.1),
            gradientColors: [.orange.opacity(0.7), .red.opacity(0.4)]
        ),
        // Slime (image-based material textures)
        TextureVariant(
            id: "slime_fur",
            nameKey: .variantSlimeFur,
            baseType: .slime,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.purple.opacity(0.6), .pink.opacity(0.4)],
            materialTextureName: "slime_fur"
        ),
        TextureVariant(
            id: "slime_weave",
            nameKey: .variantSlimeWeave,
            baseType: .slime,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.red.opacity(0.6), .white.opacity(0.3)],
            materialTextureName: "slime_weave"
        ),
        TextureVariant(
            id: "slime_velvet",
            nameKey: .variantSlimeVelvet,
            baseType: .slime,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.red.opacity(0.8), .pink.opacity(0.4)],
            materialTextureName: "slime_velvet"
        ),
        TextureVariant(
            id: "slime_metal_mesh",
            nameKey: .variantSlimeMetalMesh,
            baseType: .slime,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.gray.opacity(0.7), .white.opacity(0.3)],
            materialTextureName: "slime_metal_mesh"
        ),
        TextureVariant(
            id: "slime_wool",
            nameKey: .variantSlimeWool,
            baseType: .slime,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.brown.opacity(0.6), .orange.opacity(0.3)],
            materialTextureName: "slime_wool"
        ),
        TextureVariant(
            id: "slime_teddy",
            nameKey: .variantSlimeTeddy,
            baseType: .slime,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.brown.opacity(0.7), .yellow.opacity(0.4)],
            materialTextureName: "slime_teddy"
        ),
        TextureVariant(
            id: "slime_frosty",
            nameKey: .variantSlimeFrosty,
            baseType: .slime,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.white.opacity(0.6), .cyan.opacity(0.3)],
            materialTextureName: "slime_frosty"
        ),
        // Waves
        TextureVariant(
            id: "waves_deep_blue",
            nameKey: .variantWavesDeepBlue,
            baseType: .waves,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.blue.opacity(0.6), .teal.opacity(0.4)]
        ),
        TextureVariant(
            id: "waves_tropical",
            nameKey: .variantWavesTropical,
            baseType: .waves,
            tintColor: SIMD3<Float>(0.3, 1.0, 0.8),
            gradientColors: [.cyan.opacity(0.7), .green.opacity(0.4)]
        ),
        TextureVariant(
            id: "waves_moonlight",
            nameKey: .variantWavesMoonlight,
            baseType: .waves,
            tintColor: SIMD3<Float>(0.7, 0.75, 1.0),
            gradientColors: [.indigo.opacity(0.6), .white.opacity(0.2)]
        ),
        // Fractal
        TextureVariant(
            id: "fractal_rainbow",
            nameKey: .variantFractalRainbow,
            baseType: .fractal,
            tintColor: SIMD3<Float>(1, 1, 1),
            gradientColors: [.red.opacity(0.6), .purple.opacity(0.4)]
        ),
        TextureVariant(
            id: "fractal_deep_space",
            nameKey: .variantFractalDeepSpace,
            baseType: .fractal,
            tintColor: SIMD3<Float>(0.4, 0.5, 1.0),
            gradientColors: [.indigo.opacity(0.7), .blue.opacity(0.4)]
        ),
        TextureVariant(
            id: "fractal_warm_sunset",
            nameKey: .variantFractalWarmSunset,
            baseType: .fractal,
            tintColor: SIMD3<Float>(1.0, 0.7, 0.4),
            gradientColors: [.orange.opacity(0.7), .red.opacity(0.4)]
        ),
    ]
}

enum TextureType: String, CaseIterable, Identifiable {
    case fluids
    case kaleidoscope
    case orbs
    case particles
    case slime
    case waves
    case fractal
    case campfire
    case forest

    var id: String { rawValue }

    /// Metal kernel function name for this texture
    var kernelName: String {
        switch self {
        case .fluids: return "fluid_render"
        case .kaleidoscope: return "kaleidoscope_render"
        case .orbs: return "orbs_render"
        case .particles: return "particles_render"
        case .slime: return "slime_render"
        case .waves: return "waves_render"
        case .fractal: return "fractal_render"
        case .campfire: return "campfire_render"
        case .forest: return "forest_render"
        }
    }

    /// Whether this texture needs the full Navier-Stokes fluid simulation
    /// (only fluids needs it; others are standalone render kernels)
    var needsFluidSim: Bool {
        switch self {
        case .fluids: return true
        default: return false
        }
    }

    var displayNameKey: L10nKey {
        switch self {
        case .fluids: return .categoryFluids
        case .kaleidoscope: return .categoryKaleidoscopes
        case .orbs: return .categoryOrbs
        case .particles: return .categoryParticles
        case .slime: return .categorySlimes
        case .waves: return .forBetterSleeping
        case .fractal: return .categoryFractal
        case .campfire: return .categoryCampfire
        case .forest: return .categoryForest
        }
    }

    var iconName: String {
        switch self {
        case .fluids: return "drop.fill"
        case .kaleidoscope: return "circle.hexagongrid.fill"
        case .orbs: return "circle.fill"
        case .particles: return "sparkles"
        case .slime: return "hand.point.up.fill"
        case .waves: return "water.waves"
        case .fractal: return "atom"
        case .campfire: return "flame.fill"
        case .forest: return "leaf.fill"
        }
    }

    /// Default material texture image name for image-based shaders (slime, etc.)
    /// Returns nil for procedural shaders that don't need an image.
    var materialTextureName: String? {
        switch self {
        case .slime: return "slime_velvet"
        case .campfire: return nil
        case .forest: return nil
        default: return nil
        }
    }

    var soundFileName: String {
        switch self {
        case .fluids: return "rain_ambient"
        case .kaleidoscope: return "kaleidoscope_chime"
        case .orbs: return "orbs_hum"
        case .particles: return "particles_sparkle"
        case .slime: return "slime_touch"
        case .waves: return "waves_ocean"
        case .fractal: return "kaleidoscope_chime"
        case .campfire: return "campfire_ambient"
        case .forest: return "forest_ambient"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .fluids: return [.purple.opacity(0.8), .pink.opacity(0.5)]
        case .kaleidoscope: return [.blue.opacity(0.7), .purple.opacity(0.5)]
        case .orbs: return [.orange.opacity(0.6), .yellow.opacity(0.4)]
        case .particles: return [.cyan.opacity(0.6), .white.opacity(0.3)]
        case .slime: return [.pink.opacity(0.6), .purple.opacity(0.4)]
        case .waves: return [.blue.opacity(0.6), .teal.opacity(0.4)]
        case .fractal: return [.red.opacity(0.6), .purple.opacity(0.4)]
        case .campfire: return [.black, Color(red: 0.6, green: 0.2, blue: 0.0).opacity(0.9), Color(red: 0.35, green: 0.04, blue: 0.0).opacity(0.8)]
        case .forest: return [Color(red: 0.02, green: 0.12, blue: 0.02).opacity(0.95), Color(red: 0.08, green: 0.22, blue: 0.04).opacity(0.85), Color(red: 0.18, green: 0.14, blue: 0.03).opacity(0.8)]
        }
    }

    static func variantsForCategory(_ type: TextureType) -> [TextureVariant] {
        TextureVariant.allVariants.filter { $0.baseType == type }
    }
}
