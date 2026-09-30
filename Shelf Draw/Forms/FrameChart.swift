import SwiftUI

struct HeatField: View {
    var columns: Int
    var values: [Double]
    @Binding var selection: Int?
    var onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var minimumCellWidth: CGFloat = 36

    var body: some View {
        let width = max(columns, 1)
        let rows = Int(ceil(Double(values.count) / Double(width)))

        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            if values.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "No readings",
                        systemImage: "chart.dots.scatter",
                        description: Text("Add readings to fill the field.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)

                    Label("No readings", systemImage: "chart.dots.scatter")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
                .accessibilityLabel("No heat readings")
            } else {
                ViewThatFits(in: .horizontal) {
                    heatGrid(
                        rows: rows,
                        columns: width,
                        cellHeight: max(24, minimumCellWidth * 0.7)
                    )
                    heatList
                }

                Text(selection.map { "Selected reading \($0 + 1)" } ?? "Ready. Choose a reading")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selection == nil ? AppTheme.textSecondary : AppTheme.accent)
                    .accessibilityLabel(selection.map { "Selected reading \($0 + 1)" } ?? "Ready to select a reading")
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .animation(reduceMotion ? nil : .snappy, value: selection)
        .accessibilityAction(named: "Select strongest reading") {
            if let index = values.indices.max(by: { values[$0] < values[$1] }) {
                select(index)
            }
        }
    }

    private func heatGrid(rows: Int, columns: Int, cellHeight: CGFloat) -> some View {
        VStack(spacing: AppMetrics.tightSpacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: AppMetrics.tightSpacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        if index < values.count {
                            Button {
                                select(index)
                            } label: {
                                cell(values[index], selected: selection == index)
                                    .frame(
                                        minWidth: minimumCellWidth,
                                        maxWidth: .infinity,
                                        minHeight: cellHeight
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Reading \(index + 1), \(Int(clamped(values[index]) * 100)) percent")
                            .accessibilityAddTraits(selection == index ? .isSelected : [])
                            .accessibilityAction(named: "Select") { select(index) }
                        } else {
                            Color.clear.frame(height: cellHeight)
                        }
                    }
                }
            }
        }
    }

    private var heatList: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                Button {
                    select(index)
                } label: {
                    HStack(spacing: AppMetrics.contentSpacing) {
                        Text("Reading \(index + 1)")
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("\(Int(clamped(value) * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Reading \(index + 1), \(Int(clamped(value) * 100)) percent")
                .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }
    }

    private func cell(_ value: Double, selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(AppTheme.accent.opacity(0.15 + 0.85 * clamped(value)))
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(AppTheme.textPrimary, lineWidth: selected ? 3 : 0)
            }
    }

    private func select(_ index: Int) {
        selection = index
        onSelect(index)
    }

    private func clamped(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

struct SoundBars: View {
    var samples: [Double]
    @Binding var selection: Int?
    var onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var minimumBarWidth: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            if samples.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "No samples",
                        systemImage: "waveform",
                        description: Text("Record samples to shape the bars.")
                    )

                    Label("No samples", systemImage: "waveform")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("No sound samples")
            } else {
                ViewThatFits(in: .horizontal) {
                    barChart
                    sampleList
                }

                Text(selection.map { "Selected sample \($0 + 1)" } ?? "Ready. Choose a sample")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selection == nil ? AppTheme.textSecondary : AppTheme.accent)
                    .accessibilityLabel(selection.map { "Selected sample \($0 + 1)" } ?? "Ready to select a sample")
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .animation(reduceMotion ? nil : .snappy, value: selection)
        .accessibilityLabel("Bar field, \(samples.count) samples")
        .accessibilityAction(named: "Select first sample") {
            if !samples.isEmpty { select(0) }
        }
    }

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: AppMetrics.tightSpacing) {
            ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                Button {
                    select(index)
                } label: {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(selection == index ? AppTheme.accent : AppTheme.textPrimary)
                        .frame(height: max(4, 160 * CGFloat(min(1, max(0, sample)))))
                        .frame(minWidth: minimumBarWidth, maxWidth: .infinity, alignment: .bottom)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sample \(index + 1), \(Int(min(1, max(0, sample)) * 100)) percent")
                .accessibilityAddTraits(selection == index ? .isSelected : [])
                .accessibilityAction(named: "Select") { select(index) }
            }
        }
        .frame(height: 160, alignment: .bottom)
    }

    private var sampleList: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                Button {
                    select(index)
                } label: {
                    Text("Sample \(index + 1) · \(Int(min(1, max(0, sample)) * 100))%")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Sample \(index + 1), \(Int(min(1, max(0, sample)) * 100)) percent")
            }
        }
    }

    private func select(_ index: Int) {
        selection = index
        onSelect(index)
    }
}

#Preview {
    FrameChartPreview()
}

private struct FrameChartPreview: View {
    @State private var heatSelection: Int?
    @State private var barSelection: Int?

    var body: some View {
        ScreenScaffold {
            HeatField(
                columns: 6,
                values: [0.15, 0.42, 0.78, 0.31, 0.64, 0.92, 0.2, 0.55, 0.84, 0.46, 0.7, 1],
                selection: $heatSelection,
                onSelect: { _ in }
            )
            SoundBars(
                samples: [0.2, 0.8, 0.4, 0.9, 0.3, 0.6, 1, 0.5],
                selection: $barSelection,
                onSelect: { _ in }
            )
        }
    }
}
