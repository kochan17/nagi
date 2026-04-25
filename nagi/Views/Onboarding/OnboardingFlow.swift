import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var storeKit: StoreKitManager
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var currentStep = 0

    private let totalSteps = 13

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch currentStep {
            case 0:
                BackgroundMusicIntro(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 1:
                CarouselPage(
                    title: l10n.string(.carouselTitle1),
                    subtitle: l10n.string(.carouselSubtitle1),
                    imageName: "particles_preview",
                    pageIndex: 0,
                    onContinue: nextStep
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            case 2:
                CarouselPage(
                    title: l10n.string(.carouselTitle2),
                    subtitle: l10n.string(.carouselSubtitle2),
                    imageName: "slimes_preview",
                    pageIndex: 1,
                    onContinue: nextStep
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            case 3:
                CarouselPage(
                    title: l10n.string(.carouselTitle3),
                    subtitle: l10n.string(.carouselSubtitle3),
                    imageName: "music_preview",
                    pageIndex: 2,
                    onContinue: nextStep
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            case 4:
                PurposeSelection(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 5:
                TextureSelection(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 6:
                SoundSelection(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 7:
                BreathingQuestion(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 8:
                VibrationSelection(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 9:
                StruggleSelection(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 10:
                ReminderSelection(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 11:
                NotificationPermission(onContinue: nextStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 12:
                PaywallView(onContinue: {
                    appState.hasCompletedOnboarding = true
                }, storeKit: storeKit)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
    }

    private func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }
}
