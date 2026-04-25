import Foundation
import os.log

/// Measures end-to-end latency from a touch "intention" to each actuator firing
/// (visual / haptic / audio). The product contract is ≤ 30ms for the three;
/// 20ms+ logs a warning, 30ms+ marks the event as out-of-spec.
final class SyncClock {
    static let warnLatencyMs: Double = 20
    static let targetLatencyMs: Double = 30

    private let logger = Logger(subsystem: "app.nagi", category: "SyncClock")
    private let queue = DispatchQueue(label: "app.nagi.SyncClock", attributes: .concurrent)
    private var pending: [UUID: PendingEvent] = [:]

    private struct PendingEvent {
        let label: String
        let originHostTime: UInt64
        var actuatorLatencies: [String: Double] = [:]
    }

    /// Begin tracking a sensory event. Returns an ID to pass to `completeEvent`.
    func beginEvent(label: String) -> UUID {
        let id = UUID()
        let origin = mach_absolute_time()
        queue.async(flags: .barrier) {
            self.pending[id] = PendingEvent(label: label, originHostTime: origin)
        }
        return id
    }

    /// Record an actuator completion. Returns measured latency in ms.
    @discardableResult
    func completeEvent(id: UUID, actuator: String) -> Double {
        let now = mach_absolute_time()
        var latencyMs: Double = 0
        queue.sync(flags: .barrier) {
            guard var evt = pending[id] else { return }
            let nanos = Self.machToNanos(now - evt.originHostTime)
            latencyMs = Double(nanos) / 1_000_000.0
            evt.actuatorLatencies[actuator] = latencyMs
            pending[id] = evt
            if latencyMs > Self.targetLatencyMs {
                logger.error("[\(evt.label, privacy: .public)] \(actuator, privacy: .public) OUT-OF-SPEC \(latencyMs, privacy: .public)ms")
            } else if latencyMs > Self.warnLatencyMs {
                logger.warning("[\(evt.label, privacy: .public)] \(actuator, privacy: .public) \(latencyMs, privacy: .public)ms")
            }
        }
        return latencyMs
    }

    func endEvent(id: UUID) {
        queue.async(flags: .barrier) {
            self.pending.removeValue(forKey: id)
        }
    }

    private static let timebase: mach_timebase_info_data_t = {
        var tb = mach_timebase_info_data_t()
        mach_timebase_info(&tb)
        return tb
    }()

    private static func machToNanos(_ delta: UInt64) -> UInt64 {
        delta &* UInt64(timebase.numer) / UInt64(timebase.denom)
    }
}
