import SwiftData
import SwiftUI

struct ShelfEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChanceSetup.sortOrder) private var shelves: [ChanceSetup]

    let shelf: ChanceSetup?

    @State private var name = ""
    @State private var columns = "4"
    @State private var rows = "1"
    @State private var series: Set<String> = []
    @State private var staleWeight = 1.0
    @State private var modeID = DrawMode.one.rawValue
    @State private var rowSize = 2
    @State private var loaded = false

    private var columnsError: String? {
        guard let value = Int(columns), (1...8).contains(value) else { return "Use 1 to 8 slots per board." }
        return nil
    }

    private var rowsError: String? {
        guard let value = Int(rows), (1...4).contains(value) else { return "Use 1 to 4 boards." }
        return nil
    }

    private var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Name the shelf, e.g. Hallway niche." }
        if shelves.contains(where: { $0 !== shelf && $0.name == trimmed }) { return "Another shelf has this name." }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                ScreenHeader(title: shelf == nil ? "New shelf" : "Edit shelf", subtitle: "Slots, series, and how hard long-boxed figures push forward")

                SeriesWheel(segments: previewSegments)
                    .frame(height: 150)

                SectionCard(title: "Shelf") {
                    TextField("Shelf name", text: $name)
                        .padding(.vertical, AppMetrics.inputVerticalPadding)
                    if let nameError, loaded {
                        InlineError(message: nameError)
                    }
                    NumberField(title: "Slots per board", value: $columns, unit: "slots", error: columnsError)
                    NumberField(title: "Boards", value: $rows, unit: "boards", error: rowsError)
                }

                SectionCard(title: "Series in the draw", footnote: "None picked means every series.") {
                    ChipRow {
                        ForEach(SeedData.seriesNames, id: \.self) { name in
                            FilterChip(title: name, isSelected: series.contains(name)) {
                                if series.contains(name) { series.remove(name) } else { series.insert(name) }
                            }
                        }
                    }
                }

                SectionCard(title: "Draw", footnote: "Priority lifts figures by days spent in the box. It is a nudge, not a guarantee.") {
                    SegmentedPicker(
                        title: "Default mode",
                        options: DrawMode.allCases.map { SegmentOption($0.title, id: $0.rawValue) },
                        selection: $modeID
                    )
                    VStack(alignment: .leading) {
                        Text("Long-boxed priority ×\(staleWeight.formatted(.number.precision(.fractionLength(1))))")
                            .font(.subheadline)
                        Slider(value: $staleWeight, in: 0...3, step: 0.1)
                    }
                    Stepper("Row draw size \(rowSize)", value: $rowSize, in: 1...6)
                }

                ActionButton(
                    title: "Save shelf",
                    emphasis: .primary,
                    isEnabled: nameError == nil && columnsError == nil && rowsError == nil
                ) {
                    save()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: load)
        }
    }

    private var previewSegments: [SeriesWheel.Segment] {
        let names = series.isEmpty ? SeedData.seriesNames : SeedData.seriesNames.filter(series.contains)
        return names.enumerated().map { index, name in
            SeriesWheel.Segment(name: name, weight: 1 + staleWeight * Double(index + 1) / 3, hue: Double(index) / Double(max(names.count, 1)))
        }
    }

    private func load() {
        guard !loaded else { return }
        if let shelf {
            name = shelf.name
            columns = "\(shelf.columns)"
            rows = "\(shelf.rows)"
            series = Set(shelf.series)
            staleWeight = shelf.staleWeight
            modeID = shelf.modeID
            rowSize = shelf.rowSize
        }
        loaded = true
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let picked = SeedData.seriesNames.filter(series.contains)
        if let shelf {
            shelf.name = trimmed
            shelf.columns = Int(columns) ?? shelf.columns
            shelf.rows = Int(rows) ?? shelf.rows
            shelf.series = picked
            shelf.staleWeight = staleWeight
            shelf.modeID = modeID
            shelf.rowSize = rowSize
        } else {
            context.insert(ChanceSetup(
                name: trimmed,
                columns: Int(columns) ?? 4,
                rows: Int(rows) ?? 1,
                series: picked,
                staleWeight: staleWeight,
                modeID: modeID,
                rowSize: rowSize,
                sortOrder: (shelves.map(\.sortOrder).max() ?? 0) + 1
            ))
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    ShelfEditorSheet(shelf: nil)
        .previewStore()
}
