import SwiftUI

struct OnboardingSurveyLayout<Content: View>: View {
    let progress: CGFloat
    let title: String
    let subtitle: String?
    let canContinue: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }

                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()
                .frame(height: 32)

            // Title
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }

            Spacer()
                .frame(height: 32)

            // Content
            ScrollView {
                content()
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Continue button
            NagiButton(
                title: "Continue",
                isEnabled: canContinue,
                action: onContinue
            )
            .padding(.bottom, 8)

            Button("Skip") {
                onSkip()
            }
            .foregroundColor(.gray)
            .padding(.bottom, 32)
        }
    }
}
