import SwiftUI

struct StruggleSelection: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared

    private let struggleKeys: [L10nKey] = [
        .struggleAnxiety, .struggleDepression,
        .struggleSleepDisorder, .struggleADHD,
        .strugglePTSD, .struggleOCD,
        .struggleBipolar, .strugglePanic
    ]

    @State private var selected: Set<L10nKey> = []

    var body: some View {
        OnboardingSurveyLayout(
            progress: 5 / 6,
            title: l10n.string(.struggleTitle),
            subtitle: l10n.string(.struggleSubtitle),
            canContinue: !selected.isEmpty,
            onContinue: {
                appState.selectedStruggles = selected.map { l10n.string($0) }
                onContinue()
            },
            onSkip: onContinue
        ) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(struggleKeys, id: \.rawValue) { key in
                    SurveyChip(
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
