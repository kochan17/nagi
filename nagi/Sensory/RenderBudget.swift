import Foundation
import os.log

/// Monitors thermal state and measured FPS, and exposes a coarse render tier
/// that scenes consult to decide render-scale, particle counts, shader octaves etc.
///
/// Contract:
///   - .high     → iPhone 15 Pro ProMotion, no throttling; target 120 FPS
///   - .balanced → sustained use or warm device; target 60 FPS, renderScale 0.75
///   - .low      → thermal critical or sustained drop; target 30 FPS, renderScale 0.5
@MainActor
final class RenderBudget: ObservableObject {
    enum Tier: String { case high, balanced, low }

    @Published private(set) var tier: Tier = .high
    @Published private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    @Published private(set) var measuredFPS: Double = 120

    private let logger = Logger(subsystem: "app.nagi", category: "RenderBudget")
    private var thermalObserver: NSObjectProtocol?

    init() {
        thermalState = ProcessInfo.processInfo.thermalState
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.thermalState = ProcessInfo.processInfo.thermalState
                self?.recomputeTier()
            }
        }
        recomputeTier()
    }

    deinit {
        if let observer = thermalObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func report(fps: Double) {
        measuredFPS = fps
        recomputeTier()
    }

    private func recomputeTier() {
        let next: Tier
        switch thermalState {
        case .nominal, .fair:
            next = measuredFPS < 50 ? .balanced : .high
        case .serious:
            next = .balanced
        case .critical:
            next = .low
        @unknown default:
            next = .balanced
        }
        if next != tier {
            let previousRaw = tier.rawValue
            let nextRaw = next.rawValue
            logger.info("tier \(previousRaw, privacy: .public) → \(nextRaw, privacy: .public)")
            tier = next
        }
    }

    /// Scale applied to render targets before MetalFX upscaling.
    var renderScale: Double {
        switch tier {
        case .high: return 1.0
        case .balanced: return 0.75
        case .low: return 0.5
        }
    }

    var targetFPS: Int {
        switch tier {
        case .high: return 120
        case .balanced: return 60
        case .low: return 30
        }
    }

    /// Max octave count for FBM / noise shaders. Decrements under load.
    var maxShaderOctaves: Int {
        switch tier {
        case .high: return 6
        case .balanced: return 4
        case .low: return 3
        }
    }
}
