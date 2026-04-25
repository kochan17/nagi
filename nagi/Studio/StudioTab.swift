#if DEBUG
import SwiftUI

// MARK: - StudioTab
//
// Usage — add to MainTabView.swift inside the TabView block:
//
//   #if DEBUG
//   StudioTab(renderBudget: renderBudget)
//       .tabItem { Image(systemName: "slider.horizontal.3"); Text("Studio") }
//       .tag(99)
//   #endif
//
// Make sure MainTabView holds a @StateObject var renderBudget = RenderBudget()
// and passes it through as needed.

struct StudioTab: View {
    @StateObject private var presetStore = ScenePresetStore()
    @State private var hudVisible = false

    var renderBudget: RenderBudget

    var body: some View {
        NavigationStack {
            List {
                Section("Campfire Tuning") {
                    NavigationLink("Scene Debug") {
                        SceneDebugView(store: presetStore)
                    }
                    NavigationLink("A/B Comparison") {
                        ABComparisonView(store: presetStore)
                    }
                }

                Section("Performance") {
                    Toggle("Show Performance HUD", isOn: $hudVisible)
                    if hudVisible {
                        hudInfoRow
                    }
                }

                Section("Render Budget") {
                    renderBudgetRows
                }
            }
            .navigationTitle("Studio")
            .navigationBarTitleDisplayMode(.large)
        }
        .overlay(alignment: .topTrailing) {
            if hudVisible {
                PerformanceHUD(renderBudget: renderBudget)
            }
        }
    }

    // MARK: - Sub-views

    private var hudInfoRow: some View {
        Label(
            "HUD is visible on top of this screen. Drag the tab to reposition.",
            systemImage: "info.circle"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var renderBudgetRows: some View {
        LabeledContent("Tier", value: renderBudget.tier.rawValue)
        LabeledContent("Target FPS", value: "\(renderBudget.targetFPS)")
        LabeledContent("Render Scale", value: String(format: "%.2f", renderBudget.renderScale))
        LabeledContent("Max Octaves", value: "\(renderBudget.maxShaderOctaves)")
        LabeledContent("Thermal", value: renderBudget.thermalState.debugLabel)
            .foregroundStyle(renderBudget.thermalState.debugColor)
    }
}

// MARK: - ThermalState debug helpers (Studio-local)

private extension ProcessInfo.ThermalState {
    var debugLabel: String {
        switch self {
        case .nominal:  return "nominal"
        case .fair:     return "fair"
        case .serious:  return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    var debugColor: Color {
        switch self {
        case .nominal:  return .green
        case .fair:     return .yellow
        case .serious:  return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    StudioTab(renderBudget: RenderBudget())
        .preferredColorScheme(.dark)
}
#endif
