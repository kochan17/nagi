import AVFoundation
import PHASE
import os.log
import simd

/// PHASE-backed spatial audio with a small helper surface for registering
/// sound assets and firing them from world positions.
///
/// Responsibilities kept here:
///   - Start/stop the PHASE engine
///   - Register `.wav`/`.aiff` sound assets from bundle URLs
///   - Emit one-shot events at a 3D position relative to a listener
///
/// The full PHASE asset-tree/event construction is per-scene (see
/// `BonfireAudio` etc.). This class intentionally stays generic.
final class SpatialAudioEngine {
    private let logger = Logger(subsystem: "app.nagi", category: "SpatialAudioEngine")
    let phase: PHASEEngine = PHASEEngine(updateMode: .automatic)
    private(set) var isReady: Bool = false
    private(set) var registeredAssets: Set<String> = []

    func prepare() async {
        do {
            try configureAVAudioSession()
            try phase.start()
            isReady = true
        } catch {
            logger.error("prepare failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func configureAVAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }

    /// Register a sound asset from a bundle URL. Safe to call multiple times;
    /// subsequent calls with the same identifier are ignored.
    @discardableResult
    func registerSoundAsset(identifier: String, url: URL) -> Bool {
        guard !registeredAssets.contains(identifier) else { return true }
        do {
            _ = try phase.assetRegistry.registerSoundAsset(
                url: url,
                identifier: identifier,
                assetType: .resident,
                channelLayout: nil,
                normalizationMode: .dynamic
            )
            registeredAssets.insert(identifier)
            return true
        } catch {
            logger.error("register \(identifier, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func teardown() {
        phase.stop()
        registeredAssets.removeAll()
        isReady = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
