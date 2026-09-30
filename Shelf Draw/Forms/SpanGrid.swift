import SwiftUI

struct SpanGrid<Item: Identifiable, Content: View>: View {
    var items: [Item]
    @Binding var selection: Item.ID?
    var onSelect: (Item) -> Void
    var span: (Item) -> Int
    @ViewBuilder var content: (Item) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let rows = Self.rows(items: items, span: span)

        VStack(alignment: .leading, spacing: AppMetrics.contentSpacing) {
            if items.isEmpty {
                ViewThatFits {
                    ContentUnavailableView(
                        "Nothing to choose",
                        systemImage: "rectangle.grid.2x2",
                        description: Text("Add an item to build this grid.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)

                    Label("Nothing to choose", systemImage: "rectangle.grid.2x2")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                .accessibilityLabel("No grid items")
            } else {
                ViewThatFits(in: .horizontal) {
                    gridRows(rows)
                    VStack(spacing: AppMetrics.contentSpacing) {
                        ForEach(items) { item in
                            choice(item)
                        }
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .animation(reduceMotion ? nil : .snappy, value: selection)
        .accessibilityAction(named: "Select first item") {
            if let first = items.first { select(first) }
        }
    }

    @ViewBuilder
    private func gridRows(_ rows: [[Item]]) -> some View {
        VStack(spacing: AppMetrics.contentSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                if row.count == 1, let item = row.first, span(item) >= 2 {
                    choice(item)
                } else {
                    HStack(alignment: .top, spacing: AppMetrics.contentSpacing) {
                        ForEach(row) { item in
                            choice(item)
                        }
                    }
                }
            }
        }
    }

    private func choice(_ item: Item) -> some View {
        Button {
            select(item)
        } label: {
            content(item)
                .frame(maxWidth: .infinity, alignment: .top)
                .overlay(alignment: .topTrailing) {
                    if selection == item.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                            .padding(AppMetrics.tightSpacing)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityValue(selection == item.id ? "Selected" : "Ready to select")
        .accessibilityAddTraits(selection == item.id ? .isSelected : [])
        .accessibilityAction(named: "Select") { select(item) }
    }

    private func select(_ item: Item) {
        selection = item.id
        onSelect(item)
    }

    private static func rows(items: [Item], span: (Item) -> Int) -> [[Item]] {
        var built: [[Item]] = []
        var current: [Item] = []
        for item in items {
            if span(item) >= 2 {
                if !current.isEmpty {
                    built.append(current)
                    current = []
                }
                built.append([item])
            } else if current.count == 1 {
                current.append(item)
                built.append(current)
                current = []
            } else {
                current = [item]
            }
        }
        if !current.isEmpty { built.append(current) }
        return built
    }
}

struct ConcentricFrame<Content: View>: View {
    var step: Int
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(AppTheme.textPrimary.opacity(ring == step ? 1 : 0.25), lineWidth: ring == step ? 3 : 1)
                    .frame(width: CGFloat(120 + ring * 48), height: CGFloat(120 + ring * 48))
                    .scaleEffect(ring <= step ? 1 : 0.86)
                    .animation(reduceMotion ? nil : .spring(duration: 0.4), value: step)
            }
            content()
                .padding(AppMetrics.sectionSpacing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }
}

#Preview {
    SpanGridPreview()
}

private struct SpanGridSample: Identifiable {
    let id: String
    let title: String
    let span: Int
}

private struct SpanGridPreview: View {
    @State private var selection: String?

    private let samples = [
        SpanGridSample(id: "one", title: "Clay body", span: 2),
        SpanGridSample(id: "two", title: "Trim", span: 1),
        SpanGridSample(id: "three", title: "Handle", span: 1),
        SpanGridSample(id: "four", title: "Bisque", span: 2),
        SpanGridSample(id: "five", title: "Glaze", span: 1),
        SpanGridSample(id: "six", title: "Fire", span: 1),
        SpanGridSample(id: "seven", title: "Kiln log", span: 2),
        SpanGridSample(id: "eight", title: "Shelf", span: 1)
    ]

    var body: some View {
        ScreenScaffold {
            SpanGrid(
                items: samples,
                selection: $selection,
                onSelect: { _ in },
                span: \.span
            ) { sample in
                Text(sample.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(AppMetrics.cardPadding)
                    .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                    .background(AppTheme.bgElevated)
            }
            ConcentricFrame(step: selection == nil ? 0 : 1) {
                Text(selection == nil ? "Choose" : "Ready")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
}
