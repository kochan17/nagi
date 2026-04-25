import SwiftUI

/// Converts SwiftUI drag gestures into normalized `TouchEvent` stream.
/// Attach via `.gesture(reactor.drag(in: size))` inside `SceneStage`.
final class TouchReactor {
    var onEvent: (TouchEvent) -> Void = { _ in }

    private var lastPosition: CGPoint?
    private var lastTimestamp: TimeInterval?

    func drag(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { [weak self] g in
                guard let self else { return }
                let now = Date().timeIntervalSinceReferenceDate
                let velocity: CGVector = {
                    if let prev = self.lastPosition, let prevT = self.lastTimestamp, now > prevT {
                        let dt = now - prevT
                        return CGVector(
                            dx: (g.location.x - prev.x) / dt,
                            dy: (g.location.y - prev.y) / dt
                        )
                    }
                    return .zero
                }()
                if self.lastPosition == nil {
                    self.onEvent(.began(position: g.location))
                } else if let prev = self.lastPosition {
                    self.onEvent(.moved(from: prev, to: g.location, velocity: velocity))
                }
                self.lastPosition = g.location
                self.lastTimestamp = now
            }
            .onEnded { [weak self] g in
                guard let self else { return }
                self.onEvent(.ended(position: g.location))
                self.lastPosition = nil
                self.lastTimestamp = nil
            }
    }
}
