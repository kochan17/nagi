import SwiftUI

/// A composable nature scene that unifies visual, audio, and haptic layers.
/// Each scene (Bonfire, Waves, Forest, ...) conforms and provides its own
/// Metal-backed SwiftUI View plus reactions to touch events.
protocol SensoryScene: Identifiable {
    var id: String { get }
    var title: String { get }

    associatedtype VisualBody: SwiftUI.View
    @ViewBuilder func makeVisual(context: SensoryContext) -> VisualBody

    /// Called once when the scene becomes active. Load haptic patterns,
    /// register audio assets, prime any GPU resources here.
    func prepare(context: SensoryContext) async

    /// Called when the scene is dismissed.
    func teardown(context: SensoryContext)

    /// Reacts to a single touch event. Implementations typically:
    ///   - mark `context.clock.beginEvent` at the entry,
    ///   - drive `context.haptics.play(...)` and `context.audio.emit(...)`,
    ///   - update visual uniforms (via bound state).
    func onTouch(_ event: TouchEvent, context: SensoryContext)
}

/// Bundle of engines handed to a scene at runtime.
struct SensoryContext {
    let haptics: HapticEngine
    let audio: SpatialAudioEngine
    let clock: SyncClock
    let budget: RenderBudget
    let size: CGSize
}

/// Normalized touch event emitted by `TouchReactor`.
enum TouchEvent {
    case began(position: CGPoint)
    case moved(from: CGPoint, to: CGPoint, velocity: CGVector)
    case ended(position: CGPoint)
    case longPress(position: CGPoint)
}
