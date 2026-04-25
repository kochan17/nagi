import SwiftUI
import os.log

// MARK: - Touch state (shared reference between onTouch and VisualBody)

final class BonfireTouchState: ObservableObject {
    @Published var touchLocation: CGPoint? = nil
    @Published var previousTouchLocation: CGPoint? = nil
    @Published var isTouching: Bool = false
}

// MARK: - Scene

struct BonfireScene: SensoryScene {
    let id = "bonfire"
    let title = "Bonfire"

    // Shared reference: onTouch writes here, BonfireVisual observes via @ObservedObject.
    // Created once per BonfireScene value; struct copy semantics preserve the reference.
    private let touchState = BonfireTouchState()

    private let logger = Logger(subsystem: "app.nagi", category: "BonfireScene")

    @ViewBuilder
    func makeVisual(context: SensoryContext) -> some View {
        BonfireVisual(touchState: touchState)
    }

    func prepare(context: SensoryContext) async {
        // Register haptic patterns
        do {
            let smallCrackle = try HapticEngine.makeCampfireSmallCracklePattern()
            context.haptics.register(name: "small_crackle", pattern: smallCrackle)
        } catch {
            logger.warning("small_crackle pattern failed: \(error.localizedDescription, privacy: .public)")
        }

        do {
            let bigPop = try HapticEngine.makeCampfireBigPopPattern()
            context.haptics.register(name: "big_pop", pattern: bigPop)
        } catch {
            logger.warning("big_pop pattern failed: \(error.localizedDescription, privacy: .public)")
        }

        do {
            let rustle = try HapticEngine.makeCampfireSustainedRustlePattern()
            context.haptics.register(name: "sustained_rustle", pattern: rustle)
        } catch {
            logger.warning("sustained_rustle pattern failed: \(error.localizedDescription, privacy: .public)")
        }

        // Register audio asset
        guard let url = Bundle.main.url(forResource: "campfire_ambient", withExtension: "wav")
                ?? Bundle.main.url(forResource: "campfire_ambient", withExtension: "aiff") else {
            logger.warning("campfire_ambient not found in bundle — skipping audio registration")
            return
        }
        context.audio.registerSoundAsset(identifier: "campfire_ambient", url: url)
    }

    func onTouch(_ event: TouchEvent, context: SensoryContext) {
        switch event {
        case .began(let position):
            let eventID = context.clock.beginEvent(label: "bonfire.tap")
            touchState.previousTouchLocation = nil
            touchState.touchLocation = position
            touchState.isTouching = true
            context.haptics.play(name: "small_crackle")
            context.clock.completeEvent(id: eventID, actuator: "haptic")

        case .moved(let from, let to, _):
            touchState.previousTouchLocation = from
            touchState.touchLocation = to
            touchState.isTouching = true

        case .ended(let position):
            touchState.isTouching = false
            touchState.touchLocation = position
            context.haptics.play(name: "sustained_rustle")

        case .longPress(let position):
            // TODO: longPress detection — TouchReactor only emits began/moved/ended
            // via DragGesture. A LongPressGesture overlay in SceneStage or a
            // hold-duration timer in TouchReactor is required to generate this event.
            touchState.touchLocation = position
            context.haptics.play(name: "big_pop")
        }
    }

    func teardown(context: SensoryContext) {
        // Engine lifecycle is owned by SceneDirector; nothing to do here.
    }
}

// MARK: - Visual body

private struct BonfireVisual: View {
    @ObservedObject var touchState: BonfireTouchState

    var body: some View {
        FluidMetalView(
            touchLocation: $touchState.touchLocation,
            previousTouchLocation: $touchState.previousTouchLocation,
            isTouching: $touchState.isTouching,
            textureType: .campfire
        )
        .ignoresSafeArea()
    }
}
