import SwiftUI

struct PitchMark: Identifiable, Hashable {
    var id: String
    var row: Int
    var start: Double
    var length: Double
}

struct PitchPlane: View {
    var rows: [String]
    var marks: [PitchMark]
    @Binding var selection: PitchMark?
    var onSelect: (PitchMark) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            if rows.isEmpty || marks.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "Plane is empty",
                        systemImage: "pianokeys",
                        description: Text("Add rows and marks to begin a sequence.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 200)

                    Label("Plane is empty", systemImage: "pianokeys")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                .accessibilityLabel("Pitch plane is empty")
            } else {
                if dynamicTypeSize.isAccessibilitySize {
                    markList
                } else {
                    ViewThatFits(in: .horizontal) {
                        plane(labelWidth: 42)
                            .frame(minWidth: 320)
                        plane(labelWidth: 30)
                    }
                }

                Text(selection == nil ? "Ready. Choose a mark" : "Selected mark \(selection?.id ?? "")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selection == nil ? AppTheme.textSecondary : AppTheme.accent)
                    .accessibilityLabel(selection == nil ? "Ready to select a mark" : "A mark is selected")
            }
        }
        .sensoryFeedback(.selection, trigger: selection?.id)
        .animation(reduceMotion ? nil : .snappy, value: selection?.id)
        .accessibilityAction(named: "Select next mark") {
            guard !marks.isEmpty else { return }
            let current = selection.flatMap { marks.firstIndex(of: $0) } ?? -1
            select(marks[(current + 1) % marks.count])
        }
    }

    private var markList: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            ForEach(marks) { mark in
                let rowName = rows.indices.contains(mark.row) ? rows[mark.row] : "Row \(mark.row + 1)"
                Button {
                    select(mark)
                } label: {
                    HStack(spacing: AppMetrics.contentSpacing) {
                        Text(rowName)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text("\(Int(mark.start * 100))–\(Int((mark.start + mark.length) * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("\(rowName) mark, starts \(Int(mark.start * 100)) percent, length \(Int(mark.length * 100)) percent")
                .accessibilityAddTraits(selection == mark ? .isSelected : [])
            }
        }
    }

    private func plane(labelWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, name in
                HStack(spacing: AppMetrics.tightSpacing) {
                    Text(name)
                        .font(.caption2.monospaced())
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: labelWidth, alignment: .trailing)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(AppTheme.hairline.opacity(0.5))
                            ForEach(marks.filter { $0.row == index }) { mark in
                                Button {
                                    select(mark)
                                } label: {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(selection == mark ? AppTheme.textPrimary : AppTheme.accent)
                                        .frame(
                                            width: max(8, geo.size.width * CGFloat(mark.length)),
                                            height: geo.size.height - 6
                                        )
                                }
                                .buttonStyle(.plain)
                                .offset(x: geo.size.width * CGFloat(mark.start))
                                .accessibilityLabel("\(name) mark, starts \(Int(mark.start * 100)) percent, length \(Int(mark.length * 100)) percent")
                                .accessibilityAddTraits(selection == mark ? .isSelected : [])
                                .accessibilityAction(named: "Select") { select(mark) }
                            }
                        }
                    }
                    .frame(height: 28)
                }
            }
        }
        .accessibilityLabel("Plane, \(rows.count) rows")
    }

    private func select(_ mark: PitchMark) {
        selection = mark
        onSelect(mark)
    }
}

struct EditDesk: View {
    var title: String
    var lanes: [(String, [Double])]
    var isSelected = false
    var onCommit: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedbackPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: AppMetrics.cardRadius, style: .continuous)
                    .fill(AppTheme.textPrimary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.bgBase)
                    .padding(AppMetrics.cardPadding)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)

            if lanes.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "No lanes",
                        systemImage: "timeline.selection",
                        description: Text("Add a lane to start editing.")
                    )

                    Label("No lanes", systemImage: "timeline.selection")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("Edit desk has no lanes")
            } else {
                VStack(spacing: AppMetrics.tightSpacing) {
                    ForEach(Array(lanes.enumerated()), id: \.offset) { _, lane in
                        HStack(spacing: AppMetrics.tightSpacing) {
                            Text(lane.0)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(width: 52, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(AppTheme.hairline)
                                    ForEach(Array(lane.1.enumerated()), id: \.offset) { _, start in
                                        Capsule()
                                            .fill(AppTheme.accent)
                                            .frame(width: geo.size.width * 0.18)
                                            .offset(x: geo.size.width * CGFloat(start))
                                    }
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                }
            }

            Text(isSelected ? "Desk selected" : "Ready. Select the edit desk")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(lanes.count) lanes")
        .accessibilityValue(isSelected ? "Selected" : "Ready")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { commit() }
        .accessibilityAction(named: "Select edit desk") { commit() }
        .sensoryFeedback(.selection, trigger: feedbackPulse)
        .animation(reduceMotion ? nil : .snappy, value: isSelected)
        .contentShape(Rectangle())
        .onTapGesture(perform: commit)
    }

    private func commit() {
        feedbackPulse.toggle()
        onCommit?()
    }
}

struct XYPad: View {
    @Binding var x: Double
    @Binding var y: Double
    var caption: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var feedbackStep: Int {
        Int(x * 10) * 100 + Int(y * 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            pad(height: dynamicTypeSize.isAccessibilitySize ? 300 : 240)

            Text(x == 0 && y == 0 ? "\(caption): ready" : "\(caption): \(Int(x * 100)), \(Int(y * 100))")
                .font(.caption)
                .foregroundStyle(x == 0 && y == 0 ? AppTheme.textSecondary : AppTheme.accent)
        }
        .sensoryFeedback(.selection, trigger: feedbackStep)
        .animation(reduceMotion ? nil : .snappy, value: feedbackStep)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue("Horizontal \(Int(x * 100)) percent, vertical \(Int(y * 100)) percent")
        .accessibilityAction(named: "Move right") {
            x = min(1, x + 0.05)
        }
        .accessibilityAction(named: "Move left") {
            x = max(0, x - 0.05)
        }
        .accessibilityAction(named: "Move up") {
            y = min(1, y + 0.05)
        }
        .accessibilityAction(named: "Move down") {
            y = max(0, y - 0.05)
        }
        .accessibilityAction(named: "Center") {
            x = 0.5
            y = 0.5
        }
        .accessibilityAction(named: "Reset") {
            x = 0
            y = 0
        }
    }

    private func pad(height: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
                    .stroke(AppTheme.textPrimary, lineWidth: 2)
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 22, height: 22)
                    .position(
                        x: geo.size.width * CGFloat(min(1, max(0, x))),
                        y: geo.size.height * CGFloat(1 - min(1, max(0, y)))
                    )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        x = min(1, max(0, value.location.x / max(geo.size.width, 1)))
                        y = min(1, max(0, 1 - value.location.y / max(geo.size.height, 1)))
                    }
            )
        }
        .frame(height: height)
    }
}

#Preview {
    StagePlanesPreview()
}

private struct StagePlanesPreview: View {
    @State private var selection: PitchMark?
    @State private var x = 0.35
    @State private var y = 0.65

    private let marks = [
        PitchMark(id: "1", row: 0, start: 0.05, length: 0.16),
        PitchMark(id: "2", row: 1, start: 0.22, length: 0.12),
        PitchMark(id: "3", row: 2, start: 0.35, length: 0.20),
        PitchMark(id: "4", row: 3, start: 0.52, length: 0.16),
        PitchMark(id: "5", row: 1, start: 0.7, length: 0.10),
        PitchMark(id: "6", row: 0, start: 0.82, length: 0.14),
        PitchMark(id: "7", row: 2, start: 0.76, length: 0.08),
        PitchMark(id: "8", row: 3, start: 0.9, length: 0.07)
    ]

    var body: some View {
        ScreenScaffold {
            PitchPlane(
                rows: ["C4", "D4", "E4", "G4"],
                marks: marks,
                selection: $selection,
                onSelect: { _ in }
            )
            EditDesk(
                title: "Take 2",
                lanes: [("Picture", [0.1, 0.5]), ("Sound", [0.2, 0.72])],
                onCommit: {}
            )
            XYPad(x: $x, y: $y, caption: "Position")
        }
    }
}
