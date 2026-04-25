#if DEBUG
import SwiftUI
import QuartzCore
import Darwin

// MARK: - FPS + Memory observable

@MainActor
final class HUDMonitor: ObservableObject {
    @Published private(set) var fps: Double = 0
    @Published private(set) var memoryMB: Double = 0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var accumulator: CFTimeInterval = 0
    private let updateInterval: CFTimeInterval = 0.5

    init() {
        startDisplayLink()
    }

    deinit {
        displayLink?.invalidate()
    }

    private func startDisplayLink() {
        let link = CADisplayLink(target: DisplayLinkProxy(monitor: self), selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func tick(timestamp: CFTimeInterval) {
        guard lastTimestamp > 0 else {
            lastTimestamp = timestamp
            return
        }
        let delta = timestamp - lastTimestamp
        lastTimestamp = timestamp
        frameCount += 1
        accumulator += delta

        if accumulator >= updateInterval {
            fps = Double(frameCount) / accumulator
            frameCount = 0
            accumulator = 0
            memoryMB = Self.residentMemoryMB()
        }
    }

    private static func residentMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1_048_576
    }
}

// CADisplayLink target must be NSObject; use a proxy to avoid retain cycles
private final class DisplayLinkProxy: NSObject {
    weak var monitor: HUDMonitor?

    init(monitor: HUDMonitor) {
        self.monitor = monitor
    }

    @objc func tick(_ link: CADisplayLink) {
        Task { @MainActor [weak self] in
            self?.monitor?.tick(timestamp: link.timestamp)
        }
    }
}

// MARK: - Thermal state helpers

private extension ProcessInfo.ThermalState {
    var label: String {
        switch self {
        case .nominal:  return "nominal"
        case .fair:     return "fair"
        case .serious:  return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    var color: Color {
        switch self {
        case .nominal:  return .green
        case .fair:     return .yellow
        case .serious:  return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
}

// MARK: - PerformanceHUD

struct PerformanceHUD: View {
    @StateObject private var monitor = HUDMonitor()
    @ObservedObject var renderBudget: RenderBudget

    @State private var isExpanded = false
    @State private var position: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    static func make(renderBudget: RenderBudget) -> PerformanceHUD {
        PerformanceHUD(renderBudget: renderBudget)
    }

    var body: some View {
        hudContent
            .offset(
                x: position.width + dragOffset.width,
                y: position.height + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        position.width += value.translation.width
                        position.height += value.translation.height
                    }
            )
            .padding(12)
    }

    @ViewBuilder
    private var hudContent: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Toggle tab
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Text(isExpanded ? "HUD ▲" : "HUD ▼")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 3) {
                    row(label: "FPS", value: String(format: "%.1f", monitor.fps))
                    row(label: "Thermal", value: renderBudget.thermalState.label, valueColor: renderBudget.thermalState.color)
                    row(label: "Tier", value: renderBudget.tier.rawValue)
                    row(label: "Mem", value: String(format: "%.1f MB", monitor.memoryMB))
                    row(label: "GPU", value: "n/a")
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
            }
        }
    }

    private func row(label: String, value: String, valueColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .frame(minWidth: 140)
    }
}

// MARK: - View modifier convenience

struct PerformanceHUDModifier: ViewModifier {
    let renderBudget: RenderBudget

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            PerformanceHUD(renderBudget: renderBudget)
        }
    }
}

extension View {
    func performanceHUD(renderBudget: RenderBudget) -> some View {
        modifier(PerformanceHUDModifier(renderBudget: renderBudget))
    }
}
#endif
