import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    let onContinue: () -> Void

    @ObservedObject private var l10n = LocalizationManager.shared
    @ObservedObject var storeKit: StoreKitManager
    @State private var selectedPlan: Plan = .annual
    @State private var showError = false
    @State private var featureCardsOffset: CGFloat = 60
    @State private var featureCardsOpacity: Double = 0
    @State private var planRowsOpacity: Double = 0
    @State private var ctaPulse = false

    enum Plan {
        case annual
        case monthly
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0, blue: 0.15),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 60)

                // Headline
                Text(l10n.string(.unlockInfinite))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(l10n.string(.relaxation))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(l10n.string(.reduceAnxiety))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                // Feature list with green checkmarks — slide up from bottom
                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(icon: "hand.point.up.fill",
                               text: l10n.string(.interactive) + " " + l10n.string(.slimes))
                    FeatureRow(icon: "circle.hexagongrid.fill",
                               text: l10n.string(.unlimited) + " " + l10n.string(.textures))
                    FeatureRow(icon: "music.note",
                               text: l10n.string(.backgroundMusic))
                }
                .padding(.horizontal, 32)
                .offset(y: featureCardsOffset)
                .opacity(featureCardsOpacity)

                Spacer()
                    .frame(height: 8)

                // Plan selection — fades in after feature cards
                VStack(spacing: 12) {
                    // Annual plan
                    PlanRow(
                        title: l10n.string(.annualPlan),
                        price: l10n.string(.annualPrice),
                        weeklyPrice: l10n.string(.annualWeekly),
                        badge: l10n.string(.discount65),
                        isSelected: selectedPlan == .annual,
                        isBestValue: true,
                        action: { selectedPlan = .annual }
                    )

                    // Monthly plan
                    PlanRow(
                        title: l10n.string(.monthlyPlan),
                        price: l10n.string(.monthlyPrice),
                        weeklyPrice: l10n.string(.monthlyWeekly),
                        badge: nil,
                        isSelected: selectedPlan == .monthly,
                        isBestValue: false,
                        action: { selectedPlan = .monthly }
                    )
                }
                .padding(.horizontal, 24)
                .opacity(planRowsOpacity)

                Text(l10n.string(.cancelAnytime))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(planRowsOpacity)

                // CTA — gradient with glow
                Button(action: {
                    Task {
                        let productID = selectedPlan == .annual
                            ? StoreKitManager.annualProductID
                            : StoreKitManager.monthlyProductID
                        if let product = storeKit.products.first(where: { $0.id == productID }) {
                            await storeKit.purchase(product)
                            if appState.isSubscribed {
                                onContinue()
                            } else if storeKit.errorMessage != nil {
                                showError = true
                            }
                        }
                    }
                }) {
                    Group {
                        if storeKit.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text(l10n.string(.tryForFree))
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.5), radius: 16, x: 0, y: 4)
                    )
                }
                .disabled(storeKit.isLoading)
                .padding(.horizontal, 32)
                .scaleEffect(ctaPulse ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: ctaPulse)

                // Restore Purchases text link
                Button(action: {
                    Task {
                        await storeKit.restorePurchases()
                        if appState.isSubscribed {
                            onContinue()
                        } else if storeKit.errorMessage != nil {
                            showError = true
                        }
                    }
                }) {
                    Text(l10n.string(.restore))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(planRowsOpacity)

                // Footer links
                HStack(spacing: 24) {
                    Button(l10n.string(.termsOfUse)) {}
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Button(l10n.string(.privacyPolicy)) {}
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 24)
                .opacity(planRowsOpacity)
            }

            // X close button — top-right
            Button(action: onContinue) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                featureCardsOffset = 0
                featureCardsOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.35)) {
                planRowsOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                ctaPulse = true
            }
        }
        .task {
            await storeKit.loadProducts()
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {
                storeKit.errorMessage = nil
            }
        } message: {
            Text(storeKit.errorMessage ?? "An unknown error occurred.")
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PlanRow: View {
    let title: String
    let price: String
    let weeklyPrice: String
    let badge: String?
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(price)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if let badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(8)
                    }

                    Text(weeklyPrice)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(16)
                .padding(.top, isBestValue ? 10 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.purple.opacity(0.1) : Color(white: 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? Color.purple.opacity(0.8) : Color(white: 0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )

                if isBestValue {
                    Text("Best Value")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple)
                        .cornerRadius(6)
                        .padding(.top, -10)
                        .padding(.trailing, 12)
                }
            }
        }
    }
}
