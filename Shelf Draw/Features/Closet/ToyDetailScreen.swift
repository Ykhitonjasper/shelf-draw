import SwiftData
import SwiftUI

struct ToyDetailScreen: View {
    let toy: Toy

    @Environment(\.modelContext) private var context
    @Query(sort: \ChanceSetup.sortOrder) private var shelves: [ChanceSetup]
    @Query(sort: \SpinResult.placedAt, order: .reverse) private var results: [SpinResult]
    @AppStorage("activeShelf") private var activeShelfName = ""
    @State private var placedTick = 0
    @State private var rejectTick = 0
    @State private var notice: String?

    private var history: [SpinResult] {
        results.filter { $0.toyName == toy.name }
    }

    private var shelf: ChanceSetup? {
        shelves.first { $0.name == activeShelfName } ?? shelves.first
    }

    var body: some View {
        ScreenScaffold {
            Group {
                if let data = toy.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ZStack {
                        Circle().fill(toy.tint.opacity(0.25))
                        Image(systemName: "figure.stand")
                            .font(.largeTitle)
                            .foregroundStyle(toy.tint)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .accessibilityLabel("Photo of \(toy.name)")

            ResultCard(
                title: toy.series,
                value: toy.lastShown == nil ? "Never shown" : "\(toy.daysBoxed)",
                unit: toy.lastShown == nil ? nil : "days boxed",
                lines: [
                    ResultLine(label: "Storage box", value: "\(toy.boxNumber)"),
                    ResultLine(label: "Placements", value: "\(history.count)"),
                    ResultLine(label: "Added", value: toy.addedAt.formatted(.dateTime.day().month().year())),
                ]
            )

            if let notice {
                StatusBanner(message: notice, tone: .warning)
            }

            ActionButton(title: "Place on \(shelf?.name ?? "shelf")", systemImage: "square.and.arrow.down", emphasis: .primary) {
                placeNow()
            }
            .confirm(on: placedTick)
            .reject(on: rejectTick)

            SectionLabel(title: "Shelf history", detail: "\(history.count) placements")
            if history.isEmpty {
                EmptyStateCard(title: "Never on a shelf", message: "This figure has only lived in box \(toy.boxNumber) so far.", systemImage: "shippingbox")
            } else {
                ForEach(history) { result in
                    DetailRow(label: result.shelfName, value: "slot \(result.slot + 1) · \(result.placedAt.formatted(.dateTime.day().month()))")
                }
            }
        }
        .navigationTitle(toy.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func placeNow() {
        guard let shelf else {
            notice = "Add a shelf first."
            rejectTick += 1
            return
        }
        let occupied = ShelfOccupancy.current(results, shelf: shelf.name)
        if occupied.values.contains(where: { $0.toyName == toy.name }) {
            notice = "\(toy.name) already stands on \(shelf.name)."
            rejectTick += 1
            return
        }
        let slot = (0..<shelf.slotCount).first { occupied[$0] == nil } ?? 0
        context.insert(SpinResult(
            toyName: toy.name,
            series: toy.series,
            hue: toy.hue,
            shelfName: shelf.name,
            slot: slot,
            placedAt: .now,
            modeID: "hand",
            daysBoxed: toy.daysBoxed
        ))
        toy.lastShown = .now
        try? context.save()
        notice = nil
        placedTick += 1
    }
}

#Preview {
    NavigationStack {
        ToyDetailScreen(toy: Toy(name: "Kaiju Rex", series: "Kaiju Vinyl", boxNumber: 3, hue: 0.33))
    }
    .previewStore()
}
