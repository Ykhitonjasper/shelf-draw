import SwiftData
import SwiftUI

struct LogScreen: View {
    enum Filter: String, CaseIterable {
        case all = "All"
        case favorites = "Favourites"
        case planned = "Planned"
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \SpinResult.placedAt, order: .reverse) private var results: [SpinResult]
    @Query private var toys: [Toy]

    @State private var filter: Filter = .all
    @State private var search = ""
    @State private var starTick = 0
    @State private var showStats = false

    private var visible: [SpinResult] {
        results.filter { result in
            switch filter {
            case .all: true
            case .favorites: result.isFavorite
            case .planned: result.isPlanned
            }
        }
        .filter { search.isEmpty || $0.toyName.localizedCaseInsensitiveContains(search) || $0.shelfName.localizedCaseInsensitiveContains(search) }
    }

    private var shownThisMonth: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return Set(results.filter { $0.placedAt >= cutoff && !$0.isPlanned }.map(\.toyName)).count
    }

    var body: some View {
        Group {
            ScreenScaffold {
                ScreenHeader(
                    title: "\(results.count) placements",
                    subtitle: "Every toy you placed on a virtual shelf, newest first"
                )

                ChipRow {
                    ForEach(Filter.allCases, id: \.self) { item in
                        FilterChip(title: item.rawValue, isSelected: filter == item) {
                            filter = item
                        }
                    }
                }

                if visible.isEmpty {
                    EmptyStateCard(
                        title: filter == .favorites ? "No starred placements" : "Nothing placed yet",
                        message: "Draw a figure on the first tab and place it on a shelf. It lands here.",
                        systemImage: "clock.arrow.circlepath"
                    )
                } else {
                    Text("Tap a placement to star it. Starred ones take the full row.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    SpanGrid(
                        items: visible,
                        selection: .constant(nil),
                        onSelect: toggleStar,
                        span: { $0.isFavorite ? 2 : 1 }
                    ) { result in
                        cell(result)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: starTick)
                }

                TileGrid {
                    MetricTile(title: "On a shelf, 30 days", value: "\(shownThisMonth) of \(toys.count)", caption: "figures out of the box")
                    MetricTile(title: "Starred", value: "\(results.filter(\.isFavorite).count)", caption: "placements to repeat")
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Figure or shelf")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showStats = true
                    } label: {
                        Label("Rotation stats", systemImage: "chart.bar")
                    }
                }
            }
            .sheet(isPresented: $showStats) {
                RotationStatsScreen()
            }
        }
    }

    private func toggleStar(_ result: SpinResult) {
        result.isFavorite.toggle()
        try? context.save()
        starTick += 1
    }

    private func cell(_ result: SpinResult) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            HStack(spacing: AppMetrics.tightSpacing) {
                Circle()
                    .fill(result.tint)
                    .frame(width: 14, height: 14)
                Text(result.toyName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                if result.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityLabel("Starred")
                }
            }
            Text("\(result.shelfName) · slot \(result.slot + 1)")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
            Text(result.isPlanned
                 ? "Planned " + result.placedAt.formatted(.dateTime.weekday(.abbreviated).day().month())
                 : result.placedAt.formatted(.dateTime.day().month()) + " · \(result.daysBoxed) days boxed")
                .font(.caption2)
                .foregroundStyle(result.isPlanned ? AppTheme.accent : AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .cardSurface()
        .accessibilityHint(result.isFavorite ? "Double-tap to unstar" : "Double-tap to star")
    }
}

#Preview {
    NavigationStack {
        LogScreen()
    }
    .previewStore()
}
