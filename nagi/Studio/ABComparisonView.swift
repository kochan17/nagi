#if DEBUG
import SwiftUI

struct ABComparisonView: View {
    @ObservedObject var store: ScenePresetStore

    var body: some View {
        List {
            slotControlSection
            parametersSection
        }
        .navigationTitle("A/B Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Slot control

    private var slotControlSection: some View {
        Section {
            Picker("Active Slot", selection: slotBinding) {
                Text("Current").tag(ScenePresetStore.Slot.current)
                Text("A").tag(ScenePresetStore.Slot.a)
                Text("B").tag(ScenePresetStore.Slot.b)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            HStack(spacing: 12) {
                Button("Current → A") { store.snapshotA() }
                    .buttonStyle(ABActionStyle(tint: .blue))
                Button("Current → B") { store.snapshotB() }
                    .buttonStyle(ABActionStyle(tint: .purple))
            }

            HStack(spacing: 12) {
                Button("Apply A") { store.applyA() }
                    .buttonStyle(ABActionStyle(tint: .blue))
                Button("Apply B") { store.applyB() }
                    .buttonStyle(ABActionStyle(tint: .purple))
            }
        } header: {
            Text("Slots")
        }
    }

    // MARK: - Parameters comparison table

    private var parametersSection: some View {
        Section {
            paramRow(label: "Fire Height",       keyPath: \ScenePresetStore.Snapshot.fireHeight,       format: "%.2f")
            paramRow(label: "Flicker (Hz)",      keyPath: \ScenePresetStore.Snapshot.flickerFrequency, format: "%.1f")
            paramRow(label: "Temp Base (K)",     keyPath: \ScenePresetStore.Snapshot.colorTempBase,    format: "%.0f")
            paramRow(label: "Temp Tip (K)",      keyPath: \ScenePresetStore.Snapshot.colorTempTip,     format: "%.0f")
            paramRow(label: "Sparks",            keyPath: \ScenePresetStore.Snapshot.sparksIntensity,  format: "%.2f")
            paramRow(label: "Smoke",             keyPath: \ScenePresetStore.Snapshot.smokeOpacity,     format: "%.2f")
            paramRow(label: "Haptic",            keyPath: \ScenePresetStore.Snapshot.hapticIntensity,  format: "%.2f")
            paramRow(label: "Volume",            keyPath: \ScenePresetStore.Snapshot.audioVolume,      format: "%.2f")
        } header: {
            HStack {
                Text("Parameter").frame(maxWidth: .infinity, alignment: .leading)
                Text("A").frame(width: 60, alignment: .trailing)
                Text("B").frame(width: 60, alignment: .trailing)
            }
            .font(.caption)
        }
    }

    private func paramRow(
        label: String,
        keyPath: KeyPath<ScenePresetStore.Snapshot, Double>,
        format: String
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            snapshotValue(keyPath: keyPath, snapshot: store.slotA, format: format, color: .blue)
                .frame(width: 60, alignment: .trailing)

            snapshotValue(keyPath: keyPath, snapshot: store.slotB, format: format, color: .purple)
                .frame(width: 60, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func snapshotValue(
        keyPath: KeyPath<ScenePresetStore.Snapshot, Double>,
        snapshot: ScenePresetStore.Snapshot?,
        format: String,
        color: Color
    ) -> some View {
        if let snap = snapshot {
            Text(String(format: format, snap[keyPath: keyPath]))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(color)
        } else {
            Text("--")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Slot Picker binding

    private var slotBinding: Binding<ScenePresetStore.Slot> {
        Binding(
            get: { store.activeSlot },
            set: { newSlot in
                switch newSlot {
                case .current: break
                case .a: store.applyA()
                case .b: store.applyB()
                }
            }
        )
    }
}

// MARK: - Button style

private struct ABActionStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(tint.opacity(configuration.isPressed ? 0.4 : 0.2))
            .foregroundStyle(tint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        ABComparisonView(store: ScenePresetStore())
    }
    .preferredColorScheme(.dark)
}
#endif
