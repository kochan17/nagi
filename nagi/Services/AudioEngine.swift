import AVFoundation

/// Manages background music and touch sound effects for each texture
final class AudioEngine {
    static let shared = AudioEngine()

    private var bgmPlayer: AVAudioPlayer?
    private var touchStartPlayer: AVAudioPlayer?
    private var touchReleasePlayer: AVAudioPlayer?
    private var currentTextureType: TextureType?

    private init() {
        configureAudioSession()
        prepareTouchSounds()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session configuration failed
        }
    }

    // MARK: - BGM (per texture)

    func startBGM(for texture: TextureType) {
        // Don't restart if same texture
        if currentTextureType == texture, bgmPlayer?.isPlaying == true { return }
        currentTextureType = texture

        stopBGM()

        guard let url = Bundle.main.url(forResource: texture.soundFileName, withExtension: "mp3") else { return }

        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // Loop forever
            bgmPlayer?.volume = 0.0
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()

            // Fade in
            fadeVolume(player: bgmPlayer, to: 0.5, duration: 1.0)
        } catch {
            // BGM playback failed
        }
    }

    func stopBGM() {
        guard let player = bgmPlayer, player.isPlaying else { return }

        // Fade out
        fadeVolume(player: player, to: 0.0, duration: 0.5) {
            player.stop()
        }
    }

    // MARK: - Touch sounds

    private func prepareTouchSounds() {
        if let startURL = Bundle.main.url(forResource: "touch_start", withExtension: "mp3") {
            touchStartPlayer = try? AVAudioPlayer(contentsOf: startURL)
            touchStartPlayer?.prepareToPlay()
            touchStartPlayer?.volume = 0.3
        }

        if let releaseURL = Bundle.main.url(forResource: "touch_release", withExtension: "mp3") {
            touchReleasePlayer = try? AVAudioPlayer(contentsOf: releaseURL)
            touchReleasePlayer?.prepareToPlay()
            touchReleasePlayer?.volume = 0.3
        }
    }

    func playTouchStart() {
        touchStartPlayer?.currentTime = 0
        touchStartPlayer?.play()
    }

    func playTouchRelease() {
        touchReleasePlayer?.currentTime = 0
        touchReleasePlayer?.play()
    }

    // MARK: - Volume fade

    private func fadeVolume(player: AVAudioPlayer?, to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player else {
            completion?()
            return
        }

        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = (targetVolume - player.volume) / Float(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume += volumeStep
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            player.volume = targetVolume
            completion?()
        }
    }
}
