import SwiftUI

struct DialScrub: View {
    @Binding var fraction: Double
    var caption: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var percentage: Int {
        Int(clampedFraction * 100)
    }

    private var clampedFraction: Double {
        min(1, max(0, fraction))
    }

    var body: some View {
        VStack(spacing: AppMetrics.contentSpacing) {
            ViewThatFits {
                dial(size: 220)
                dial(size: 164)
            }

            Text(percentage == 0 ? "Ready to set" : "\(percentage)% selected")
                .font(.caption.weight(.semibold))
                .foregroundStyle(percentage == 0 ? AppTheme.textSecondary : AppTheme.accent)
                .accessibilityLabel(percentage == 0 ? "Dial empty. Ready to set" : "\(percentage) percent selected")
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: percentage)
        .animation(reduceMotion ? nil : .snappy, value: percentage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue("\(percentage) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                fraction = min(1, clampedFraction + 0.05)
            case .decrement:
                fraction = max(0, clampedFraction - 0.05)
            @unknown default:
                break
            }
        }
        .accessibilityAction(named: "Reset") {
            fraction = 0
        }
    }

    private func dial(size: CGFloat) -> some View {
        ZStack {
            Circle().stroke(AppTheme.hairline, lineWidth: 8)
            Circle()
                .trim(from: 0, to: clampedFraction)
                .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: AppMetrics.tightSpacing) {
                Text(caption)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(percentage)%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let center = size / 2
                    let vector = CGVector(dx: value.location.x - center, dy: value.location.y - center)
                    var angle = atan2(vector.dy, vector.dx) + .pi / 2
                    if angle < 0 { angle += 2 * .pi }
                    fraction = min(1, max(0, angle / (2 * .pi)))
                }
        )
    }
}

struct WaveBand: View {
    var samples: [Double]
    var isSelected = false
    var onCommit: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedbackPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            if samples.count < 2 {
                ViewThatFits {
                    ContentUnavailableView(
                        "No wave yet",
                        systemImage: "waveform.path",
                        description: Text("Add at least two samples.")
                    )

                    Label("No wave yet", systemImage: "waveform.path")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("Wave is empty")
            } else {
                wave(height: 160)

                Text(isSelected ? "Wave selected" : "Ready. Select the wave")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
            }
        }
        .accessibilityLabel("Wave, \(samples.count) samples")
        .accessibilityValue(isSelected ? "Selected" : "Ready")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { commit() }
        .accessibilityAction(named: "Select wave") { commit() }
        .sensoryFeedback(.selection, trigger: feedbackPulse)
        .animation(reduceMotion ? nil : .snappy, value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture(perform: commit)
    }

    private func wave(height: CGFloat) -> some View {
        Canvas { context, size in
            var path = Path()
            for (index, sample) in samples.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(samples.count - 1)
                let y = size.height * (1 - CGFloat(min(1, max(0, sample))))
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(
                path,
                with: .color(isSelected ? AppTheme.accent : AppTheme.textPrimary),
                lineWidth: isSelected ? 3 : 2
            )
        }
        .frame(height: height)
    }

    private func commit() {
        feedbackPulse.toggle()
        onCommit?()
    }
}

struct Sunburst: View {
    var shares: [Double]
    var labels: [String]
    var isSelected = false
    var onCommit: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedbackPulse = false

    var body: some View {
        let total = max(shares.reduce(0, +), 0.001)
        VStack(spacing: AppMetrics.tightSpacing) {
            if shares.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "No segments",
                        systemImage: "chart.pie",
                        description: Text("Add values to build the face.")
                    )

                    Label("No segments", systemImage: "chart.pie")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("Sunburst is empty")
            } else {
                ViewThatFits {
                    burst(total: total, size: 180)
                    burst(total: total, size: 136)
                }

                Text(isSelected ? "Segments selected" : "Ready. Select the segments")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
            }
        }
        .accessibilityLabel(labels.joined(separator: ", "))
        .accessibilityValue(isSelected ? "Selected" : "Ready")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { commit() }
        .accessibilityAction(named: "Select segments") { commit() }
        .sensoryFeedback(.selection, trigger: feedbackPulse)
        .animation(reduceMotion ? nil : .snappy, value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture(perform: commit)
    }

    private func burst(total: Double, size: CGFloat) -> some View {
        ZStack {
            ForEach(Array(shares.enumerated()), id: \.offset) { index, share in
                let start = shares.prefix(index).reduce(0, +) / total
                let end = start + share / total
                Circle()
                    .trim(from: start, to: end)
                    .stroke(
                        index.isMultiple(of: 2) ? AppTheme.accent : AppTheme.textPrimary,
                        style: StrokeStyle(lineWidth: isSelected ? 32 : 28, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size, height: size)
    }

    private func commit() {
        feedbackPulse.toggle()
        onCommit?()
    }
}

#Preview {
    DialPreview()
}

private struct DialPreview: View {
    @State private var fraction = 0.35

    var body: some View {
        ScreenScaffold {
            DialScrub(fraction: $fraction, caption: "Dusk")
            WaveBand(
                samples: [0.2, 0.6, 0.4, 0.9, 0.3, 0.7, 0.5, 0.8],
                onCommit: {}
            )
            Sunburst(
                shares: [2, 1, 3, 1, 2, 1],
                labels: ["Clay", "Trim", "Dry", "Bisque", "Glaze", "Fire"],
                onCommit: {}
            )
        }
    }
}
