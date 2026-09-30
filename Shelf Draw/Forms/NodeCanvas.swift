import SwiftUI

struct BoardNode: Identifiable, Hashable {
    var id: String
    var title: String
    var x: CGFloat
    var y: CGFloat
}

struct NodeCanvas: View {
    var nodes: [BoardNode]
    @Binding var selection: BoardNode?
    var onSelect: (BoardNode) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pan: CGSize = .zero
    @GestureState private var drag: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            if nodes.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "Board is empty",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        description: Text("Add a node to begin mapping.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)

                    Label("Board is empty", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 140)
                }
                .accessibilityLabel("Board is empty")
            } else {
                if dynamicTypeSize.isAccessibilitySize {
                    nodeList
                } else {
                    ViewThatFits(in: .horizontal) {
                        board(height: 380)
                            .frame(minWidth: 420)
                        board(height: 300)
                    }
                }

                Text(selection.map { "Selected: \($0.title)" } ?? "Ready. Choose or pan to a node")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selection == nil ? AppTheme.textSecondary : AppTheme.accent)
                    .accessibilityLabel(selection.map { "Selected \($0.title)" } ?? "Ready to choose a node")
            }
        }
        .accessibilityLabel("Board, \(nodes.count) nodes")
        .accessibilityValue(selection.map { "\($0.title) selected" } ?? "Ready to select a node")
        .accessibilityAction(named: "Select next node") {
            guard !nodes.isEmpty else { return }
            let current = selection.flatMap { nodes.firstIndex(of: $0) } ?? -1
            select(nodes[(current + 1) % nodes.count])
        }
        .accessibilityAction(named: "Reset board position") {
            pan = .zero
        }
        .sensoryFeedback(.selection, trigger: selection?.id)
        .animation(reduceMotion ? nil : .snappy, value: selection?.id)
    }

    private var nodeList: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            ForEach(nodes) { node in
                Button {
                    select(node)
                } label: {
                    HStack(spacing: AppMetrics.contentSpacing) {
                        Image(systemName: selection == node ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selection == node ? AppTheme.accent : AppTheme.textSecondary)
                        Text(node.title)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Node \(node.title)")
                .accessibilityAddTraits(selection == node ? .isSelected : [])
            }
        }
    }

    private func board(height: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    let step: CGFloat = 28
                    var grid = Path()
                    var x = CGFloat(0)
                    while x <= size.width {
                        grid.move(to: CGPoint(x: x, y: 0))
                        grid.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }
                    var y = CGFloat(0)
                    while y <= size.height {
                        grid.move(to: CGPoint(x: 0, y: y))
                        grid.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }
                    context.stroke(grid, with: .color(AppTheme.hairline), lineWidth: AppMetrics.hairlineWidth)
                }
                ForEach(nodes) { node in
                    Button {
                        select(node)
                    } label: {
                        Text(node.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(AppMetrics.contentSpacing)
                            .background(
                                selection == node ? AppTheme.accent.opacity(0.35) : AppTheme.bgElevated,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule().stroke(
                                    selection == node ? AppTheme.accent : AppTheme.textPrimary,
                                    lineWidth: selection == node ? 2 : AppMetrics.hairlineWidth
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .offset(x: node.x + pan.width + drag.width, y: node.y + pan.height + drag.height)
                    .accessibilityLabel("Node \(node.title)")
                    .accessibilityAddTraits(selection == node ? .isSelected : [])
                    .accessibilityAction(named: "Select") { select(node) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($drag) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        pan.width += value.translation.width
                        pan.height += value.translation.height
                    }
            )
        }
        .frame(height: height)
        .clipped()
    }

    private func select(_ node: BoardNode) {
        selection = node
        onSelect(node)
    }
}

#Preview {
    NodeCanvasPreview()
}

private struct NodeCanvasPreview: View {
    @State private var selection: BoardNode?

    private let nodes = [
        BoardNode(id: "a", title: "Clay", x: 18, y: 28),
        BoardNode(id: "b", title: "Wheel", x: 142, y: 72),
        BoardNode(id: "c", title: "Trim", x: 52, y: 136),
        BoardNode(id: "d", title: "Bisque", x: 190, y: 182),
        BoardNode(id: "e", title: "Glaze", x: 90, y: 242),
        BoardNode(id: "f", title: "Kiln", x: 224, y: 302),
        BoardNode(id: "g", title: "Cone pack", x: 12, y: 318),
        BoardNode(id: "h", title: "Shelf log", x: 146, y: 336)
    ]

    var body: some View {
        ScreenScaffold {
            NodeCanvas(nodes: nodes, selection: $selection, onSelect: { _ in })
        }
    }
}
