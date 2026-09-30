import SwiftData
import SwiftUI

struct ShelvesScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChanceSetup.sortOrder) private var shelves: [ChanceSetup]
    @Query private var toys: [Toy]
    @AppStorage("activeShelf") private var activeShelfName = ""

    @State private var picked: Int?
    @State private var editing: ChanceSetup?
    @State private var creating = false
    @State private var pendingDelete: ChanceSetup?

    private var pickedShelf: ChanceSetup? {
        guard let picked, shelves.indices.contains(picked) else {
            return shelves.first { $0.name == activeShelfName } ?? shelves.first
        }
        return shelves[picked]
    }

    var body: some View {
        Group {
            ScreenScaffold {
                ScreenHeader(
                    title: "\(shelves.count) shelf setups",
                    subtitle: "Tap the stack to pick where the next toy gets placed"
                )

                TicketStack(
                    names: stackOrder.map(\.name),
                    selected: 0,
                    onSelect: { _ in advance() }
                )

                if let shelf = pickedShelf {
                    SeriesWheel(segments: wheelSegments(for: shelf))
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                    ChipRow {
                        TagChip(title: "\(shelf.columns)×\(shelf.rows) slots", systemImage: "square.grid.3x2")
                        TagChip(title: DrawMode(rawValue: shelf.modeID)?.title ?? "One figure", systemImage: "die.face.3")
                        TagChip(title: "Priority ×\(shelf.staleWeight.formatted(.number.precision(.fractionLength(1))))", systemImage: "clock.arrow.circlepath")
                    }
                }

                CTAButton(
                    title: pickedShelf?.name == activeShelfName ? "Active on the Draw tab" : "Use for the next draw",
                    systemImage: "checkmark.circle",
                    emphasis: pickedShelf?.name == activeShelfName ? .secondary : .primary,
                    isEnabled: pickedShelf != nil && pickedShelf?.name != activeShelfName
                ) {
                    activeShelfName = pickedShelf?.name ?? activeShelfName
                }

                if shelves.isEmpty {
                    EmptyStateCard(
                        title: "No shelves yet",
                        message: "Add the shelf or cabinet you rotate figures on.",
                        systemImage: "books.vertical",
                        actionTitle: "Add shelf",
                        action: { creating = true }
                    )
                } else {
                    SectionLabel(title: "All shelves", detail: "Swipe to delete")
                    ForEach(shelves) { shelf in
                        SwipeRow(
                            title: shelf.name + (shelf.name == activeShelfName ? " · active" : ""),
                            subtitle: summary(shelf),
                            systemImage: shelf.rows > 1 ? "square.grid.2x2" : "rectangle.split.3x1",
                            onTap: { editing = shelf }
                        ) {
                            Button(role: .destructive) {
                                pendingDelete = shelf
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shelves")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        creating = true
                    } label: {
                        Label("Add shelf", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editing) { shelf in
                ShelfEditorSheet(shelf: shelf)
            }
            .sheet(isPresented: $creating) {
                ShelfEditorSheet(shelf: nil)
            }
            .confirmationDialog(
                "Delete \(pendingDelete?.name ?? "shelf")?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    if let pendingDelete {
                        context.delete(pendingDelete)
                        try? context.save()
                    }
                    pendingDelete = nil
                } label: {
                    Text("Delete shelf")
                }
            } message: {
                Text("Placement history for this shelf stays in the Log.")
            }
        }
    }

    private var stackOrder: [ChanceSetup] {
        guard let current = pickedShelf, let index = shelves.firstIndex(of: current) else { return shelves }
        return Array(shelves[index...]) + Array(shelves[..<index])
    }

    private func advance() {
        guard !shelves.isEmpty else { return }
        let current = pickedShelf.flatMap { shelves.firstIndex(of: $0) } ?? 0
        picked = (current + 1) % shelves.count
    }

    private func summary(_ shelf: ChanceSetup) -> String {
        let series = shelf.series.isEmpty ? "all series" : shelf.series.joined(separator: ", ")
        return "\(shelf.slotCount) slots · \(series)"
    }

    private func wheelSegments(for shelf: ChanceSetup) -> [SeriesWheel.Segment] {
        let names = shelf.series.isEmpty ? SeedData.seriesNames : shelf.series
        return names.enumerated().map { index, name in
            let members = toys.filter { $0.series == name }
            let weight = members.reduce(0.0) { total, toy in
                total + RNGEngine.weight(
                    RNGEngine.Candidate(name: toy.name, series: toy.series, daysBoxed: toy.daysBoxed),
                    staleWeight: shelf.staleWeight
                )
            }
            return SeriesWheel.Segment(name: name, weight: max(weight, 0.5), hue: Double(index) / Double(max(names.count, 1)))
        }
    }
}

#Preview {
    NavigationStack {
        ShelvesScreen()
    }
    .previewStore()
}
