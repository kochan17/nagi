import SwiftUI

struct BreathingQuestion: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var selected: Bool?

    var body: some View {
        OnboardingSurveyLayout(
            progress: 4 / 6,
            title: l10n.string(.breathingTitle),
            subtitle: nil,
            canContinue: selected != nil,
            onContinue: {
                appState.wantsBreathing = selected ?? false
                onContinue()
            },
            onSkip: onContinue
        ) {
            VStack(spacing: 12) {
                SurveyChip(
                    title: l10n.string(.yes),
                    isSelected: selected == true,
                    action: { selected = true }
                )
                SurveyChip(
                    title: l10n.string(.no),
                    isSelected: selected == false,
                    action: { selected = false }
                )
            }
        }
    }
}
