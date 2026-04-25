import SwiftUI

struct TextureSelection: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var selected: Set<L10nKey> = []

    private let textureKeys: [L10nKey] = [.textureNature, .textureLight, .textureFood, .textureParticles]

    var body: some View {
        OnboardingSurveyLayout(
            progress: 2 / 6,
            title: l10n.string(.textureTitle),
            subtitle: l10n.string(.textureSubtitle),
            canContinue: !selected.isEmpty,
            onContinue: {
                appState.selectedTextures = selected.map { l10n.string($0) }
                onContinue()
            },
            onSkip: onContinue
        ) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(textureKeys, id: \.rawValue) { key in
                    TextureCard(
                        title: l10n.string(key),
                        isSelected: selected.contains(key),
                        action: {
                            if selected.contains(key) {
                                selected.remove(key)
                            } else {
                                selected.insert(key)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct TextureCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                    )
                    .frame(height: 120)

                VStack {
                    // Placeholder for texture image
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.5), .cyan.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 70)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                }
            }
        }
    }
}
