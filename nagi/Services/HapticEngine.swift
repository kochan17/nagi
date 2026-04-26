import CoreHaptics

// MARK: - Per-texture haptic profile

enum ReleaseStyle {
    case bounce   // elastic multi-tap decay (slime)
    case snap     // sharp strong + soft tail (particles)
    case fade     // single long-tail fade (fluids, orbs)
    case ripple   // spaced decreasing taps (waves, kaleidoscope)
}

struct HapticProfile {
    let baseIntensity: Float
    let baseSharpness: Float
    let releaseStyle: ReleaseStyle

    static let `default` = HapticProfile(baseIntensity: 0.4, baseSharpness: 0.2, releaseStyle: .snap)

    static func profile(for textureType: TextureType) -> HapticProfile {
        switch textureType {
        case .fluids:
            return HapticProfile(baseIntensity: 0.3, baseSharpness: 0.15, releaseStyle: .fade)
        case .kaleidoscope:
            return HapticProfile(baseIntensity: 0.5, baseSharpness: 0.4, releaseStyle: .ripple)
        case .orbs:
            return HapticProfile(baseIntensity: 0.4, baseSharpness: 0.1, releaseStyle: .fade)
        case .particles:
            return HapticProfile(baseIntensity: 0.6, baseSharpness: 0.8, releaseStyle: .snap)
        case .slime:
            return HapticProfile(baseIntensity: 0.7, baseSharpness: 0.3, releaseStyle: .bounce)
        case .waves:
            return HapticProfile(baseIntensity: 0.5, baseSharpness: 0.5, releaseStyle: .ripple)
        case .fractal:
            return HapticProfile(baseIntensity: 0.55, baseSharpness: 0.6, releaseStyle: .ripple)
        case .campfire:
            return HapticProfile(baseIntensity: 0.5, baseSharpness: 0.7, releaseStyle: .snap)
        case .forest:
            return HapticProfile(baseIntensity: 0.45, baseSharpness: 0.4, releaseStyle: .ripple)
        }
    }
}

// MARK: - Advanced haptic engine for fluid interaction

final class HapticEngine {
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?

    private var isPlaying = false
    private var currentProfile: HapticProfile = .default

    /// Named pre-loaded patterns for scene-based haptics (bonfire crackle, etc.).
    /// Pre-loading avoids the first-fire latency that would miss the 30ms SyncClock budget.
    private var namedPatterns: [String: CHHapticPattern] = [:]

    init() {
        prepareEngine()
    }

    // MARK: - Setup

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true

            engine?.stoppedHandler = { [weak self] reason in
                self?.isPlaying = false
            }

            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    // Reset failed
                }
            }

            try engine?.start()
        } catch {
            // Haptics unavailable
        }
    }

    // MARK: - Profile

    func loadProfile(for textureType: TextureType) {
        currentProfile = HapticProfile.profile(for: textureType)
    }

    // MARK: - Continuous touch haptic (plays while finger is on screen)

    func startContinuousHaptic() {
        guard let engine, !isPlaying else { return }

        let intensityParam = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: currentProfile.baseIntensity
        )
        let sharpnessParam = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: currentProfile.baseSharpness
        )

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: 100
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
            isPlaying = true
        } catch {
            // Failed to start
        }
    }

    // MARK: - Update haptic based on touch velocity/pressure

    func updateContinuousHaptic(velocity: Float, pressure: Float) {
        guard isPlaying else { return }

        let velocityNormalized = min(velocity / 500.0, 1.0)

        // Scale on top of profile's base values so each texture retains its character
        let intensity = currentProfile.baseIntensity + velocityNormalized * (1.0 - currentProfile.baseIntensity) * 0.6
        let sharpness = currentProfile.baseSharpness + velocityNormalized * (1.0 - currentProfile.baseSharpness) * 0.5

        let intensityParam = CHHapticDynamicParameter(
            parameterID: .hapticIntensityControl,
            value: min(intensity, 1.0),
            relativeTime: 0
        )
        let sharpnessParam = CHHapticDynamicParameter(
            parameterID: .hapticSharpnessControl,
            value: min(sharpness, 1.0),
            relativeTime: 0
        )

        do {
            try continuousPlayer?.sendParameters([intensityParam, sharpnessParam], atTime: CHHapticTimeImmediate)
        } catch {
            // Update failed
        }
    }

    // MARK: - Stop continuous haptic

    func stopContinuousHaptic() {
        guard isPlaying else { return }
        do {
            try continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
            isPlaying = false
        } catch {
            // Stop failed
        }
    }

    // MARK: - Transient haptics (one-shot effects)

    func playReleaseHaptic() {
        guard let engine else { return }

        let events: [CHHapticEvent]
        switch currentProfile.releaseStyle {
        case .bounce:
            // Elastic multi-tap decay (slime: squishy bounce-back)
            events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0.07
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                    ],
                    relativeTime: 0.13
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.19
                )
            ]
        case .snap:
            // Sharp strong + soft tail (particles: crisp sparkle)
            events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0.06
                )
            ]
        case .fade:
            // Gentle single long-tail fade (fluids / orbs: smooth release)
            events = [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                        CHHapticEventParameter(parameterID: .attackTime, value: 0.0),
                        CHHapticEventParameter(parameterID: .decayTime, value: 0.3),
                        CHHapticEventParameter(parameterID: .sustained, value: 0)
                    ],
                    relativeTime: 0,
                    duration: 0.35
                )
            ]
        case .ripple:
            // Spaced decreasing taps (waves / kaleidoscope: rhythmic spread)
            events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: 0.1
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.2
                )
            ]
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Release haptic failed
        }
    }

    // MARK: - Named pattern registry

    func register(name: String, pattern: CHHapticPattern) {
        namedPatterns[name] = pattern
    }

    @discardableResult
    func play(name: String) -> Bool {
        guard let engine, let pattern = namedPatterns[name] else { return false }
        do {
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Bonfire pattern factories

    static func makeCampfireSmallCracklePattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    static func makeCampfireBigPopPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.95),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    static func makeCampfireSustainedRustlePattern(duration: TimeInterval = 0.4) throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
                CHHapticEventParameter(parameterID: .attackTime, value: 0.0),
                CHHapticEventParameter(parameterID: .decayTime, value: Float(duration * 0.8)),
                CHHapticEventParameter(parameterID: .sustained, value: 0)
            ],
            relativeTime: 0,
            duration: duration
        )
        // Intensity curve: 0.35 → 0.15
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.35),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.15)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameterCurves: [intensityCurve])
    }

    // MARK: - Forest pattern factories

    /// Leaf step: a dry, crisp transient like pressing down on a dry autumn leaf — two quick
    /// micro-taps to suggest the crunch-and-crackle texture of the leaf bed underfoot.
    static func makeForestLeafStepPattern() throws -> CHHapticPattern {
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.65),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
                ],
                relativeTime: 0.055
            )
        ]
        return try CHHapticPattern(events: events, parameters: [])
    }

    /// Rustle gust: a continuous soft rumble that fades — the sound of leaves stirring
    /// when fingers lift and the canopy settles back.
    static func makeForestRustleGustPattern(duration: TimeInterval = 0.5) throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.30),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                CHHapticEventParameter(parameterID: .attackTime, value: 0.02),
                CHHapticEventParameter(parameterID: .decayTime, value: Float(duration * 0.75)),
                CHHapticEventParameter(parameterID: .sustained, value: 0)
            ],
            relativeTime: 0,
            duration: duration
        )
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.30),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.4, value: 0.20),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.05)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameterCurves: [intensityCurve])
    }

    /// Deep groan: low-frequency transient for a held press — an ancient tree flexing
    /// in the wind, heavy and resonant.
    static func makeForestDeepGroanPattern() throws -> CHHapticPattern {
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.88),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.50),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.10)
                ],
                relativeTime: 0.12
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.08)
                ],
                relativeTime: 0.24
            )
        ]
        return try CHHapticPattern(events: events, parameters: [])
    }

    /// Splash haptic when touching fluid for the first time
    func playSplashHaptic() {
        guard let engine else { return }

        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: currentProfile.baseSharpness + 0.2)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: currentProfile.baseSharpness + 0.1)
                ],
                relativeTime: 0.05
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.15),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: currentProfile.baseSharpness)
                ],
                relativeTime: 0.1
            )
        ]

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Splash haptic failed
        }
    }
}
