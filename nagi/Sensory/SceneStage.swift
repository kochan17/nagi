import SwiftUI

/// Composition root for a `SensoryScene`. Hosts the visual body, captures
/// touch, owns all sensory engines, and drives their lifecycle.
struct SceneStage<Scene: SensoryScene>: View {
    let scene: Scene

    @StateObject private var director = SceneDirector()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let context = director.context(size: size)

            ZStack {
                scene.makeVisual(context: context)
                    .ignoresSafeArea()

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(director.touchReactor.drag(in: size))
            }
            .task {
                director.touchReactor.onEvent = { event in
                    scene.onTouch(event, context: context)
                }
                await director.start()
                await scene.prepare(context: context)
            }
            .onDisappear {
                scene.teardown(context: context)
                director.stop()
            }
        }
    }
}

@MainActor
final class SceneDirector: ObservableObject {
    let haptics = HapticEngine()
    let audio = SpatialAudioEngine()
    let clock = SyncClock()
    let budget = RenderBudget()
    let touchReactor = TouchReactor()

    func context(size: CGSize) -> SensoryContext {
        SensoryContext(
            haptics: haptics,
            audio: audio,
            clock: clock,
            budget: budget,
            size: size
        )
    }

    func start() async {
        // HapticEngine prepares itself in init; only audio needs async prepare.
        await audio.prepare()
    }

    func stop() {
        audio.teardown()
    }
}
