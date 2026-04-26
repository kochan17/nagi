import SwiftUI

struct RelaxView: View {
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var visibleBanners: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerView
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 24)

                        LazyVStack(spacing: 16) {
                            ForEach(Array(TextureType.allCases.enumerated()), id: \.element.id) { index, category in
                                let variants = TextureType.variantsForCategory(category)
                                NavigationLink {
                                    destinationView(for: category)
                                } label: {
                                    CategoryBannerCard(
                                        category: category,
                                        variantCount: variants.count,
                                        l10n: l10n
                                    )
                                }
                                .opacity(visibleBanners.contains(category.id) ? 1 : 0)
                                .offset(y: visibleBanners.contains(category.id) ? 0 : 30)
                                .animation(
                                    .easeOut(duration: 0.45).delay(Double(index) * 0.07),
                                    value: visibleBanners.contains(category.id)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                for (index, category) in TextureType.allCases.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.07) {
                        visibleBanners.insert(category.id)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for category: TextureType) -> some View {
        switch category {
        case .campfire:
            SceneStage(scene: BonfireScene())
        case .forest:
            SceneStage(scene: ForestScene())
        default:
            CategoryDetailView(category: category)
        }
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Relax")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(l10n.string(.relaxHeaderSubtitle))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Text(l10n.string(.premium))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                )
        }
    }
}

private struct CategoryBannerCard: View {
    let category: TextureType
    let variantCount: Int
    let l10n: LocalizationManager

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Base linear gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: category.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 180)

            // Radial glow overlay in top-right corner for depth
            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.15), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 120
                ))
                .frame(width: 200, height: 200)
                .offset(x: 60, y: -40)
                .allowsHitTesting(false)

            // Bottom gradient for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.3)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Animated shimmer stripe
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.12),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80)
                .offset(x: shimmerOffset)
                .allowsHitTesting(false)

            // Decorative icon: base layer + offset copy for parallax depth
            ZStack {
                Image(systemName: category.iconName)
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.08))
                    .offset(x: 4, y: 4)

                Image(systemName: category.iconName)
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.15))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
            .allowsHitTesting(false)

            // Bottom-left title with variant badge
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(l10n.string(category.displayNameKey))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if variantCount > 1 {
                    Text("\(variantCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(
                .linear(duration: 2.2)
                .repeatForever(autoreverses: false)
                .delay(Double.random(in: 0...1.5))
            ) {
                shimmerOffset = 400
            }
        }
    }
}
