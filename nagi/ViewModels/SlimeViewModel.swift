import SwiftUI
import Combine

enum TouchPhase {
    case began
    case moved
    case ended
}

@MainActor
final class SlimeViewModel: ObservableObject {
    @Published var animationPhase: CGFloat = 0

    private let hapticEngine = HapticEngine()
    private var cancellables = Set<AnyCancellable>()
    private var previousTouchLocation: CGPoint?
    private var isTouchActive = false

    init(textureType: TextureType = .fluids) {
        hapticEngine.loadProfile(for: textureType)
    }

    func setTextureType(_ textureType: TextureType) {
        hapticEngine.loadProfile(for: textureType)
    }

    func startAnimation() {
        Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.animationPhase += 0.016
            }
            .store(in: &cancellables)
    }

    func stopAnimation() {
        cancellables.removeAll()
        hapticEngine.stopContinuousHaptic()
    }

    func onTouch(at point: CGPoint, phase: TouchPhase) {
        switch phase {
        case .began:
            isTouchActive = true
            previousTouchLocation = point
            hapticEngine.playSplashHaptic()
            hapticEngine.startContinuousHaptic()

        case .moved:
            if !isTouchActive {
                isTouchActive = true
                hapticEngine.playSplashHaptic()
                hapticEngine.startContinuousHaptic()
            }

            if let prev = previousTouchLocation {
                let dx = Float(point.x - prev.x)
                let dy = Float(point.y - prev.y)
                let velocity = sqrt(dx * dx + dy * dy)
                hapticEngine.updateContinuousHaptic(velocity: velocity, pressure: 1.0)
            }
            previousTouchLocation = point

        case .ended:
            isTouchActive = false
            previousTouchLocation = nil
            hapticEngine.stopContinuousHaptic()
            hapticEngine.playReleaseHaptic()
        }
    }
}
