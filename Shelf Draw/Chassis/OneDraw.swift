import SwiftUI

/// One result in the middle. Other modes stay off this face.
struct OneDraw: View {
    var label: String
    var options: [String]
    @Binding var selection: Int?
    var onCommit: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var value: String? {
        guard let selection, options.indices.contains(selection) else { return nil }
        return options[selection]
    }

    var body: some View {
        VStack(spacing: AppMetrics.contentSpacing) {
            if options.isEmpty {
                ContentUnavailableView(
                    "Empty draw",
                    systemImage: "circle.dashed",
                    description: Text("Add at least one option to draw.")
                )
            } else {
                Button(action: commitDraw) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppTheme.accent.opacity(value == nil ? 0.10 : 0.22), AppTheme.bgElevated.opacity(0.4)],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 110
                                )
                            )
                        Circle()
                            .stroke(AppTheme.accent, lineWidth: 3)
                            .shadow(color: AppTheme.accent.opacity(0.45), radius: 14)
                        Circle()
                            .inset(by: 14)
                            .stroke(AppTheme.accent.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [2, 5]))
                        VStack(spacing: 4) {
                            ViewThatFits {
                                Text(value ?? "DRAW")
                                    .font(.largeTitle.weight(.heavy))
                                Text(value ?? "DRAW")
                                    .font(.title2.weight(.bold))
                                Text(value ?? "DRAW")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(value == nil ? AppTheme.accent : AppTheme.textPrimary)
                            .minimumScaleFactor(0.5)
                            Text(value == nil ? "tap to draw" : "tap to redraw")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(AppMetrics.cardPadding)
                        // The shuffle swaps the name ~9 times; cross-fading each swap reads as flicker.
                        .transaction { $0.animation = nil }
                    }
                    .frame(width: 200, height: 200)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(value.map { "Drawn option: \($0)" } ?? "Ready to draw from \(options.count) options")
                .accessibilityAction(named: value == nil ? "Draw" : "Redraw", commitDraw)
            }
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .transaction { $0.animation = nil }
        }
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? nil : .snappy, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func commitDraw() {
        let next = selection.map { ($0 + 1) % options.count } ?? 0
        selection = next
        onCommit(options[next])
    }
}

#Preview {
    ScreenScaffold {
        OneDraw(
            label: "Tonight's draw",
            options: ["Nia", "Mateo", "Avery", "Sora", "Imani", "Luca"],
            selection: .constant(2),
            onCommit: { _ in }
        )
    }
}
