import SwiftUI
import CoreHaptics

struct CategoryDetailView: View {
    let category: TextureType

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var selectedVariantIndex = 0
    @State private var overlayOpacity: Double = 0

    private let audio = AudioEngine.shared

    private var variants: [TextureVariant] {
        TextureType.variantsForCategory(category)
    }

    private var selectedVariant: TextureVariant {
        variants[selectedVariantIndex]
    }

    var body: some View {
        ZStack {
            // Full screen texture layer
            TexturePreviewLayer(variant: selectedVariant)
                .ignoresSafeArea()

            // Top bar
            VStack {
                topBar
                    .opacity(overlayOpacity)
                Spacer()
            }

            // Right side toolbar
            HStack {
                Spacer()
                rightToolbar
                    .opacity(overlayOpacity)
                    .padding(.trailing, 16)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, UIScreen.main.bounds.height * 0.25)

            // Bottom variant selector
            VStack {
                Spacer()
                bottomSelector
                    .opacity(overlayOpacity)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            audio.startBGM(for: category)
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                overlayOpacity = 1.0
            }
        }
        .onDisappear {
            audio.stopBGM()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            glassButton(icon: "chevron.left") {
                audio.stopBGM()
                dismiss()
            }

            Spacer()

            Text(l10n.string(category.displayNameKey))
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()

            glassButton(icon: "gearshape") {}
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 12)
    }

    // MARK: - Right Toolbar

    private var rightToolbar: some View {
        VStack(spacing: 12) {
            glassButton(icon: "heart") {}
            glassButton(icon: "headphones") {}
            glassButton(icon: "arrow.clockwise") {}
        }
    }

    // MARK: - Bottom Selector

    private var bottomSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(variants.enumerated()), id: \.element.id) { index, variant in
                    VariantCircleButton(
                        variant: variant,
                        isSelected: index == selectedVariantIndex,
                        label: l10n.string(variant.nameKey)
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedVariantIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func glassButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TexturePreviewLayer

private struct TexturePreviewLayer: View {
    let variant: TextureVariant

    @State private var touchLocation: CGPoint?
    @State private var previousTouchLocation: CGPoint?
    @State private var isTouching = false

    private let audio = AudioEngine.shared

    var body: some View {
        FluidMetalView(
            touchLocation: $touchLocation,
            previousTouchLocation: $previousTouchLocation,
            isTouching: $isTouching,
            textureType: variant.baseType
        )
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let wasNotTouching = !isTouching
                    previousTouchLocation = touchLocation
                    touchLocation = value.location
                    isTouching = true
                    if wasNotTouching {
                        audio.playTouchStart()
                    }
                }
                .onEnded { _ in
                    isTouching = false
                    previousTouchLocation = nil
                    touchLocation = nil
                    audio.playTouchRelease()
                }
        )
    }
}

// MARK: - VariantCircleButton

private struct VariantCircleButton: View {
    let variant: TextureVariant
    let isSelected: Bool
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: variant.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )

                if isSelected {
                    Text(label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white))
                } else {
                    Text(label)
                        .font(.caption)
                        .fontWeight(.light)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
