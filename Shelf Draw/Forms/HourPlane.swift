import SwiftUI

struct HourBlock: Identifiable, Hashable {
    var id: String
    var title: String
    var startHour: Double
    var durationHours: Double
}

struct HourPlane<Header: View>: View {
    var dayStart: Int = 8
    var dayEnd: Int = 20
    var blocks: [HourBlock]
    @Binding var selection: HourBlock?
    var onSelect: ((HourBlock) -> Void)?
    @ViewBuilder var header: () -> Header

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var feedbackSelection: String?
    private let hourHeight: CGFloat = 52

    var body: some View {
        let visible = blocks.filter { block in
            block.startHour < Double(dayEnd) && block.startHour + block.durationHours > Double(dayStart)
        }

        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            header()

            if visible.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "No blocks scheduled",
                        systemImage: "clock",
                        description: Text("Add a block to make this day interactive.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)

                    Label("No blocks scheduled", systemImage: "clock")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                .accessibilityLabel("No blocks scheduled")
            } else {
                if dynamicTypeSize.isAccessibilitySize {
                    blockList(visible)
                } else {
                    ViewThatFits(in: .horizontal) {
                        plane(visible, labelWidth: 28)
                            .frame(minWidth: 320)
                        plane(visible, labelWidth: 22)
                    }
                }

                Text(selection == nil ? "Choose a block" : "Selected: \(selection?.title ?? "")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selection == nil ? AppTheme.textSecondary : AppTheme.accent)
                    .accessibilityLabel(selection == nil ? "Ready. Choose a block" : "Selected \(selection?.title ?? "")")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Select next block") {
            guard !visible.isEmpty else { return }
            let index = selection.flatMap { selected in visible.firstIndex(of: selected) } ?? -1
            select(visible[(index + 1) % visible.count])
        }
        .sensoryFeedback(.selection, trigger: feedbackSelection)
        .animation(reduceMotion ? nil : .snappy, value: selection?.id)
    }

    private func blockList(_ visible: [HourBlock]) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            ForEach(visible.sorted { $0.startHour < $1.startHour }) { block in
                Button {
                    select(block)
                } label: {
                    VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                        Text(block.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("\(timeLabel(block.startHour)) · \(durationLabel(block.durationHours))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("\(block.title), starts \(timeLabel(block.startHour)), duration \(durationLabel(block.durationHours))")
                .accessibilityAddTraits(selection == block ? .isSelected : [])
            }
        }
    }

    private func plane(_ visible: [HourBlock], labelWidth: CGFloat) -> some View {
        let lanes = Self.lanes(for: visible)
        let laneCount = max(1, Set(lanes.values).count)

        return HStack(alignment: .top, spacing: AppMetrics.tightSpacing) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(dayStart..<dayEnd, id: \.self) { hour in
                    Text(String(format: "%02d", hour))
                        .font(.caption2.monospaced())
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: labelWidth, height: hourHeight, alignment: .topTrailing)
                }
            }
            GeometryReader { geo in
                let column = geo.size.width / CGFloat(laneCount)
                ZStack(alignment: .topLeading) {
                    ForEach(dayStart..<dayEnd, id: \.self) { hour in
                        Rectangle()
                            .fill(AppTheme.hairline)
                            .frame(height: AppMetrics.hairlineWidth)
                            .offset(y: CGFloat(hour - dayStart) * hourHeight)
                    }
                    ForEach(visible) { block in
                        let lane = lanes[block.id, default: 0]
                        let y = CGFloat(block.startHour - Double(dayStart)) * hourHeight
                        let height = max(hourHeight * 0.6, CGFloat(block.durationHours) * hourHeight - 4)
                        Button {
                            select(block)
                        } label: {
                            Text(block.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(3)
                                .padding(AppMetrics.tightSpacing)
                                .frame(width: max(24, column - 6), height: height, alignment: .topLeading)
                                .background(selection == block ? AppTheme.accent.opacity(0.42) : AppTheme.accent.opacity(0.20))
                                .overlay {
                                    Rectangle().stroke(
                                        AppTheme.accent,
                                        lineWidth: selection == block ? 2 : AppMetrics.hairlineWidth
                                    )
                                }
                        }
                        .buttonStyle(.plain)
                        .offset(x: CGFloat(lane) * column + 2, y: y)
                        .accessibilityLabel("\(block.title), starts \(timeLabel(block.startHour)), duration \(durationLabel(block.durationHours))")
                        .accessibilityAddTraits(selection == block ? .isSelected : [])
                        .accessibilityAction(named: "Select") { select(block) }
                    }
                }
            }
            .frame(height: CGFloat(dayEnd - dayStart) * hourHeight)
        }
    }

    private func select(_ block: HourBlock) {
        selection = block
        feedbackSelection = block.id
        onSelect?(block)
    }

    private func timeLabel(_ hour: Double) -> String {
        let whole = Int(hour)
        let minutes = Int((hour - Double(whole)) * 60)
        return String(format: "%02d:%02d", whole, minutes)
    }

    private func durationLabel(_ hours: Double) -> String {
        "\(Int(hours * 60)) minutes"
    }

    private static func lanes(for blocks: [HourBlock]) -> [String: Int] {
        let ordered = blocks.sorted { $0.startHour < $1.startHour }
        var ends: [Double] = []
        var assigned: [String: Int] = [:]
        for block in ordered {
            let end = block.startHour + block.durationHours
            if let lane = ends.firstIndex(where: { $0 <= block.startHour + 0.01 }) {
                ends[lane] = end
                assigned[block.id] = lane
            } else {
                assigned[block.id] = ends.count
                ends.append(end)
            }
        }
        return assigned
    }
}

extension HourPlane where Header == EmptyView {
    init(
        dayStart: Int = 8,
        dayEnd: Int = 20,
        blocks: [HourBlock],
        selection: Binding<HourBlock?>,
        onSelect: ((HourBlock) -> Void)? = nil
    ) {
        self.init(
            dayStart: dayStart,
            dayEnd: dayEnd,
            blocks: blocks,
            selection: selection,
            onSelect: onSelect,
            header: { EmptyView() }
        )
    }
}

#Preview {
    HourPlanePreview()
}

private struct HourPlanePreview: View {
    @State private var selection: HourBlock?

    private let blocks = [
        HourBlock(id: "a", title: "Throw", startHour: 8.5, durationHours: 1.5),
        HourBlock(id: "b", title: "Trim", startHour: 9, durationHours: 1),
        HourBlock(id: "c", title: "Glaze", startHour: 10.5, durationHours: 1.5),
        HourBlock(id: "d", title: "Load", startHour: 12.5, durationHours: 1),
        HourBlock(id: "e", title: "Fire", startHour: 14, durationHours: 2),
        HourBlock(id: "f", title: "Cool", startHour: 17, durationHours: 1.5),
        HourBlock(id: "g", title: "Unload", startHour: 18.5, durationHours: 0.75),
        HourBlock(id: "h", title: "Shelf notes", startHour: 19.25, durationHours: 0.5)
    ]

    var body: some View {
        ScreenScaffold {
            HourPlane(blocks: blocks, selection: $selection) {
                Text("Saturday")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
}
