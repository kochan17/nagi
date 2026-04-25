import SwiftUI

struct NagiButton: View {
    let title: String
    var isEnabled: Bool = true
    var style: ButtonStyle = .accent
    let action: () -> Void

    enum ButtonStyle {
        case accent
        case white
        case gradient
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(labelColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(backgroundView)
                .clipShape(Capsule())
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .accent:
            Capsule()
                .fill(isEnabled ? Color.cyan : Color(white: 0.2))
        case .white:
            Capsule()
                .fill(isEnabled ? Color.white : Color(white: 0.4))
        case .gradient:
            Capsule()
                .fill(
                    LinearGradient(
                        colors: isEnabled
                            ? [Color.purple, Color.pink]
                            : [Color(white: 0.2), Color(white: 0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    private var labelColor: Color {
        guard isEnabled else { return .gray }
        switch style {
        case .accent: return .black
        case .white: return .black
        case .gradient: return .white
        }
    }
}
