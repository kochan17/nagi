import SwiftUI

struct BackgroundMusicIntro: View {
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Gradient circle icon with glow
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: .purple.opacity(0.4), radius: 20)

                    Image(systemName: "music.note")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Title + subtitle
                VStack(spacing: 12) {
                    Text(l10n.string(.backgroundMusic))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(l10n.string(.calmingMusicDescription))
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Tips
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "headphones")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title3)
                        Text(l10n.string(.useEarphones))
                            .foregroundColor(.white.opacity(0.8))
                            .font(.subheadline)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title3)
                        Text(l10n.string(.adjustVolume))
                            .foregroundColor(.white.opacity(0.8))
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                NagiButton(title: l10n.string(.ok), style: .white, action: onContinue)
                    .padding(.bottom, 48)
            }
        }
    }
}
