import SwiftUI

struct CarouselPage: View {
    let title: String
    let subtitle: String
    let imageName: String
    let pageIndex: Int
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Preview image with pulsing glow behind it
            ZStack {
                Circle()
                    .fill(gradientColor.opacity(0.2))
                    .blur(radius: 30)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: pulse
                    )

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 300)
                    .padding(.horizontal, 32)
            }
            .onAppear { pulse = true }

            Spacer()
                .frame(height: 40)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(subtitle)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == pageIndex ? Color.cyan : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            Spacer()

            NagiButton(title: l10n.string(.continueButton), action: onContinue)
                .padding(.bottom, 48)
        }
    }

    private var gradientColors: [Color] {
        switch pageIndex {
        case 0: return [.pink.opacity(0.6), .purple.opacity(0.8)]
        case 1: return [.cyan.opacity(0.6), .purple.opacity(0.8)]
        case 2: return [.teal.opacity(0.6), .blue.opacity(0.8)]
        default: return [.gray, .black]
        }
    }

    private var gradientColor: Color {
        switch pageIndex {
        case 0: return .pink
        case 1: return .cyan
        case 2: return .teal
        default: return .purple
        }
    }
}
