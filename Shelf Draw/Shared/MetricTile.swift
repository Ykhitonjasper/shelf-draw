import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    var caption: String?
    var systemImage: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var iconSpacing = AppMetrics.tightSpacing

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
            HStack(spacing: iconSpacing) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMono)
                    .lineLimit(2)
            }
        }
        .cardSurface()
    }
}

struct TileGrid<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: AppMetrics.tileMinWidth), spacing: AppMetrics.contentSpacing)],
            spacing: AppMetrics.contentSpacing
        ) {
            content
        }
    }
}

#Preview {
    ScreenScaffold {
        TileGrid {
            MetricTile(title: "Batches", value: "12", caption: "This month", systemImage: "tray.full")
            MetricTile(title: "Average yield", value: "1.4 L", caption: "Per batch")
            MetricTile(title: "Longest steep", value: "18 h")
        }
    }
}
