import SwiftUI

struct ResultLine: Identifiable {
    let id: String
    let label: String
    let value: String

    init(label: String, value: String) {
        id = label
        self.label = label
        self.value = value
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    var unit: String?
    var lines: [ResultLine] = []
    var note: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var valueSpacing = AppMetrics.tightSpacing

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline, spacing: valueSpacing) {
                    resultValue
                    resultUnit
                }

                VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                    resultValue
                    resultUnit
                }
            }
            .accessibilityElement(children: .combine)

            if !lines.isEmpty {
                Divider()
                    .overlay(AppTheme.hairline)

                VStack(spacing: 8) {
                    ForEach(lines) { line in
                        DetailRow(label: line.label, value: line.value)
                            .contentTransition(reduceMotion ? .identity : .numericText())
                    }
                }
            }

            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMono)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardSurface()
    }

    private var resultValue: some View {
        Text(value)
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .contentTransition(reduceMotion ? .identity : .numericText())
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var resultUnit: some View {
        if let unit {
            Text(unit)
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ScreenScaffold {
        ResultCard(
            title: "Water needed",
            value: "1.4",
            unit: "L",
            lines: [
                ResultLine(label: "Grounds", value: "180 g"),
                ResultLine(label: "Ratio", value: "1:8")
            ],
            note: "Assumes coarse grind and a 14 hour steep."
        )
    }
}
