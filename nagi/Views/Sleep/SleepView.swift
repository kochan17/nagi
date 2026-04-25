import SwiftUI

struct SleepView: View {
    @ObservedObject private var l10n = LocalizationManager.shared

    private var sleepSounds: [(String, String, Color)] {
        [
            (l10n.string(.soundRain), "cloud.rain.fill", Color.blue),
            (l10n.string(.soundOceanWaves), "water.waves", Color.teal),
            (l10n.string(.soundThunder), "cloud.bolt.fill", Color.purple),
            (l10n.string(.soundForest), "leaf.fill", Color.green),
            (l10n.string(.soundCampfire), "flame.fill", Color.orange),
            (l10n.string(.soundWhiteNoise), "waveform", Color.gray)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(l10n.string(.sleepStories))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)

                        // Sleep sound cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(sleepSounds, id: \.0) { sound in
                                SleepSoundCard(
                                    title: sound.0,
                                    icon: sound.1,
                                    color: sound.2
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SleepSoundCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1))
        )
    }
}
