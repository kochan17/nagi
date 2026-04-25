import SwiftUI

struct BreathView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var isBreathing = false
    @State private var phase: BreathPhase = .inhale
    @State private var circleScale: CGFloat = 0.5

    enum BreathPhase {
        case inhale
        case hold
        case exhale
    }

    private func phaseText(_ phase: BreathPhase) -> String {
        switch phase {
        case .inhale: return l10n.string(.breatheIn)
        case .hold: return l10n.string(.hold)
        case .exhale: return l10n.string(.breatheOut)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Breathing circle
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.cyan.opacity(0.6), .cyan.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .scaleEffect(circleScale)
                        .frame(width: 250, height: 250)

                    Text(phaseText(phase))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                Spacer()

                // Start/Stop button
                Button(action: {
                    isBreathing.toggle()
                    if isBreathing {
                        startBreathingCycle()
                    }
                }) {
                    Text(isBreathing ? l10n.string(.stop) : l10n.string(.start))
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(Color.cyan)
                        .cornerRadius(25)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func startBreathingCycle() {
        guard isBreathing else { return }

        // Inhale (4 seconds)
        phase = .inhale
        withAnimation(.easeInOut(duration: 4)) {
            circleScale = 1.0
        }

        // Hold (4 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard self.isBreathing else { return }
            self.phase = .hold
        }

        // Exhale (6 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            guard self.isBreathing else { return }
            self.phase = .exhale
            withAnimation(.easeInOut(duration: 6)) {
                self.circleScale = 0.5
            }
        }

        // Repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 14) {
            self.startBreathingCycle()
        }
    }
}
