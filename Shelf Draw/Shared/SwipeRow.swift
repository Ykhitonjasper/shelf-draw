import SwiftUI

struct SwipeRow<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var systemImage: String?
    var onTap: (() -> Void)?
    private let trailingActions: () -> Trailing

    @State private var feedbackTrigger = 0
    @ScaledMetric(relativeTo: .body) private var iconColumn = AppMetrics.iconColumn
    @ScaledMetric(relativeTo: .body) private var verticalPadding = AppMetrics.contentSpacing

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailingActions: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.onTap = onTap
        self.trailingActions = trailingActions
    }

    var body: some View {
        Group {
            if onTap != nil {
                Button(action: performTap) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .swipeActions {
            trailingActions()
        }
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
        .accessibilityLabel(accessibilityText)
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: AppMetrics.contentSpacing) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: iconColumn)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, verticalPadding)
        .contentShape(Rectangle())
    }

    private var accessibilityText: String {
        [title, subtitle]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func performTap() {
        guard let onTap else { return }
        feedbackTrigger += 1
        onTap()
    }
}

#Preview {
    List {
        SwipeRow(
            title: "Morning check",
            subtitle: "Updated 12 minutes ago",
            systemImage: "sun.max",
            onTap: {}
        ) {
            Button(role: .destructive) {} label: {
                Label("Delete", systemImage: "trash")
            }

            Button {} label: {
                Label("Pin", systemImage: "pin")
            }
            .tint(AppTheme.accent)
        }
    }
    .scrollContentBackground(.hidden)
    .background(AppBackground())
}
