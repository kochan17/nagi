import SwiftUI

struct TodayView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var moodStep = 1
    @State private var showRelaxation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Premium badge
                        HStack {
                            Spacer()
                            PremiumBadge()
                        }
                        .padding(.horizontal, 16)

                        // Section 1: Mood check or Today's relaxation
                        if !showRelaxation {
                            moodCheckSection
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            todayRelaxationSection
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // Section 2: Recommended for you
                        recommendedSection

                        // Section 3: Meditations
                        meditationsSection

                        // Section 4: Your favorite
                        favoriteSection

                        // Section 5: For your better sleeping
                        sleepingSection

                        // Section 6: Mood diary (bottom card)
                        moodDiarySection

                        Spacer().frame(height: 20)
                    }
                    .padding(.top, 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showRelaxation)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: moodStep)
                }
            }
        }
    }

    // MARK: - Section 1: Mood Check

    @ViewBuilder
    private var moodCheckSection: some View {
        VStack(spacing: 16) {
            Text("\(moodStep)/2 step")
                .font(.caption)
                .foregroundColor(.gray)

            if moodStep == 1 {
                VStack(spacing: 16) {
                    Text(l10n.string(.howAreYouFeeling))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(l10n.string(.describeMood))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            MoodButton(mood: mood) {
                                appState.todayMood = mood
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { moodStep = 2 }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            } else if moodStep == 2 {
                VStack(spacing: 16) {
                    Text(l10n.string(.whatsOnMind))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(l10n.string(.letUsKnow))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(MindTopic.allCases, id: \.self) { topic in
                            MindTopicButton(topic: topic) {
                                appState.todayMindTopic = topic
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showRelaxation = true }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            Button(l10n.string(.dontWantToShare)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showRelaxation = true }
            }
            .font(.caption)
            .foregroundColor(.cyan)
        }
    }

    // MARK: - Section 1b: Today's Relaxation (after mood check)

    @ViewBuilder
    private var todayRelaxationSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.6), .cyan.opacity(0.3), .black],
                            center: .center,
                            startRadius: 20,
                            endRadius: 150
                        )
                    )
                    .frame(width: 250, height: 250)
                    .blur(radius: 20)

                Text(l10n.string(.todaysRelaxation))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            NavigationLink {
                SlimeView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text(l10n.string(.start))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.cyan)
                .cornerRadius(25)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Section 2: Recommended for you

    @ViewBuilder
    private var recommendedSection: some View {
        SectionHeader(
            title: l10n.string(.recommendedForYou),
            subtitle: l10n.string(.selectionsBasedOnInterests)
        )

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ContentCard(title: l10n.string(.fluids), gradient: [.purple.opacity(0.8), .blue.opacity(0.6)])
                ContentCard(title: l10n.string(.kaleidoscopes), gradient: [.blue.opacity(0.7), .purple.opacity(0.5)])
                ContentCard(title: l10n.string(.categoryOrbs), gradient: [.pink.opacity(0.6), .orange.opacity(0.4)])
                ContentCard(title: l10n.string(.diySlimes), gradient: [.cyan.opacity(0.6), .teal.opacity(0.4)])
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 3: Meditations

    @ViewBuilder
    private var meditationsSection: some View {
        SectionHeader(
            title: l10n.string(.meditations),
            subtitle: l10n.string(.meditationsSubtitle)
        )

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ContentCard(title: l10n.string(.embracingLove), gradient: [.green.opacity(0.7), .teal.opacity(0.5)])
                ContentCard(title: l10n.string(.soothingAnxiety), gradient: [.cyan.opacity(0.7), .blue.opacity(0.5)])
                ContentCard(title: l10n.string(.hopeAndHealing), gradient: [.orange.opacity(0.6), .pink.opacity(0.4)])
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 4: Your favorite

    @ViewBuilder
    private var favoriteSection: some View {
        SectionHeader(
            title: l10n.string(.yourFavorite),
            subtitle: l10n.string(.yourFavoriteSubtitle)
        )

        VStack(spacing: 16) {
            Text(l10n.string(.noFavoritesYet))
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(l10n.string(.explore)) {}
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
        .padding(.vertical, 8)
    }

    // MARK: - Section 5: For your better sleeping

    @ViewBuilder
    private var sleepingSection: some View {
        SectionHeader(
            title: l10n.string(.forBetterSleeping),
            subtitle: l10n.string(.forBetterSleepingSubtitle)
        )

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ContentCard(title: l10n.string(.relaxMixes), gradient: [.purple.opacity(0.8), .pink.opacity(0.5)])
                ContentCard(title: l10n.string(.whiteNoiseSlimes), gradient: [.gray.opacity(0.6), .white.opacity(0.3)])
                ContentCard(title: l10n.string(.soundRain), gradient: [.blue.opacity(0.6), .cyan.opacity(0.3)])
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Section 6: Mood diary

    @ViewBuilder
    private var moodDiarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(l10n.string(.moodDiary))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(l10n.string(.moodDiaryQuestion))
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Button(l10n.string(.checkMyMood)) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showRelaxation = false
                            moodStep = 1
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.cyan)
                    .cornerRadius(20)
                }

                Spacer()

                Text("😊")
                    .font(.system(size: 48))
                    .opacity(0.6)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.1))
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

struct ContentCard: View {
    let title: String
    let gradient: [Color]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(12)
        }
    }
}

struct MoodButton: View {
    let mood: Mood
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.largeTitle)
                Text(mood.displayName)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct MindTopicButton: View {
    let topic: MindTopic
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: topic.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(white: 0.15)))
                Text(topic.displayName)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct PremiumBadge: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            Text(l10n.string(.premium))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color(white: 0.15))
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.25), location: 0.45),
                                .init(color: .white.opacity(0.4), location: 0.5),
                                .init(color: .white.opacity(0.25), location: 0.55),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: shimmerOffset * geo.size.width * 2)
                        .clipShape(Capsule())
                    }
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
}
