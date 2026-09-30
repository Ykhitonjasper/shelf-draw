import SwiftUI

/// A short stack of tickets. The top one is the one in hand.
struct TicketStack: View {
    var names: [String]
    var selected: Int?
    var onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let cardHeight: CGFloat = 68
    private static let peek: CGFloat = 10

    var body: some View {
        Group {
            if names.isEmpty {
                ContentUnavailableView(
                    "Ticket drum empty",
                    systemImage: "ticket",
                    description: Text("Add entrants to build the stack.")
                )
            } else {
                Button(action: drawNext) {
                    ZStack(alignment: .top) {
                        ForEach(Array(names.prefix(3).enumerated()).reversed(), id: \.offset) { index, name in
                            let shape = RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
                            HStack(spacing: AppMetrics.contentSpacing) {
                                Capsule()
                                    .fill(index == selected ? AppTheme.accent : AppTheme.hairline)
                                    .frame(width: 5, height: 36)
                                ViewThatFits {
                                    Text(name).font(.headline)
                                    Text(name).font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                                Spacer(minLength: 0)
                                Text(index == selected ? "DRAWN" : "READY")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(index == selected ? AppTheme.accent : AppTheme.textSecondary)
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.horizontal, AppMetrics.cardPadding)
                            .frame(maxWidth: .infinity)
                            .frame(height: Self.cardHeight)
                            .background(AppTheme.bgElevated, in: shape)
                            .overlay {
                                shape.stroke(index == selected ? AppTheme.accent : AppTheme.hairline, lineWidth: AppMetrics.hairlineWidth)
                            }
                            .opacity(index == 0 ? 1 : 1 - Double(index) * 0.25)
                            .scaleEffect(x: 1 - CGFloat(index) * 0.05, y: 1, anchor: .top)
                            .offset(y: CGFloat(index) * Self.peek)
                            .zIndex(Double(3 - index))
                        }
                    }
                    .frame(height: Self.cardHeight + Self.peek * CGFloat(max(min(names.count, 3) - 1, 0)), alignment: .top)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selected.flatMap { names.indices.contains($0) ? "Drawn ticket for \(names[$0])" : nil } ?? "Ticket stack ready")
                .accessibilityAction(named: "Draw next ticket") { drawNext() }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: selected)
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func drawNext() {
        let current = selected.flatMap { names.indices.contains($0) ? $0 : nil }
        onSelect(current.map { ($0 + 1) % names.count } ?? 0)
    }
}

#Preview {
    ScreenScaffold {
        TicketStack(
            names: ["Priya", "Owen", "Mina", "Jonah", "Esme", "Kai"],
            selected: 0,
            onSelect: { _ in }
        )
    }
}
