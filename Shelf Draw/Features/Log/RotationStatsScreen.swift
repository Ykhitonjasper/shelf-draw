import SwiftData
import SwiftUI

struct RotationStatsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var toys: [Toy]
    @Query private var results: [SpinResult]

    @State private var window = "30"

    private var cutoff: Date {
        Calendar.current.date(byAdding: .day, value: -(Int(window) ?? 30), to: .now) ?? .now
    }

    private var seriesRows: [(name: String, shown: Int, total: Int)] {
        SeedData.seriesNames.map { name in
            let members = toys.filter { $0.series == name }
            let shown = members.filter { ($0.lastShown ?? .distantPast) >= cutoff }.count
            return (name, shown, members.count)
        }
    }

    private var longestBoxed: [Toy] {
        toys.sorted { $0.daysBoxed > $1.daysBoxed }.prefix(6).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScreenScaffold {
                ScreenHeader(title: "Rotation stats", subtitle: "How much of the collection reached a shelf")

                SegmentedPicker(
                    title: "Window",
                    options: [SegmentOption("14 days", id: "14"), SegmentOption("30 days", id: "30"), SegmentOption("90 days", id: "90")],
                    selection: $window
                )

                TileGrid {
                    ForEach(seriesRows, id: \.name) { row in
                        MetricTile(title: row.name, value: "\(row.shown)/\(row.total)", caption: "shown in \(window) days")
                    }
                }

                SectionLabel(title: "Longest in the box", detail: "next in line for a shelf")
                ForEach(longestBoxed) { toy in
                    DetailRow(label: toy.name, value: toy.lastShown == nil ? "never shown · box \(toy.boxNumber)" : "\(toy.daysBoxed) days · box \(toy.boxNumber)")
                }

                TagChip(title: "\(results.filter { !$0.isPlanned }.count) placements logged", systemImage: "clock")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }
}

#Preview {
    RotationStatsScreen()
        .previewStore()
}
