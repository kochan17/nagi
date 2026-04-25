import SwiftUI

struct PurposeSelection: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var selected: L10nKey?

    private var purposeKeys: [L10nKey] {
        [.purposeRelieveStress, .purposeFallAsleep, .purposeFeelCalm,
         .purposeEaseAnxiety, .purposeIncreaseHappiness, .purposeBoostEnergy]
    }

    var body: some View {
        OnboardingSurveyLayout(
            progress: 1 / 6,
            title: l10n.string(.purposeTitle),
            subtitle: l10n.string(.purposeSubtitle),
            canContinue: selected != nil,
            onContinue: {
                if let key = selected {
                    appState.selectedPurpose = l10n.string(key)
                }
                onContinue()
            },
            onSkip: onContinue
        ) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(purposeKeys, id: \.rawValue) { key in
                    SurveyChip(
                        title: l10n.string(key),
                        isSelected: selected == key,
                        action: { selected = key }
                    )
                }
            }
        }
    }
}
