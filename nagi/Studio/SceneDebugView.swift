#if DEBUG
import SwiftUI

struct SceneDebugView: View {
    @ObservedObject var store: ScenePresetStore

    var body: some View {
        List {
            Section("Visual") {
                sliderRow(
                    label: "Fire Height",
                    value: $store.fireHeight,
                    range: 0.3...1.0,
                    step: 0.01
                )
                sliderRow(
                    label: "Flicker (Hz)",
                    value: $store.flickerFrequency,
                    range: 4...15,
                    step: 0.5
                )
                sliderRow(
                    label: "Color Temp Base (K)",
                    value: $store.colorTempBase,
                    range: 1500...3500,
                    step: 50
                )
                sliderRow(
                    label: "Color Temp Tip (K)",
                    value: $store.colorTempTip,
                    range: 1000...2500,
                    step: 50
                )
                sliderRow(
                    label: "Sparks Intensity",
                    value: $store.sparksIntensity,
                    range: 0...2.0,
                    step: 0.05
                )
                sliderRow(
                    label: "Smoke Opacity",
                    value: $store.smokeOpacity,
                    range: 0...1.0,
                    step: 0.01
                )
            }

            Section("Haptic") {
                sliderRow(
                    label: "Haptic Intensity",
                    value: $store.hapticIntensity,
                    range: 0...1.0,
                    step: 0.01
                )
            }

            Section("Audio") {
                sliderRow(
                    label: "Audio Volume",
                    value: $store.audioVolume,
                    range: 0...1.0,
                    step: 0.01
                )
            }
        }
        .navigationTitle("Scene Debug")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    store.reset()
                }
            }
        }
    }

    private func sliderRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        SceneDebugView(store: ScenePresetStore())
    }
    .preferredColorScheme(.dark)
}
#endif
