import SwiftUI

struct ReminderSelection: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var selected: ReminderTime?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                ProgressView(value: 5.5, total: 6)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .padding(.horizontal, 40)
                Spacer()
            }
            .padding(.top, 16)

            Spacer().frame(height: 40)

            Text(l10n.string(.reminderTitle))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            Text(l10n.string(.reminderSubtitle))
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Spacer().frame(height: 32)

            VStack(spacing: 12) {
                ForEach(ReminderTime.allCases, id: \.self) { time in
                    SurveyChip(
                        title: time.displayName,
                        isSelected: selected == time,
                        action: { selected = time }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            NagiButton(
                title: l10n.string(.setReminder),
                isEnabled: selected != nil,
                action: {
                    appState.reminderTime = selected
                    onContinue()
                }
            )
            .padding(.bottom, 8)

            Button(l10n.string(.skip)) {
                onContinue()
            }
            .foregroundColor(.gray)
            .padding(.bottom, 32)
        }
    }
}
