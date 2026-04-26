import SwiftUI
import os.log

// MARK: - Touch state (shared reference between onTouch and VisualBody)

final class ForestTouchState: ObservableObject {
    @Published var touchLocation: CGPoint? = nil
    @Published var previousTouchLocation: CGPoint? = nil
    @Published var isTouching: Bool = false
}

// MARK: - Scene

struct ForestScene: SensoryScene {
    let id = "forest"
    let title = "Forest"

    private let touchState = ForestTouchState()
    private let logger = Logger(subsystem: "app.nagi", category: "ForestScene")

    @ViewBuilder
    func makeVisual(context: SensoryContext) -> some View {
        ForestVisual(touchState: touchState)
    }

    func prepare(context: SensoryContext) async {
        // Register haptic patterns
        do {
            let leafStep = try HapticEngine.makeForestLeafStepPattern()
            context.haptics.register(name: "leaf_step", pattern: leafStep)
        } catch {
            logger.warning("leaf_step pattern failed: \(error.localizedDescription, privacy: .public)")
        }

        do {
            let rustleGust = try HapticEngine.makeForestRustleGustPattern()
            context.haptics.register(name: "rustle_gust", pattern: rustleGust)
        } catch {
            logger.warning("rustle_gust pattern failed: \(error.localizedDescription, privacy: .public)")
        }

        do {
            let deepGroan = try HapticEngine.makeForestDeepGroanPattern()
            context.haptics.register(name: "deep_groan", pattern: deepGroan)
        } catch {
            logger.warning("deep_groan pattern failed: \(error.localizedDescription, privacy: .public)")
        }

        // Register audio asset
        guard let url = Bundle.main.url(forResource: "forest_ambient", withExtension: "wav")
                ?? Bundle.main.url(forResource: "forest_ambient", withExtension: "aiff") else {
            logger.warning("forest_ambient not found in bundle — skipping audio registration")
            return
        }
        context.audio.registerSoundAsset(identifier: "forest_ambient", url: url)
    }

    func onTouch(_ event: TouchEvent, context: SensoryContext) {
        switch event {
        case .began(let position):
            let eventID = context.clock.beginEvent(label: "forest.tap")
            touchState.previousTouchLocation = nil
            touchState.touchLocation = position
            touchState.isTouching = true
            context.haptics.play(name: "leaf_step")
            context.clock.completeEvent(id: eventID, actuator: "haptic")

        case .moved(let from, let to, _):
            touchState.previousTouchLocation = from
            touchState.touchLocation = to
            touchState.isTouching = true

        case .ended(let position):
            touchState.isTouching = false
            touchState.touchLocation = position
            context.haptics.play(name: "rustle_gust")

        case .longPress(let position):
            touchState.touchLocation = position
            context.haptics.play(name: "deep_groan")
        }
    }

    func teardown(context: SensoryContext) {
        // Engine lifecycle is owned by SceneDirector; nothing to do here.
    }
}

// MARK: - Visual body

private struct ForestVisual: View {
    @ObservedObject var touchState: ForestTouchState

    var body: some View {
        FluidMetalView(
            touchLocation: $touchState.touchLocation,
            previousTouchLocation: $touchState.previousTouchLocation,
            isTouching: $touchState.isTouching,
            textureType: .forest
        )
        .ignoresSafeArea()
    }
}
