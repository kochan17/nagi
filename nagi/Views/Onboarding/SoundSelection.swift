import SwiftUI

struct SoundSelection: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var selected: Set<L10nKey> = []

    private let soundKeys: [(title: L10nKey, subtitle: L10nKey)] = [
        (.soundNature, .soundNatureSubtitle),
        (.soundHealing, .soundHealingSubtitle),
        (.soundDeepSleep, .soundDeepSleepSubtitle),
        (.soundASMR, .soundASMRSubtitle),
        (.soundAmbient, .soundAmbientSubtitle)
    ]

    var body: some View {
        OnboardingSurveyLayout(
            progress: 3 / 6,
            title: l10n.string(.soundTitle),
            subtitle: l10n.string(.soundSubtitle),
            canContinue: !selected.isEmpty,
            onContinue: {
                appState.selectedSounds = selected.map { l10n.string($0) }
                onContinue()
            },
            onSkip: onContinue
        ) {
            VStack(spacing: 12) {
                ForEach(soundKeys, id: \.title.rawValue) { pair in
                    SoundChip(
                        title: l10n.string(pair.title),
                        subtitle: l10n.string(pair.subtitle),
                        isSelected: selected.contains(pair.title),
                        action: {
                            if selected.contains(pair.title) {
                                selected.remove(pair.title)
                            } else {
                                selected.insert(pair.title)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct SoundChip: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
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
}
