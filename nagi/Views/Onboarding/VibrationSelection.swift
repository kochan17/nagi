import SwiftUI
import CoreHaptics

struct VibrationSelection: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var selected: VibrationMode?
    @State private var engine: CHHapticEngine?

    var body: some View {
        OnboardingSurveyLayout(
            progress: 4.5 / 6,
            title: l10n.string(.vibrationTitle),
            subtitle: l10n.string(.vibrationSubtitle),
            canContinue: selected != nil,
            onContinue: {
                appState.selectedVibration = selected ?? .medium
                onContinue()
            },
            onSkip: onContinue
        ) {
            VStack(spacing: 12) {
                ForEach(VibrationMode.allCases, id: \.self) { mode in
                    VibrationChip(
                        mode: mode,
                        isSelected: selected == mode,
                        action: {
                            selected = mode
                            playHaptic(for: mode)
                        }
                    )
                }
            }
        }
        .onAppear { prepareHaptics() }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            // Haptics not available
        }
    }

    private func playHaptic(for mode: VibrationMode) {
        guard let engine else { return }

        let intensity: Float
        let sharpness: Float

        switch mode {
        case .soft:
            intensity = 0.3
            sharpness = 0.2
        case .medium:
            intensity = 0.6
            sharpness = 0.5
        case .hard:
            intensity = 1.0
            sharpness = 0.8
        case .off:
            return
        }

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Haptic playback failed
        }
    }
}

struct VibrationChip: View {
    let mode: VibrationMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color(white: 0.2))
                    .cornerRadius(8)

                Text(mode.displayName)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: isSelected ? 0.25 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                    )
            )
        }
    }

    private var iconName: String {
        switch mode {
        case .soft: return "wave.3.left"
        case .medium: return "wave.3.left.circle"
        case .hard: return "wave.3.left.circle.fill"
        case .off: return "minus"
        }
    }
}
