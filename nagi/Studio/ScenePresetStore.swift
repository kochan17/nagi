#if DEBUG
import Foundation
import Combine

// MARK: - Slot / Snapshot

extension ScenePresetStore {
    enum Slot {
        case current
        case a
        case b
    }

    struct Snapshot {
        var fireHeight: Double
        var flickerFrequency: Double
        var colorTempBase: Double
        var colorTempTip: Double
        var sparksIntensity: Double
        var smokeOpacity: Double
        var hapticIntensity: Double
        var audioVolume: Double
    }
}

// MARK: - Constants

private enum DefaultValue {
    static let fireHeight: Double       = 0.75
    static let flickerFrequency: Double = 8
    static let colorTempBase: Double    = 2700
    static let colorTempTip: Double     = 1600
    static let sparksIntensity: Double  = 1.0
    static let smokeOpacity: Double     = 0.5
    static let hapticIntensity: Double  = 0.7
    static let audioVolume: Double      = 0.8
}

private enum UDKey {
    static let prefix = "nagi.debug.preset."
    static let fireHeight       = prefix + "fireHeight"
    static let flickerFrequency = prefix + "flickerFrequency"
    static let colorTempBase    = prefix + "colorTempBase"
    static let colorTempTip     = prefix + "colorTempTip"
    static let sparksIntensity  = prefix + "sparksIntensity"
    static let smokeOpacity     = prefix + "smokeOpacity"
    static let hapticIntensity  = prefix + "hapticIntensity"
    static let audioVolume      = prefix + "audioVolume"
}

// MARK: - ScenePresetStore

final class ScenePresetStore: ObservableObject {
    @Published var fireHeight: Double       { didSet { persist(UDKey.fireHeight, fireHeight) } }
    @Published var flickerFrequency: Double { didSet { persist(UDKey.flickerFrequency, flickerFrequency) } }
    @Published var colorTempBase: Double    { didSet { persist(UDKey.colorTempBase, colorTempBase) } }
    @Published var colorTempTip: Double     { didSet { persist(UDKey.colorTempTip, colorTempTip) } }
    @Published var sparksIntensity: Double  { didSet { persist(UDKey.sparksIntensity, sparksIntensity) } }
    @Published var smokeOpacity: Double     { didSet { persist(UDKey.smokeOpacity, smokeOpacity) } }
    @Published var hapticIntensity: Double  { didSet { persist(UDKey.hapticIntensity, hapticIntensity) } }
    @Published var audioVolume: Double      { didSet { persist(UDKey.audioVolume, audioVolume) } }

    @Published private(set) var activeSlot: Slot = .current

    // Stored snapshots for slots A and B
    private(set) var slotA: Snapshot?
    private(set) var slotB: Snapshot?

    private let defaults = UserDefaults.standard

    init() {
        fireHeight       = defaults.object(forKey: UDKey.fireHeight)       as? Double ?? DefaultValue.fireHeight
        flickerFrequency = defaults.object(forKey: UDKey.flickerFrequency) as? Double ?? DefaultValue.flickerFrequency
        colorTempBase    = defaults.object(forKey: UDKey.colorTempBase)    as? Double ?? DefaultValue.colorTempBase
        colorTempTip     = defaults.object(forKey: UDKey.colorTempTip)     as? Double ?? DefaultValue.colorTempTip
        sparksIntensity  = defaults.object(forKey: UDKey.sparksIntensity)  as? Double ?? DefaultValue.sparksIntensity
        smokeOpacity     = defaults.object(forKey: UDKey.smokeOpacity)     as? Double ?? DefaultValue.smokeOpacity
        hapticIntensity  = defaults.object(forKey: UDKey.hapticIntensity)  as? Double ?? DefaultValue.hapticIntensity
        audioVolume      = defaults.object(forKey: UDKey.audioVolume)      as? Double ?? DefaultValue.audioVolume
    }

    func reset() {
        fireHeight       = DefaultValue.fireHeight
        flickerFrequency = DefaultValue.flickerFrequency
        colorTempBase    = DefaultValue.colorTempBase
        colorTempTip     = DefaultValue.colorTempTip
        sparksIntensity  = DefaultValue.sparksIntensity
        smokeOpacity     = DefaultValue.smokeOpacity
        hapticIntensity  = DefaultValue.hapticIntensity
        audioVolume      = DefaultValue.audioVolume
        activeSlot       = .current
    }

    // MARK: - Snapshot A/B

    /// Save current parameter values to slot A.
    func snapshotA() {
        slotA = currentSnapshot()
        if activeSlot == .a { activeSlot = .current }
    }

    /// Save current parameter values to slot B.
    func snapshotB() {
        slotB = currentSnapshot()
        if activeSlot == .b { activeSlot = .current }
    }

    func applyA() {
        guard let snap = slotA else { return }
        apply(snap)
        activeSlot = .a
    }

    func applyB() {
        guard let snap = slotB else { return }
        apply(snap)
        activeSlot = .b
    }

    // MARK: - Internal helpers

    private func currentSnapshot() -> Snapshot {
        Snapshot(
            fireHeight: fireHeight,
            flickerFrequency: flickerFrequency,
            colorTempBase: colorTempBase,
            colorTempTip: colorTempTip,
            sparksIntensity: sparksIntensity,
            smokeOpacity: smokeOpacity,
            hapticIntensity: hapticIntensity,
            audioVolume: audioVolume
        )
    }

    private func apply(_ snap: Snapshot) {
        fireHeight       = snap.fireHeight
        flickerFrequency = snap.flickerFrequency
        colorTempBase    = snap.colorTempBase
        colorTempTip     = snap.colorTempTip
        sparksIntensity  = snap.sparksIntensity
        smokeOpacity     = snap.smokeOpacity
        hapticIntensity  = snap.hapticIntensity
        audioVolume      = snap.audioVolume
    }

    private func persist(_ key: String, _ value: Double) {
        defaults.set(value, forKey: key)
    }
}
#endif
