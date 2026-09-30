import SwiftData
import SwiftUI

struct DrawScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChanceSetup.sortOrder) private var shelves: [ChanceSetup]
    @Query(sort: \Toy.name) private var toys: [Toy]
    @Query(sort: \SpinResult.placedAt, order: .reverse) private var results: [SpinResult]
    @AppStorage("activeShelf") private var activeShelfName = ""
    @AppStorage("staleBoost") private var staleBoost = 1.0

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var mode: DrawMode = .one
    @State private var selection: Int?
    @State private var outcome: RNGEngine.Outcome?
    @State private var targetSlot: Int?
    @State private var drawCount: UInt64 = 0
    @State private var placedTick = 0
    @State private var shuffling = false
    @State private var notice: String?
    @State private var lastPlaced: [SpinResult] = []
    @State private var showCloset = false

    private var shelf: ChanceSetup? {
        shelves.first { $0.name == activeShelfName } ?? shelves.first
    }

    private var occupancy: [Int: SpinResult] {
        guard let shelf else { return [:] }
        return ShelfOccupancy.current(results, shelf: shelf.name)
    }

    private var candidates: [Toy] {
        let onShelf = Set(occupancy.values.map(\.toyName))
        return toys.filter { toy in
            !onShelf.contains(toy.name) && (shelf?.series.isEmpty ?? true || shelf?.series.contains(toy.series) == true)
        }
    }

    private var freeSlots: [Int] {
        guard let shelf else { return [] }
        return (0..<shelf.slotCount).filter { occupancy[$0] == nil }
    }

    private var drawnToys: [Toy] {
        guard let outcome else { return [] }
        let pool = candidates
        return outcome.picks.compactMap { pool.indices.contains($0) ? pool[$0] : nil }
    }

    var body: some View {
        ScreenScaffold {
            HStack(spacing: 8) {
                TagChip(title: "\(occupancy.count) of \(shelf?.slotCount ?? 0) slots filled", systemImage: "square.grid.2x2")
                TagChip(title: "\(candidates.count) boxed", systemImage: "shippingbox")
                Spacer(minLength: 0)
            }

            ZStack(alignment: .top) {
                OneDraw(
                    label: drawLabel,
                    options: candidates.map(\.name),
                    selection: $selection,
                    onCommit: { _ in draw() }
                )
                Button(action: draw) {
                    Color.clear
                        .frame(width: 200, height: 200)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(shuffling || candidates.isEmpty)
                .accessibilityIdentifier("smoke.draw.commit")
                .accessibilityLabel("Draw a figure")
            }
            .arrive()
            if outcome != nil {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(drawnToys.first?.name ?? "Drawn")
                    .accessibilityIdentifier("smoke.draw.result")
            }

            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                shelfBoard
                Label(
                    outcome == nil ? "Draw first, then drag across the shelf to pick a slot" : "Drag across the shelf to move it to another slot",
                    systemImage: "hand.draw"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }
            .cardSurface()

            ChipRow {
                ForEach(DrawMode.allCases) { item in
                    FilterChip(title: item.title, isSelected: mode == item) {
                        mode = item
                        resetDraw()
                    }
                    .accessibilityIdentifier(item == .slot ? "smoke.draw.slot" : "smoke.draw.mode")
                }
            }
            if mode == .slot {
                Text("Picking by slot number")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .accessibilityIdentifier("smoke.draw.slotset")
            }

            if let notice {
                HStack(spacing: AppMetrics.contentSpacing) {
                    StatusBanner(message: notice, tone: .note)
                        .accessibilityIdentifier("smoke.draw.placed")
                    if !lastPlaced.isEmpty {
                        Button {
                            undoLast()
                        } label: {
                            Text("Undo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            ActionButton(
                title: outcome?.keep == true ? "Keep this shelf" : placeTitle,
                systemImage: outcome?.keep == true ? "checkmark" : "square.and.arrow.down.on.square",
                emphasis: outcome == nil ? .secondary : .primary,
                isEnabled: shelf != nil && outcome != nil && !shuffling
            ) {
                placeDraw()
            }
            .accessibilityIdentifier("smoke.draw.place")
            .confirm(on: placedTick)

            drawDetail
        }
        .animation(reduceMotion ? nil : .snappy, value: notice)
        .navigationTitle(shelf?.name ?? "Draw")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleMenu {
            ForEach(shelves) { item in
                Button {
                    activeShelfName = item.name
                } label: {
                    Label(item.name, systemImage: item.name == shelf?.name ? "checkmark" : "square.split.2x1")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCloset = true
                } label: {
                    Label("Storage boxes", systemImage: "shippingbox")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        undoLast()
                    } label: {
                        Label("Undo last placement", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(lastPlaced.isEmpty)
                    ShareLink(item: shareText) {
                        Label("Share shelf", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showCloset) {
            ToyClosetScreen()
        }
        .onAppear(perform: syncMode)
        .onChange(of: shelf?.name) {
            syncMode()
            resetDraw()
        }
    }

    private var placeTitle: String {
        drawnToys.count > 1 ? "Place \(drawnToys.count) on shelf" : "Place on shelf"
    }

    private var shelfBoard: some View {
        let rows = max(shelf?.rows ?? 1, 1)
        let rowHeight: CGFloat = sizeClass == .regular ? 150 : 104
        return GeometryReader { proxy in
            ShelfMark(
                columns: shelf?.columns ?? 4,
                rows: rows,
                figures: occupancy.mapValues(\.tint),
                target: outcome == nil ? nil : (targetSlot ?? outcome?.slots.first),
                ghost: drawnToys.first?.tint
            )
            .contentShape(Rectangle())
            // Simultaneous so a vertical swipe that starts on the shelf still scrolls the page.
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        pickSlot(at: value.location, in: proxy.size, rows: rows)
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        pickSlot(at: value.location, in: proxy.size, rows: rows)
                    }
            )
        }
        .frame(height: CGFloat(rows) * rowHeight)
        .sensoryFeedback(.selection, trigger: targetSlot)
        .accessibilityHint("Drag across the shelf to choose the slot for the drawn figure")
    }

    private func pickSlot(at location: CGPoint, in size: CGSize, rows: Int) {
        guard outcome != nil else { return }
        targetSlot = ShelfMark.slot(at: location, in: size, columns: shelf?.columns ?? 4, rows: rows)
    }

    @ViewBuilder
    private var drawDetail: some View {
        if let first = drawnToys.first {
            if let data = first.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.controlRadius))
            }
            ResultCard(
                title: "Out of box \(first.boxNumber)",
                value: drawnToys.map(\.name).joined(separator: ", "),
                lines: drawnToys.map { ResultLine(label: $0.name, value: "\($0.series) · \($0.daysBoxed) days boxed") }
                    + [ResultLine(label: "Slot", value: slotText)],
                note: "Figures that sat boxed longer come up more often. Tune it in Settings."
            )
        } else if candidates.isEmpty {
            EmptyStateCard(
                title: "Every figure is on this shelf",
                message: "Add a figure from your storage boxes, or widen the series on this shelf.",
                systemImage: "shippingbox",
                actionTitle: "Open storage boxes",
                action: { showCloset = true }
            )
        } else if !occupancy.isEmpty {
            SectionCard(title: "On this shelf now") {
                ForEach(occupancy.keys.sorted(), id: \.self) { slot in
                    if let result = occupancy[slot] {
                        DetailRow(label: "Slot \(slot + 1)", value: "\(result.toyName) · \(result.placedAt.formatted(.dateTime.day().month()))")
                    }
                }
            }
        }
    }

    private var slotText: String {
        guard let slot = targetSlot ?? outcome?.slots.first else { return "first free" }
        return "\(slot + 1)" + (occupancy[slot].map { " · replaces \($0.toyName)" } ?? "")
    }

    private var drawLabel: String {
        guard let outcome else {
            switch mode {
            case .one: return "One boxed figure. Long-boxed ones come up more often."
            case .row: return "A row of figures for the free slots, drawn in one go."
            case .slot: return "A figure and a slot number, even a filled one."
            case .coin: return "A coin: keep this shelf as it is, or swap one figure."
            case .wheel: return "The series wheel spins first, then a figure from it."
            }
        }
        switch outcome.mode {
        case .coin:
            return outcome.keep ? "Coin says keep this week's shelf" : "Coin says swap one figure"
        case .row:
            return "Row of \(outcome.picks.count): " + drawnToys.map(\.name).joined(separator: ", ")
        case .wheel:
            return "Wheel landed on \(outcome.series ?? "a series")"
        case .slot:
            return "Slot \((outcome.slots.first ?? 0) + 1) by number"
        case .one:
            return "\(drawnToys.first?.daysBoxed ?? 0) days in the box"
        }
    }

    private var shareText: String {
        let lines = occupancy.keys.sorted().compactMap { slot in
            occupancy[slot].map { "\(slot + 1). \($0.toyName) (\($0.series))" }
        }
        return ([shelf?.name ?? "Shelf"] + lines).joined(separator: "\n")
    }

    private func syncMode() {
        if let shelf, let preset = DrawMode(rawValue: shelf.modeID) {
            mode = preset
        }
    }

    private func resetDraw() {
        outcome = nil
        selection = nil
        targetSlot = nil
    }

    private func draw() {
        guard let shelf, !shuffling else { return }
        drawCount += 1
        var setup = shelf.snapshot
        setup.staleWeight *= staleBoost
        let pool = candidates
        let seed = UInt64(Date.now.timeIntervalSince1970 * 1000) &+ drawCount
        let result = RNGEngine.roll(
            setup,
            candidates: pool.map { RNGEngine.Candidate(name: $0.name, series: $0.series, daysBoxed: $0.daysBoxed) },
            freeSlots: freeSlots,
            mode: mode,
            seed: seed
        )
        notice = nil
        outcome = nil
        targetSlot = nil

        guard !reduceMotion, pool.count > 1 else {
            land(result)
            return
        }
        shuffling = true
        Task { @MainActor in
            for step in 0..<9 {
                selection = Int.random(in: 0..<pool.count)
                try? await Task.sleep(for: .milliseconds(45 + step * 14))
            }
            land(result)
            shuffling = false
        }
    }

    private func land(_ result: RNGEngine.Outcome?) {
        outcome = result
        selection = result?.picks.first
    }

    private func placeDraw() {
        guard let shelf, let outcome else { return }
        if outcome.keep {
            notice = "Shelf stays as it is this week."
            resetDraw()
            placedTick += 1
            return
        }
        var placed: [SpinResult] = []
        for (offset, toy) in drawnToys.enumerated() {
            let slot = offset == 0 ? (targetSlot ?? outcome.slots.first ?? 0) : (outcome.slots.indices.contains(offset) ? outcome.slots[offset] : offset)
            let result = SpinResult(
                toyName: toy.name,
                series: toy.series,
                hue: toy.hue,
                shelfName: shelf.name,
                slot: min(slot, shelf.slotCount - 1),
                placedAt: .now,
                modeID: outcome.mode.rawValue,
                daysBoxed: toy.daysBoxed
            )
            context.insert(result)
            toy.lastShown = .now
            placed.append(result)
        }
        try? context.save()
        lastPlaced = placed
        notice = placed.count == 1
            ? "\(placed[0].toyName) is up in slot \(placed[0].slot + 1)."
            : "\(placed.count) figures are up on \(shelf.name)."
        resetDraw()
        placedTick += 1
    }

    private func undoLast() {
        for result in lastPlaced {
            context.delete(result)
        }
        try? context.save()
        lastPlaced = []
        notice = nil
    }
}

#Preview {
    NavigationStack {
        DrawScreen()
    }
    .previewStore()
}
