import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var l10n = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    Section {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            VStack(alignment: .leading) {
                                Text(l10n.string(.nagiUser))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(appState.isSubscribed ? l10n.string(.profilePremium) : l10n.string(.profileFree))
                                    .font(.caption)
                                    .foregroundColor(appState.isSubscribed ? .yellow : .gray)
                            }
                        }
                        .listRowBackground(Color(white: 0.1))
                    }

                    Section(l10n.string(.settings)) {
                        ProfileRow(icon: "bell.fill", title: l10n.string(.notifications))
                        ProfileRow(icon: "hand.tap.fill", title: l10n.string(.vibration))
                        ProfileRow(icon: "speaker.wave.2.fill", title: l10n.string(.sound))
                    }
                    .listRowBackground(Color(white: 0.1))

                    Section(l10n.string(.language)) {
                        Picker(l10n.string(.language), selection: $l10n.selectedLanguage) {
                            ForEach(LocalizationManager.shared.availableLanguages, id: \.code) { lang in
                                Text(lang.displayName).tag(lang.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                        .listRowBackground(Color(white: 0.1))
                    }
                    .listRowBackground(Color(white: 0.1))

                    Section(l10n.string(.subscription)) {
                        ProfileRow(icon: "crown.fill", title: l10n.string(.manageSubscription))
                        ProfileRow(icon: "arrow.clockwise", title: l10n.string(.restorePurchases))
                    }
                    .listRowBackground(Color(white: 0.1))

                    Section(l10n.string(.about)) {
                        ProfileRow(icon: "doc.text.fill", title: l10n.string(.termsOfUseProfile))
                        ProfileRow(icon: "hand.raised.fill", title: l10n.string(.privacyPolicyProfile))
                    }
                    .listRowBackground(Color(white: 0.1))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
