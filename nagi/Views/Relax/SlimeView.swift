import SwiftUI
import CoreHaptics

struct SlimeView: View {
    let textureType: TextureType

    @StateObject private var viewModel: SlimeViewModel

    init(textureType: TextureType = .fluids) {
        self.textureType = textureType
        _viewModel = StateObject(wrappedValue: SlimeViewModel(textureType: textureType))
    }

    @State private var touchLocation: CGPoint?
    @State private var previousTouchLocation: CGPoint?
    @State private var isTouching = false
    @State private var metalViewOpacity: Double = 0
    @State private var isMetalReady = false
    @State private var glowPulse = false

    private let audio = AudioEngine.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Pulsing loading glow shown while Metal pipeline initializes
            if !isMetalReady {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.5), .cyan.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(glowPulse ? 1.15 : 0.9)
                    .opacity(glowPulse ? 0.9 : 0.4)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: glowPulse)
            }

            FluidMetalView(
                touchLocation: $touchLocation,
                previousTouchLocation: $previousTouchLocation,
                isTouching: $isTouching,
                textureType: textureType
            )
            .ignoresSafeArea()
            .opacity(metalViewOpacity)
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
                        viewModel.onTouch(at: value.location, phase: .moved)
                    }
                    .onEnded { _ in
                        isTouching = false
                        previousTouchLocation = nil
                        touchLocation = nil
                        audio.playTouchRelease()
                        viewModel.onTouch(at: .zero, phase: .ended)
                    }
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            glowPulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    metalViewOpacity = 1.0
                    isMetalReady = true
                }
            }
        }
    }
}
